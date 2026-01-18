import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/export_import_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final ExportImportService _exportImportService = ExportImportService();
  bool _isLoading = false;

  Future<void> _exportToLocal() async {
    try {
      setState(() => _isLoading = true);
      
      // Get JSON data
      final jsonData = await _exportImportService.exportToJson();
      
      // Generate filename
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'keb_tang_backup_$timestamp.json';

      // Open save dialog
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'บันทึกไฟล์สำรองข้อมูล',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonData), // For web support if needed
      );

      // On Android/iOS saveFile might return null if cancelled, 
      // or a path even if file not fully "written" by the picker itself on some platforms.
      // But file_picker 8+ saveFile on Android returns the path to the created file.
      // We explicitly write to it to ensure content is saved.

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonData);
        _showSuccess('บันทึกไฟล์สำเร็จ: $outputFile');
      } else {
        // User cancelled
      }

      setState(() => _isLoading = false);
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
                   _buildSectionTitle('จัดการข้อมูล'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildActionButton(
                            icon: Icons.save_alt,
                            label: 'บันทึกไฟล์ลงเครื่อง',
                            subtitle: 'บันทึกข้อมูลเป็นไฟล์ JSON',
                            color: Colors.blue,
                            onPressed: _exportToLocal,
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.file_open,
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
