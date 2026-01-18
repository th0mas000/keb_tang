import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../database/database_helper.dart';
import '../widgets/transaction_card.dart';
import '../utils/currency_formatter.dart';
import 'add_transaction_screen.dart';
import '../widgets/responsive_container.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  List<Transaction> _transactions = [];
  TransactionType? _filterType; // null means show all
  bool _isLoading = true;
  
  // Grouped data: Map<DateString, List<Transaction>>
  final Map<String, List<Transaction>> _groupedTransactions = {};
  final Map<String, Map<String, double>> _dailyTotals = {}; // Date -> {income, expense}

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
      
      _groupTransactions(transactions);
      
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

  void _groupTransactions(List<Transaction> transactions) {
    _groupedTransactions.clear();
    _dailyTotals.clear();
    
    // Convert to map for grouping
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      
      if (!_groupedTransactions.containsKey(dateKey)) {
        _groupedTransactions[dateKey] = [];
        _dailyTotals[dateKey] = {'income': 0.0, 'expense': 0.0};
      }
      
      _groupedTransactions[dateKey]!.add(transaction);
      
      if (transaction.type == TransactionType.income) {
        _dailyTotals[dateKey]!['income'] = _dailyTotals[dateKey]!['income']! + transaction.amount;
      } else {
        _dailyTotals[dateKey]!['expense'] = _dailyTotals[dateKey]!['expense']! + transaction.amount;
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

  String _formatDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'วันนี้'; // Today
    } else if (checkDate == yesterday) {
      return 'เมื่อวาน'; // Yesterday
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get sorted keys (newest first)
    final sortedKeys = _groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการทั้งหมด'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        scrolledUnderElevation: 0,
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
      backgroundColor: Colors.grey[50],
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
                  child: ResponsiveContainer(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedKeys[index];
                        final dailyTransactions = _groupedTransactions[dateKey]!;
                        final totals = _dailyTotals[dateKey]!;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDateHeader(dateKey),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (totals['income']! > 0)
                                        Text(
                                          '+${CurrencyFormatter.formatTHB(totals['income']!)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      if (totals['income']! > 0 && totals['expense']! > 0)
                                        const SizedBox(width: 8),
                                      if (totals['expense']! > 0)
                                        Text(
                                          '-${CurrencyFormatter.formatTHB(totals['expense']!)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Transactions
                            ...dailyTransactions.map((transaction) {
                              return TransactionCard(
                                transaction: transaction,
                                showDate: false, // Already grouped by date
                                onTap: () => _editTransaction(transaction),
                                onDelete: () => _deleteTransaction(transaction.id!),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}
