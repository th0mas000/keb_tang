import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../services/export_import_service.dart';
import '../widgets/responsive_container.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final ExportImportService _exportImportService = ExportImportService();
  bool _isLoading = false;

  Future<void> _exportBackup() async {
    try {
      setState(() => _isLoading = true);
      
      // Get shareable file path
      final filePath = await _exportImportService.getShareableFilePath();
      
      // Share file - this opens the system share sheet where users can:
      // 1. Save to Files (Local)
      // 2. Save to Google Drive
      // 3. Send via Email/Line/etc.
      final result = await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/json')],
        subject: 'Keb Tang Backup',
        text: 'Backup file for Keb Tang app',
      );

      // Share.shareXFiles returns void or status depending on version/platform,
      // generally we assume success if no error thrown, though user might dismiss sheet.
      
      setState(() => _isLoading = false);
      
      // Note: We don't show "Success" snackbar here because we don't know for sure 
      // if the user actually completed the share/save action in the external app.
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('ไม่สามารถส่งออกไฟล์: $e');
    }
  }

  Future<void> _exportToLocal() async {
    try {
      setState(() => _isLoading = true);
      
      // Get JSON data
      final jsonData = await _exportImportService.exportToJson();
      
      // Generate default filename
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final defaultFileName = 'keb_tang_backup_$timestamp.json';
      
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile: Use saveFile with bytes
        // This uses the Storage Access Framework (SAF) on Android
        final bytes = utf8.encode(jsonData);
        
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'บันทึกไฟล์สำรองข้อมูล',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: Uint8List.fromList(bytes),
        );

        // On Android/iOS, if bytes are provided, the file is automatically written
        // outputPath might be null even on success (platform-dependent)
        setState(() => _isLoading = false);
        if (outputPath != null) {
          _showSuccess('บันทึกไฟล์สำเร็จ');
        }
        // If outputPath is null, assume user cancelled (no error thrown = success)
      } else {
        // For desktop: Use saveFile to get path, then write manually
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'บันทึกไฟล์สำรองข้อมูล',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputPath == null) {
          // User cancelled
          setState(() => _isLoading = false);
          return;
        }

        final file = File(outputPath);
        await file.writeAsString(jsonData);
        
        setState(() => _isLoading = false);
        _showSuccess('บันทึกไฟล์สำเร็จ');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('ไม่สามารถบันทึกไฟล์: $e');
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
      if (filePath == null) {
        _showError('ไม่พบที่อยู่ไฟล์');
        return;
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
         _showError('ไม่สามารถเข้าถึงไฟล์ได้: $filePath');
         return;
      }
      
      final length = await file.length();
      if (length == 0) {
        _showError('ไฟล์ไม่มีข้อมูล (ขนาด 0 bytes)');
        return;
      }

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

  Future<ImportStrategy?> _showImportStrategyDialog() async {
    return showDialog<ImportStrategy>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เลือกวิธีการนำเข้า',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'กรุณาเลือกวิธีการจัดการข้อมูลที่นำเข้า',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              _buildStrategyOption(
                icon: Icons.sync_alt,
                title: 'แทนที่',
                subtitle: 'ลบข้อมูลเดิมทั้งหมดและแทนที่ด้วยข้อมูลใหม่',
                color: Colors.orange,
                onTap: () => Navigator.pop(context, ImportStrategy.replace),
              ),
              const SizedBox(height: 12),
              _buildStrategyOption(
                icon: Icons.merge,
                title: 'รวม',
                subtitle: 'เพิ่มรายการใหม่ ข้ามรายการที่ซ้ำ',
                color: Colors.blue,
                onTap: () => Navigator.pop(context, ImportStrategy.merge),
              ),
              const SizedBox(height: 12),
              _buildStrategyOption(
                icon: Icons.add_circle,
                title: 'เพิ่มทั้งหมด',
                subtitle: 'เพิ่มทุกรายการ แม้จะมีอยู่แล้ว',
                color: Colors.green,
                onTap: () => Navigator.pop(context, ImportStrategy.addAll),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrategyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
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
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'สำรองและกู้คืนข้อมูล',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF64748B),
                Colors.deepPurple.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ResponsiveContainer(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Export to Local Card
                  _buildModernActionCard(
                    icon: Icons.save_alt,
                    title: 'บันทึกไฟล์ลงเครื่อง',
                    subtitle: 'เลือกตำแหน่งที่ต้องการบันทึกไฟล์สำรองข้อมูล',
                    gradientColors: [
                      const Color(0xFF3B82F6),
                      const Color(0xFF3B82F6),
                    ],
                    onPressed: _exportToLocal,
                  ),
                  const SizedBox(height: 16),

                  // Share Card
                  _buildModernActionCard(
                    icon: Icons.share_rounded,
                    title: 'แชร์ไฟล์สำรองข้อมูล',
                    subtitle: 'ส่งไปยังแอปอื่น หรือบันทึกบนคลาวด์',
                    gradientColors: [
                      const Color(0xFF64748B),
                      Colors.deepPurple.shade400,
                    ],
                    onPressed: _exportBackup,
                  ),
                  const SizedBox(height: 16),

                  // Import Card
                  _buildModernActionCard(
                    icon: Icons.upload_file,
                    title: 'นำเข้าข้อมูล',
                    subtitle: 'กู้คืนข้อมูลจากไฟล์สำรองที่บันทึกไว้',
                    gradientColors: [
                      const Color(0xFF10B981),
                      const Color(0xFF10B981),
                    ],
                    onPressed: _importFromLocal,
                  ),
                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100.withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ข้อแนะนำ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• สำรองข้อมูลเป็นประจำเพื่อความปลอดภัย\n'
                                '• ใช้ "แชร์" เพื่อบันทึกลง Google Drive\n'
                                '• ใช้ "บันทึกลงเครื่อง" เพื่อเก็บไว้ในอุปกรณ์\n'
                                '• ไฟล์สำรองเป็นรูปแบบ JSON',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF64748B),
                          ),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'กำลังประมวลผล...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 4,
      shadowColor: gradientColors.first.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
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
