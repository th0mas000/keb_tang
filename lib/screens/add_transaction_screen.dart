import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../database/database_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction; // For editing existing transaction
  final Map<String, dynamic>? initialData; // For bill scanning data

  const AddTransactionScreen({super.key, this.transaction, this.initialData});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'อาหาร';
  DateTime _selectedDate = DateTime.now();

  final List<String> _incomeCategories = [
    'เงินเดือน',
    'ธุรกิจ',
    'การลงทุน',
    'ของขวัญ',
    'อื่นๆ'
  ];

  final List<String> _expenseCategories = [
    'อาหาร',
    'การเดินทาง',
    'ช้อปปิ้ง',
    'ค่าบิล',
    'ความบันเทิง',
    'สุขภาพ',
    'การศึกษา',
    'อื่นๆ'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      // Editing mode
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
    } else if (widget.initialData != null) {
      // Bill scanning mode - pre-fill with scanned data
      final data = widget.initialData!;
      if (data['amount'] != null) {
        _amountController.text = data['amount'].toString();
      }
      if (data['title'] != null) {
        _titleController.text = data['title'];
      }
      if (data['date'] != null) {
        _selectedDate = data['date'];
      }
      if (data['type'] != null) {
        _selectedType = data['type'];
        _selectedCategory = _currentCategories.first;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _currentCategories =>
      _selectedType == TransactionType.income
          ? _incomeCategories
          : _expenseCategories;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: widget.transaction?.id,
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        category: _selectedCategory,
        date: _selectedDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      try {
        if (widget.transaction == null) {
          // Create new
          await DatabaseHelper.instance.createTransaction(transaction);
        } else {
          // Update existing
          await DatabaseHelper.instance.updateTransaction(transaction);
        }
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขรายการ' : 'เพิ่มรายการ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              const Text(
                'ประเภท',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('รายรับ'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('รายจ่าย'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    // Reset category when type changes
                    _selectedCategory = _currentCategories.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'หัวข้อ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกหัวข้อ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'จำนวนเงิน',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกจำนวนเงิน';
                  }
                  if (double.tryParse(value) == null) {
                    return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                  }
                  if (double.parse(value) <= 0) {
                    return 'จำนวนเงินต้องมากกว่า 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _currentCategories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'วันที่',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด (ไม่บังคับ)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == TransactionType.income
                        ? Colors.green
                        : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isEditing ? 'อัปเดตรายการ' : 'เพิ่มรายการ',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
