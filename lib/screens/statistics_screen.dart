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
        appBar: AppBar(
          title: const Text('สถิติ'),
          bottom: const TabBar(
            isScrollable: false,
            tabs: [
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
      body: ResponsiveContainer(
        child: Column(
          children: [
            _buildDateSelector(),
            if (_summary != null) _buildSummaryCards(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PeriodChart(data: _chartData, period: 'daily'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCategoryBreakdown,
        tooltip: 'ดูสัดส่วนตามหมวดหมู่',
        child: const Icon(Icons.pie_chart),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadData();
            },
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    DateFormat('d MMM yyyy', 'th_TH').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedDate.isBefore(DateTime.now())
                ? () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                    _loadData();
                  }
                : null,
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
            child: _SummaryCard(
              title: 'รายรับ',
              amount: _summary!.totalIncome,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: 'รายจ่าย',
              amount: _summary!.totalExpense,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: _summary!.netLabel,
              amount: _summary!.net.abs(),
              color: _summary!.net >= 0 ? Colors.blue : Colors.orange,
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
      body: ResponsiveContainer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
                      });
                      _loadData();
                    },
                  ),
                  Text(
                    '${DateFormat('d MMM', 'th_TH').format(_selectedWeekStart)} - ${DateFormat('d MMM yyyy', 'th_TH').format(weekEnd)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: weekEnd.isBefore(DateTime.now())
                        ? () {
                            setState(() {
                              _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
                            });
                            _loadData();
                          }
                        : null,
                  ),
                ],
              ),
            ),
            if (_summary != null) _buildSummaryCards(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PeriodChart(data: _chartData, period: 'weekly'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCategoryBreakdown,
        tooltip: 'ดูสัดส่วนตามหมวดหมู่',
        child: const Icon(Icons.pie_chart),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'รายรับ',
              amount: _summary!.totalIncome,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: 'รายจ่าย',
              amount: _summary!.totalExpense,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: _summary!.netLabel,
              amount: _summary!.net.abs(),
              color: _summary!.net >= 0 ? Colors.blue : Colors.orange,
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
      body: ResponsiveContainer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
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
                  Text(
                    DateFormat('MMMM yyyy', 'th_TH').format(_selectedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
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
                ],
              ),
            ),
            if (_summary != null) _buildSummaryCards(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PeriodChart(data: _chartData, period: 'monthly'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCategoryBreakdown,
        tooltip: 'ดูสัดส่วนตามหมวดหมู่',
        child: const Icon(Icons.pie_chart),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'รายรับ',
              amount: _summary!.totalIncome,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: 'รายจ่าย',
              amount: _summary!.totalExpense,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: _summary!.netLabel,
              amount: _summary!.net.abs(),
              color: _summary!.net >= 0 ? Colors.blue : Colors.orange,
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
      body: ResponsiveContainer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedYear--;
                      });
                      _loadData();
                    },
                  ),
                  Text(
                    _selectedYear.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedYear < DateTime.now().year
                        ? () {
                            setState(() {
                              _selectedYear++;
                            });
                            _loadData();
                          }
                        : null,
                  ),
                ],
              ),
            ),
            if (_summary != null) _buildSummaryCards(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PeriodChart(data: _chartData, period: 'yearly'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCategoryBreakdown,
        tooltip: 'ดูสัดส่วนตามหมวดหมู่',
        child: const Icon(Icons.pie_chart),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'รายรับ',
              amount: _summary!.totalIncome,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: 'รายจ่าย',
              amount: _summary!.totalExpense,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: _summary!.netLabel,
              amount: _summary!.net.abs(),
              color: _summary!.net >= 0 ? Colors.blue : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Summary Card Widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.formatTHB(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
