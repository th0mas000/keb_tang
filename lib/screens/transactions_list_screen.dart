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
  DateTime? _startDate;
  DateTime? _endDate;
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
      
      // Filter by date range if set
      final filteredTransactions = _filterByDateRange(transactions);
      
      _groupTransactions(filteredTransactions);
      
      setState(() {
        _transactions = filteredTransactions;
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

  List<Transaction> _filterByDateRange(List<Transaction> transactions) {
    if (_startDate == null && _endDate == null) {
      return transactions;
    }
    
    return transactions.where((transaction) {
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      if (_startDate != null && _endDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return !transactionDate.isBefore(start) && !transactionDate.isAfter(end);
      } else if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        return !transactionDate.isBefore(start);
      } else if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return !transactionDate.isAfter(end);
      }
      
      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('th', 'TH'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF64748B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadTransactions();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadTransactions();
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
      return DateFormat('dd MMM yyyy', 'th_TH').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get sorted keys (newest first)
    final sortedKeys = _groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'รายการทั้งหมด',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF64748B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'กรองตามวันที่',
            onPressed: _pickDateRange,
          ),
          PopupMenuButton<TransactionType?>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'กรอง',
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
              _loadTransactions();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.all_inclusive, size: 18, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 12),
                    const Text('ทั้งหมด'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TransactionType.income,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    const Text('รายรับ'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TransactionType.expense,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    const Text('รายจ่าย'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF64748B),
                ),
              ),
            )
          : _transactions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFF7F8FA),
                                const Color(0xFFF7F8FA),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ยังไม่มีรายการ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _filterType == null
                              ? 'เริ่มเพิ่มรายการแรกของคุณ'
                              : 'ไม่พบรายการที่กรอง',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  color: const Color(0xFF64748B),
                  child: ResponsiveContainer(
                    child: Column(
                      children: [
                        // Date filter chip
                        if (_startDate != null || _endDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF64748B).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF64748B),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.date_range_rounded,
                                              size: 18,
                                              color: Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        InkWell(
                                          onTap: _clearDateFilter,
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: Color(0xFF64748B),
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
                        // Transaction list
                        Expanded(
                          child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24, top: 8),
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedKeys[index];
                        final dailyTransactions = _groupedTransactions[dateKey]!;
                        final totals = _dailyTotals[dateKey]!;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Header
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDateHeader(dateKey),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (totals['income']! > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD1FAE5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '+${CurrencyFormatter.formatTHB(totals['income']!)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF047857),
                                            ),
                                          ),
                                        ),
                                      if (totals['income']! > 0 && totals['expense']! > 0)
                                        const SizedBox(width: 6),
                                      if (totals['expense']! > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '-${CurrencyFormatter.formatTHB(totals['expense']!)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFB91C1C),
                                            ),
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
                      ],
                    ),
                  ),
                ),
    );
  }
}
