import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleDriveService {
  static const _scopes = [drive.DriveApi.driveFileScope];
  
  // TODO: Replace with your actual client ID from Google Cloud Console
  // To get credentials:
  // 1. Go to https://console.cloud.google.com/
  // 2. Create a project or select existing one
  // 3. Enable Google Drive API
  // 4. Create OAuth 2.0 credentials for Android/iOS
  // 5. Add the client ID here
  static final _clientId = ClientId(
    'YOUR_CLIENT_ID.apps.googleusercontent.com',
    'YOUR_CLIENT_SECRET', // Optional for mobile apps
  );

  drive.DriveApi? _driveApi;
  AutoRefreshingAuthClient? _authClient;

  // Check if authenticated
  bool get isAuthenticated => _authClient != null && _driveApi != null;

  // Authenticate with Google Drive
  Future<bool> authenticate() async {
    try {
      // For mobile apps, we need to use a different OAuth flow
      // This is a placeholder - actual implementation depends on platform
      // For now, return false to indicate setup is needed
      
      // Uncomment and configure when you have OAuth credentials:
      /*
      _authClient = await clientViaUserConsent(
        _clientId,
        _scopes,
        (url) async {
          // Open the URL in browser for user consent
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        },
      );
      
      _driveApi = drive.DriveApi(_authClient!);
      return true;
      */
      
      return false;
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  // Upload backup to Google Drive
  Future<String?> uploadBackup(String localFilePath) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated. Please authenticate first.');
    }

    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        throw Exception('File not found: $localFilePath');
      }

      final fileName = file.path.split(Platform.pathSeparator).last;
      
      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..mimeType = 'application/json'
        ..description = 'Keb Tang backup created on ${DateTime.now()}';

      // Upload file
      final media = drive.Media(file.openRead(), await file.length());
      final response = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      return response.id;
    } catch (e) {
      throw Exception('Failed to upload backup: $e');
    }
  }

  // List all backups from Google Drive
  Future<List<DriveBackupFile>> listBackups() async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated. Please authenticate first.');
    }

    try {
      // Query for JSON files (backups)
      final fileList = await _driveApi!.files.list(
        q: "mimeType='application/json' and name contains 'keb_tang_backup'",
        orderBy: 'createdTime desc',
        spaces: 'drive',
        $fields: 'files(id, name, createdTime, size)',
      );

      return fileList.files
              ?.map((file) => DriveBackupFile(
                    id: file.id!,
                    name: file.name!,
                    createdTime: file.createdTime ?? DateTime.now(),
                    size: int.tryParse(file.size ?? '0') ?? 0,
                  ))
              .toList() ??
          [];
    } catch (e) {
      throw Exception('Failed to list backups: $e');
    }
  }

  // Download backup from Google Drive
  Future<String> downloadBackup(String fileId) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated. Please authenticate first.');
    }

    try {
      // Get file metadata
      final file = await _driveApi!.files.get(fileId) as drive.File;
      
      // Download file content
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Read the content as string
      final stringBuffer = StringBuffer();
      await for (var chunk in media.stream) {
        stringBuffer.write(String.fromCharCodes(chunk));
      }

      return stringBuffer.toString();
    } catch (e) {
      throw Exception('Failed to download backup: $e');
    }
  }

  // Delete backup from Google Drive
  Future<void> deleteBackup(String fileId) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated. Please authenticate first.');
    }

    try {
      await _driveApi!.files.delete(fileId);
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    _authClient?.close();
    _authClient = null;
    _driveApi = null;
  }
}

// Model for Drive backup file
class DriveBackupFile {
  final String id;
  final String name;
  final DateTime createdTime;
  final int size;

  DriveBackupFile({
    required this.id,
    required this.name,
    required this.createdTime,
    required this.size,
  });
}
