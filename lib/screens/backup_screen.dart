import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/export_import_service.dart';
import '../services/google_drive_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final ExportImportService _exportImportService = ExportImportService();
  final GoogleDriveService _driveService = GoogleDriveService();
  
  bool _isLoading = false;
  List<DriveBackupFile> _driveBackups = [];

  @override
  void initState() {
    super.initState();
    _checkDriveAuth();
  }

  Future<void> _checkDriveAuth() async {
    if (_driveService.isAuthenticated) {
      await _loadDriveBackups();
    }
  }

  Future<void> _loadDriveBackups() async {
    try {
      setState(() => _isLoading = true);
      final backups = await _driveService.listBackups();
      setState(() {
        _driveBackups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('ไม่สามารถโหลดรายการสำรองจาก Google Drive: $e');
    }
  }

  Future<void> _exportToLocal() async {
    try {
      setState(() => _isLoading = true);
      final filePath = await _exportImportService.getShareableFilePath();
      setState(() => _isLoading = false);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'เก็บตังค์ - สำรองข้อมูล',
        text: 'ไฟล์สำรองข้อมูลจากแอป เก็บตังค์',
      );

      _showSuccess('ส่งออกข้อมูลสำเร็จ');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('ไม่สามารถส่งออกข้อมูล: $e');
    }
  }

  Future<void> _importFromLocal() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      // Show strategy selection dialog
      final strategy = await _showImportStrategyDialog();
      if (strategy == null) return;

      setState(() => _isLoading = true);
      final count = await _exportImportService.importFromFile(filePath, strategy);
      setState(() => _isLoading = false);

      _showSuccess('นำเข้าข้อมูลสำเร็จ: $count รายการ');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('ไม่สามารถนำเข้าข้อมูล: $e');
    }
  }

  Future<void> _exportToDrive() async {
    try {
      if (!_driveService.isAuthenticated) {
        _showError('กรุณาเชื่อมต่อกับ Google Drive ก่อน');
        return;
      }

      setState(() => _isLoading = true);
      final filePath = await _exportImportService.exportToFile();
      await _driveService.uploadBackup(filePath);
      setState(() => _isLoading = false);

      _showSuccess('อัปโหลดข้อมูลไปยัง Google Drive สำเร็จ');
      await _loadDriveBackups();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('ไม่สามารถอัปโหลดไปยัง Google Drive: $e');
    }
  }

  Future<void> _importFromDrive(String fileId) async {
    try {
      // Show strategy selection dialog
      final strategy = await _showImportStrategyDialog();
      if (strategy == null) return;

      setState(() => _isLoading = true);
      final jsonData = await _driveService.downloadBackup(fileId);
      final count = await _exportImportService.importFromJson(jsonData, strategy);
      setState(() => _isLoading = false);

      _showSuccess('นำเข้าข้อมูลจาก Google Drive สำเร็จ: $count รายการ');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('ไม่สามารถนำเข้าข้อมูลจาก Google Drive: $e');
    }
  }

  Future<void> _connectToDrive() async {
    try {
      setState(() => _isLoading = true);
      final success = await _driveService.authenticate();
      setState(() => _isLoading = false);

      if (success) {
        _showSuccess('เชื่อมต่อกับ Google Drive สำเร็จ');
        await _loadDriveBackups();
      } else {
        _showError(
          'Google Drive ยังไม่ได้ตั้งค่า\n'
          'กรุณาติดต่อผู้พัฒนาเพื่อตั้งค่า OAuth credentials'
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('ไม่สามารถเชื่อมต่อกับ Google Drive: $e');
    }
  }

  Future<ImportStrategy?> _showImportStrategyDialog() async {
    return showDialog<ImportStrategy>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกวิธีการนำเข้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('แทนที่'),
              subtitle: const Text('ลบข้อมูลเดิมทั้งหมดและแทนที่ด้วยข้อมูลใหม่'),
              leading: const Icon(Icons.sync_alt, color: Colors.orange),
              onTap: () => Navigator.pop(context, ImportStrategy.replace),
            ),
            ListTile(
              title: const Text('รวม'),
              subtitle: const Text('เพิ่มรายการใหม่ ข้ามรายการที่ซ้ำ'),
              leading: const Icon(Icons.merge, color: Colors.blue),
              onTap: () => Navigator.pop(context, ImportStrategy.merge),
            ),
            ListTile(
              title: const Text('เพิ่มทั้งหมด'),
              subtitle: const Text('เพิ่มทุกรายการ แม้จะมีอยู่แล้ว'),
              leading: const Icon(Icons.add_circle, color: Colors.green),
              onTap: () => Navigator.pop(context, ImportStrategy.addAll),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สำรองและกู้คืนข้อมูล'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Local Backup Section
                  _buildSectionTitle('สำรองข้อมูลในเครื่อง'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildActionButton(
                            icon: Icons.upload_file,
                            label: 'ส่งออกข้อมูล',
                            subtitle: 'บันทึกข้อมูลเป็นไฟล์ JSON',
                            color: Colors.blue,
                            onPressed: _exportToLocal,
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.download,
                            label: 'นำเข้าข้อมูล',
                            subtitle: 'กู้คืนข้อมูลจากไฟล์',
                            color: Colors.green,
                            onPressed: _importFromLocal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Google Drive Section
                  _buildSectionTitle('Google Drive'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (!_driveService.isAuthenticated) ...[
                            _buildActionButton(
                              icon: Icons.cloud,
                              label: 'เชื่อมต่อ Google Drive',
                              subtitle: 'เข้าสู่ระบบด้วยบัญชี Google',
                              color: Colors.purple,
                              onPressed: _connectToDrive,
                            ),
                          ] else ...[
                            _buildActionButton(
                              icon: Icons.cloud_upload,
                              label: 'อัปโหลดไป Google Drive',
                              subtitle: 'สำรองข้อมูลบน Cloud',
                              color: Colors.blue,
                              onPressed: _exportToDrive,
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ไฟล์สำรองบน Drive',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _loadDriveBackups,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_driveBackups.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'ยังไม่มีไฟล์สำรอง',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              ..._driveBackups.map((backup) => ListTile(
                                    leading: const Icon(Icons.cloud_done),
                                    title: Text(backup.name),
                                    subtitle: Text(
                                      '${_formatDate(backup.createdTime)} • ${_formatSize(backup.size)}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed: () => _importFromDrive(backup.id),
                                    ),
                                  )),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Info Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'แนะนำให้สำรองข้อมูลเป็นประจำเพื่อป้องกันข้อมูลสูญหาย',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
