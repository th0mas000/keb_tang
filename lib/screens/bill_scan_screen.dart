import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import 'add_transaction_screen.dart';
import '../models/transaction_type.dart';
import '../utils/currency_formatter.dart';

class BillScanScreen extends StatefulWidget {
  const BillScanScreen({super.key});

  @override
  State<BillScanScreen> createState() => _BillScanScreenState();
}

class _BillScanScreenState extends State<BillScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();

  File? _selectedImage;
  bool _isProcessing = false;
  String? _extractedText;
  Map<String, dynamic>? _parsedData;
  String? _errorMessage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _extractedText = null;
          _parsedData = null;
          _errorMessage = null;
        });

        await _processImage(image.path);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e';
      });
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Extract text using OCR
      final text = await _ocrService.extractTextFromImage(imagePath);

      // Parse receipt data
      final parsed = ReceiptParser.parseReceipt(text);

      setState(() {
        _extractedText = text;
        _parsedData = parsed;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการประมวลผลรูปภาพ: $e';
        _isProcessing = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'เลือกแหล่งรูปภาพ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('กล้อง'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('คลังรูปภาพ'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToTransaction() {
    if (_parsedData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          initialData: {
            'amount': _parsedData!['amount'],
            'title': _parsedData!['merchantName'],
            'date': _parsedData!['date'],
            'type': TransactionType.expense,
          },
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Transaction was saved, go back to home
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนบิล'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _showImageSourceDialog,
              tooltip: 'สแกนอีกครั้ง',
            ),
        ],
      ),
      body: _selectedImage == null
          ? _buildInitialState()
          : _buildImagePreview(),
      floatingActionButton: _parsedData != null &&
              _parsedData!['amount'] != null
          ? FloatingActionButton.extended(
              onPressed: _proceedToTransaction,
              icon: const Icon(Icons.check),
              label: const Text('สร้างรายการ'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'สแกนใบเสร็จของคุณ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ถ่ายรูปหรือเลือกจากคลังรูปภาพ\nรองรับภาษาไทย �🇭',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: const Icon(Icons.camera_alt, size: 28),
            label: const Text(
              'สแกนบิล',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),

          // Processing indicator or results
          if (_isProcessing)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังประมวลผลรูปภาพ...'),
                ],
              ),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            )
          else if (_parsedData != null)
            _buildExtractedData(),
        ],
      ),
    );
  }

  Widget _buildExtractedData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อมูลที่ดึงได้',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Amount
        _buildDataCard(
          icon: Icons.attach_money,
          label: 'จำนวนเงิน',
          value: _parsedData!['amount'] != null
              ? CurrencyFormatter.formatTHB(_parsedData!['amount'])
              : 'ไม่พบ',
          color: Colors.green,
        ),
        const SizedBox(height: 12),

        // Merchant name
        _buildDataCard(
          icon: Icons.store,
          label: 'ร้านค้า',
          value: _parsedData!['merchantName'] ?? 'ไม่พบ',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),

        // Date
        _buildDataCard(
          icon: Icons.calendar_today,
          label: 'วันที่',
          value: _parsedData!['date'] != null
              ? '${_parsedData!['date'].day}/${_parsedData!['date'].month}/${_parsedData!['date'].year}'
              : 'วันนี้',
          color: Colors.orange,
        ),

        const SizedBox(height: 24),

        // Extracted text (collapsible)
        if (_extractedText != null) ...[
          ExpansionTile(
            title: const Text('ดูข้อความที่ดึงได้'),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _extractedText!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
