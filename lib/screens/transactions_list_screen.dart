import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../database/database_helper.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  List<Transaction> _transactions = [];
  TransactionType? _filterType; // null means show all
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = _filterType == null
          ? await DatabaseHelper.instance.readAllTransactions()
          : await DatabaseHelper.instance.readTransactionsByType(_filterType!);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรายการ: $e')),
        );
      }
    }
  }

  Future<void> _deleteTransaction(int id) async {
    try {
      await DatabaseHelper.instance.deleteTransaction(id);
      _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบรายการแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบรายการ: $e')),
        );
      }
    }
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );
    if (result == true) {
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการทั้งหมด'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<TransactionType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
              _loadTransactions();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive),
                    SizedBox(width: 8),
                    Text('ทั้งหมด'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TransactionType.income,
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.green),
                    SizedBox(width: 8),
                    Text('รายรับ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TransactionType.expense,
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.red),
                    SizedBox(width: 8),
                    Text('รายจ่าย'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีรายการ',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return TransactionCard(
                        transaction: transaction,
                        onTap: () => _editTransaction(transaction),
                        onDelete: () => _deleteTransaction(transaction.id!),
                      );
                    },
                  ),
                ),
    );
  }
}
