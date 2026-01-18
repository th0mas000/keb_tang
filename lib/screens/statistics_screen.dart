import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chart_data.dart';
import '../models/category_data.dart';
import '../services/chart_data_service.dart';
import '../services/category_chart_service.dart';
import '../widgets/period_chart.dart';
import '../widgets/income_pie_chart.dart';
import '../widgets/category_pie_chart.dart';
import '../utils/currency_formatter.dart';
import '../widgets/responsive_container.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'สถิติ',
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
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'รายวัน'),
              Tab(text: 'รายสัปดาห์'),
              Tab(text: 'รายเดือน'),
              Tab(text: 'รายปี'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DailyChartView(),
            WeeklyChartView(),
            MonthlyChartView(),
            YearlyChartView(),
          ],
        ),
      ),
    );
  }
}

// Daily Chart View
class DailyChartView extends StatefulWidget {
  const DailyChartView({super.key});

  @override
  State<DailyChartView> createState() => _DailyChartViewState();
}

class _DailyChartViewState extends State<DailyChartView> {
  final ChartDataService _chartService = ChartDataService();
  final CategoryChartService _categoryService = CategoryChartService();
  DateTime _selectedDate = DateTime.now();
  List<ChartDataPoint> _chartData = [];
  PeriodSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _chartService.getDailyData(_selectedDate);
    final summary = _chartService.calculateSummary(data);
    setState(() {
      _chartData = data;
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  void _showCategoryBreakdown() async {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
    
    final breakdown = await _categoryService.getCategoryBreakdown(startOfDay, endOfDay);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 600,
              maxWidth: 500,
            ),
            child: CategoryPieChart(breakdown: breakdown),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ResponsiveContainer(
        child: Column(
          children: [
            _buildDateSelector(),
            if (_summary != null) _buildSummaryCards(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : PeriodChart(data: _chartData, period: 'daily'),
            ),
          ],
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
              color: Colors.teal.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showCategoryBreakdown,
          tooltip: 'ดูสัดส่วนตามหมวดหมู่',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.pie_chart_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.cyan.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF64748B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                });
                _loadData();
              },
            ),
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('d MMM yyyy', 'th_TH').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _selectedDate.isBefore(DateTime.now())
                  ? const Color(0xFF64748B)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _selectedDate.isBefore(DateTime.now())
                  ? () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      });
                      _loadData();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ModernSummaryCard(
              title: 'รายรับ',
              amount: _summary!.totalIncome,
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
              amount: _summary!.totalExpense,
              icon: Icons.arrow_downward_rounded,
              gradientColors: [
                const Color(0xFFEF4444),
                const Color(0xFFEF4444),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModernSummaryCard(
              title: _summary!.netLabel,
              amount: _summary!.net.abs(),
              icon: _summary!.net >= 0 
                  ? Icons.trending_up_rounded 
                  : Icons.trending_down_rounded,
              gradientColors: _summary!.net >= 0
                  ? [const Color(0xFF3B82F6), const Color(0xFF3B82F6)]
                  : [const Color(0xFFF59E0B), const Color(0xFFF59E0B)],
            ),
          ),
        ],
      ),
    );
  }
}

// Weekly Chart View
class WeeklyChartView extends StatefulWidget {
  const WeeklyChartView({super.key});

  @override
  State<WeeklyChartView> createState() => _WeeklyChartViewState();
}

class _WeeklyChartViewState extends State<WeeklyChartView> {
  final ChartDataService _chartService = ChartDataService();
  final CategoryChartService _categoryService = CategoryChartService();
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  List<ChartDataPoint> _chartData = [];
  PeriodSummary? _summary;
  bool _isLoading = true;

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _chartService.getWeeklyData(_selectedWeekStart);
    final summary = _chartService.calculateSummary(data);
    setState(() {
      _chartData = data;
      _summary = summary;
      _isLoading = false;
    });
  }

  void _showCategoryBreakdown() async {
    final startOfWeek = DateTime(_selectedWeekStart.year, _selectedWeekStart.month, _selectedWeekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    final breakdown = await _categoryService.getCategoryBreakdown(startOfWeek, endOfWeek);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 600,
              maxWidth: 500,
            ),
            child: CategoryPieChart(breakdown: breakdown),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ResponsiveContainer(
        child: Column(
          children: [
            _buildWeekSelector(weekEnd),
            if (_summary != null) _buildSummaryCards(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : PeriodChart(data: _chartData, period: 'weekly'),
            ),
          ],
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
              color: Colors.teal.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showCategoryBreakdown,
          tooltip: 'ดูสัดส่วนตามหมวดหมู่',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.pie_chart_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _buildWeekSelector(DateTime weekEnd) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.cyan.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF64748B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
                });
                _loadData();
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${DateFormat('d MMM', 'th_TH').format(_selectedWeekStart)} - ${DateFormat('d MMM yyyy', 'th_TH').format(weekEnd)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: weekEnd.isBefore(DateTime.now())
                  ? const Color(0xFF64748B)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: weekEnd.isBefore(DateTime.now())
                  ? () {
                      setState(() {
                        _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
                      });
                      _loadData();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ModernSummaryCard(
              title: 'รายรับ',
              amount: _summary!.totalIncome,
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
              amount: _summary!.totalExpense,
              icon: Icons.arrow_downward_rounded,
              gradientColors: [
                const Color(0xFFEF4444),
                const Color(0xFFEF4444),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModernSummaryCard(
              title: _summary!.netLabel,
              amount: _summary!.net.abs(),
              icon: _summary!.net >= 0 
                  ? Icons.trending_up_rounded 
                  : Icons.trending_down_rounded,
              gradientColors: _summary!.net >= 0
                  ? [const Color(0xFF3B82F6), const Color(0xFF3B82F6)]
                  : [const Color(0xFFF59E0B), const Color(0xFFF59E0B)],
            ),
          ),
        ],
      ),
    );
  }
}

