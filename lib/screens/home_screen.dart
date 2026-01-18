import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';
import 'transactions_list_screen.dart';
import 'bill_scan_screen.dart';
import 'statistics_screen.dart';
import 'backup_screen.dart';
import '../widgets/responsive_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final income = await DatabaseHelper.instance.getTotalIncome();
      final expenses = await DatabaseHelper.instance.getTotalExpenses();
      final balance = await DatabaseHelper.instance.getBalance();
      final transactions = await DatabaseHelper.instance.readAllTransactions();

      setState(() {
        _totalIncome = income;
        _totalExpenses = expenses;
        _balance = balance;
        _recentTransactions = transactions.take(5).toList(); // Show last 5
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    }
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );
    if (result == true) {
      _loadData();
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
      _loadData();
    }
  }

  Future<void> _deleteTransaction(int id) async {
    try {
      await DatabaseHelper.instance.deleteTransaction(id);
      _loadData();
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

  void _viewAllTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionsListScreen(),
      ),
    ).then((_) => _loadData()); // Reload when returning
  }

  Future<void> _scanBill() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BillScanScreen(),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เก็บตังค์'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupScreen(),
                ),
              );
            },
            tooltip: 'สำรองข้อมูล',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
            tooltip: 'สถิติ',
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: _scanBill,
            tooltip: 'สแกนบิล',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ResponsiveContainer(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary cards
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'รายรับ',
                              amount: _totalIncome,
                              icon: Icons.arrow_upward,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SummaryCard(
                              title: 'รายจ่าย',
                              amount: _totalExpenses,
                              icon: Icons.arrow_downward,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SummaryCard(
                        title: 'ยอดคงเหลือ',
                        amount: _balance,
                        icon: Icons.account_balance_wallet,
                        color: _balance >= 0 ? Colors.blue : Colors.orange,
                      ),
                      const SizedBox(height: 32),
  
                      // Recent transactions header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'รายการล่าสุด',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_recentTransactions.isNotEmpty)
                            TextButton(
                              onPressed: _viewAllTransactions,
                              child: const Text('ดูทั้งหมด'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
  
                      // Recent transactions list
                      _recentTransactions.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'ยังไม่มีรายการ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'แตะปุ่ม + เพื่อเพิ่มรายการแรกของคุณ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: _recentTransactions.map((transaction) {
                                return TransactionCard(
                                  transaction: transaction,
                                  onTap: () => _editTransaction(transaction),
                                  onDelete: () =>
                                      _deleteTransaction(transaction.id!),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรายการ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
