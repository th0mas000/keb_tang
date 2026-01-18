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
import '../utils/currency_formatter.dart';

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'หน้าหลัก',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF64748B),
                const Color(0xFF64748B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.backup_rounded),
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
            icon: const Icon(Icons.bar_chart_rounded),
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
            icon: const Icon(Icons.document_scanner_rounded),
            onPressed: _scanBill,
            tooltip: 'สแกนบิล',
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
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.purple.shade600,
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
                            child: _ModernSummaryCard(
                              title: 'รายรับ',
                              amount: _totalIncome,
                              icon: Icons.arrow_upward_rounded,
                              gradientColors: [
                                const Color(0xFF10B981),
                                const Color(0xFF10B981),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ModernSummaryCard(
                              title: 'รายจ่าย',
                              amount: _totalExpenses,
                              icon: Icons.arrow_downward_rounded,
                              gradientColors: [
                                const Color(0xFFEF4444),
                                const Color(0xFFEF4444),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ModernSummaryCard(
                        title: 'ยอดคงเหลือ',
                        amount: _balance,
                        icon: Icons.account_balance_wallet_rounded,
                        gradientColors: _balance >= 0
                            ? [const Color(0xFF94A3B8), const Color(0xFF94A3B8)]
                            : [const Color(0xFFF59E0B), const Color(0xFFF59E0B)],
                        isBalance: true,
                      ),
                      const SizedBox(height: 32),
  
                      // Recent transactions header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF7F8FA),
                              const Color(0xFFF7F8FA),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: const Color(0xFF718096),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'รายการล่าสุด',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A5568),
                                  ),
                                ),
                              ],
                            ),
                            if (_recentTransactions.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF64748B),
                                      const Color(0xFF64748B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextButton(
                                  onPressed: _viewAllTransactions,
                                  child: const Text(
                                    'ดูทั้งหมด',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
  
                      // Recent transactions list
                      _recentTransactions.isEmpty
                          ? Container(
                              margin: const EdgeInsets.only(top: 32),
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade50,
                                    Colors.pink.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.inbox_rounded,
                                      size: 64,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'ยังไม่มีรายการ',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4A5568),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'แตะปุ่ม + เพื่อเพิ่มรายการแรกของคุณ',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF718096),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF64748B),
              const Color(0xFF64748B),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _addTransaction,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 24,color: Colors.white),
          label: const Text(
            'เพิ่มรายการ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Modern Summary Card Widget
class _ModernSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isBalance;

  const _ModernSummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradientColors,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: gradientColors.first.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(isBalance ? 24 : 20),
        child: Column(
          crossAxisAlignment: isBalance ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: isBalance ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: isBalance ? 32 : 28,
                ),
                if (isBalance)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            if (!isBalance) ...[
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.formatTHB(amount),
                style: TextStyle(
                  fontSize: isBalance ? 28 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