// Monthly Chart View
class MonthlyChartView extends StatefulWidget {
  const MonthlyChartView({super.key});

  @override
  State<MonthlyChartView> createState() => _MonthlyChartViewState();
}

class _MonthlyChartViewState extends State<MonthlyChartView> {
  final ChartDataService _chartService = ChartDataService();
  final CategoryChartService _categoryService = CategoryChartService();
  DateTime _selectedMonth = DateTime.now();
  List<ChartDataPoint> _chartData = [];
  PeriodSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _chartService.getMonthlyData(_selectedMonth);
    final summary = _chartService.calculateSummary(data);
    setState(() {
      _chartData = data;
      _summary = summary;
      _isLoading = false;
    });
  }

  void _showCategoryBreakdown() async {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    
    final breakdown = await _categoryService.getCategoryBreakdown(startOfMonth, endOfMonth);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 600,
              maxWidth: 500,
            ),
            child: CategoryPieChart(breakdown: breakdown),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ResponsiveContainer(
        child: Column(
          children: [
            _buildMonthSelector(),
            if (_summary != null) _buildSummaryCards(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : PeriodChart(data: _chartData, period: 'monthly'),
            ),
          ],
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
              color: Colors.teal.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showCategoryBreakdown,
          tooltip: 'ดูสัดส่วนตามหมวดหมู่',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.pie_chart_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.cyan.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF64748B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  );
                });
                _loadData();
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('MMMM yyyy', 'th_TH').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: DateTime(_selectedMonth.year, _selectedMonth.month + 1)
                      .isBefore(DateTime.now())
                  ? const Color(0xFF64748B)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: DateTime(_selectedMonth.year, _selectedMonth.month + 1)
                      .isBefore(DateTime.now())
                  ? () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                      _loadData();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ModernSummaryCard(
              title: 'รายรับ',
              amount: _summary!.totalIncome,
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
              amount: _summary!.totalExpense,
              icon: Icons.arrow_downward_rounded,
              gradientColors: [
                const Color(0xFFEF4444),
                const Color(0xFFEF4444),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModernSummaryCard(
              title: _summary!.netLabel,
              amount: _summary!.net.abs(),
              icon: _summary!.net >= 0 
                  ? Icons.trending_up_rounded 
                  : Icons.trending_down_rounded,
              gradientColors: _summary!.net >= 0
                  ? [const Color(0xFF3B82F6), const Color(0xFF3B82F6)]
                  : [const Color(0xFFF59E0B), const Color(0xFFF59E0B)],
            ),
          ),
        ],
      ),
    );
  }
}

// Yearly Chart View
class YearlyChartView extends StatefulWidget {
  const YearlyChartView({super.key});

  @override
  State<YearlyChartView> createState() => _YearlyChartViewState();
}

class _YearlyChartViewState extends State<YearlyChartView> {
  final ChartDataService _chartService = ChartDataService();
  final CategoryChartService _categoryService = CategoryChartService();
  int _selectedYear = DateTime.now().year;
  List<ChartDataPoint> _chartData = [];
  PeriodSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _chartService.getYearlyData(_selectedYear);
    final summary = _chartService.calculateSummary(data);
    setState(() {
      _chartData = data;
      _summary = summary;
      _isLoading = false;
    });
  }

  void _showCategoryBreakdown() async {
    final startOfYear = DateTime(_selectedYear, 1, 1);
    final endOfYear = DateTime(_selectedYear, 12, 31, 23, 59, 59);
    
    final breakdown = await _categoryService.getCategoryBreakdown(startOfYear, endOfYear);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 600,
              maxWidth: 500,
            ),
            child: CategoryPieChart(breakdown: breakdown),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ResponsiveContainer(
        child: Column(
          children: [
            _buildYearSelector(),
            if (_summary != null) _buildSummaryCards(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : PeriodChart(data: _chartData, period: 'yearly'),
            ),
          ],
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
              color: Colors.teal.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showCategoryBreakdown,
          tooltip: 'ดูสัดส่วนตามหมวดหมู่',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.pie_chart_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.cyan.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF64748B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedYear--;
                });
                _loadData();
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _selectedYear.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _selectedYear < DateTime.now().year
                  ? const Color(0xFF64748B)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _selectedYear < DateTime.now().year
                  ? () {
                      setState(() {
                        _selectedYear++;
                      });
                      _loadData();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ModernSummaryCard(
              title: 'รายรับ',
              amount: _summary!.totalIncome,
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
              amount: _summary!.totalExpense,
              icon: Icons.arrow_downward_rounded,
              gradientColors: [
                const Color(0xFFEF4444),
                const Color(0xFFEF4444),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModernSummaryCard(
              title: _summary!.netLabel,
              amount: _summary!.net.abs(),
              icon: _summary!.net >= 0 
                  ? Icons.trending_up_rounded 
                  : Icons.trending_down_rounded,
              gradientColors: _summary!.net >= 0
                  ? [const Color(0xFF3B82F6), const Color(0xFF3B82F6)]
                  : [const Color(0xFFF59E0B), const Color(0xFFF59E0B)],
            ),
          ),
        ],
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

  const _ModernSummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradientColors,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.formatTHB(amount),
                style: const TextStyle(
                  fontSize: 16,
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
