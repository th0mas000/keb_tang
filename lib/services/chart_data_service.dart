import '../models/transaction.dart';
import '../models/chart_data.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';

/// Service for aggregating transaction data for chart visualization
class ChartDataService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get daily data - all transactions for a specific day
  Future<List<ChartDataPoint>> getDailyData(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final transactions = await _dbHelper.getTransactionsByDateRange(
      startOfDay,
      endOfDay,
    );

    // Group by hour
    final Map<int, ChartDataPoint> hourlyData = {};
    
    for (var transaction in transactions) {
      final hour = transaction.date.hour;
      if (!hourlyData.containsKey(hour)) {
        hourlyData[hour] = ChartDataPoint(
          label: '${hour.toString().padLeft(2, '0')}:00',
          income: 0,
          expense: 0,
          date: DateTime(date.year, date.month, date.day, hour),
        );
      }
      
      if (transaction.type.name == 'income') {
        hourlyData[hour] = ChartDataPoint(
          label: hourlyData[hour]!.label,
          income: hourlyData[hour]!.income + transaction.amount,
          expense: hourlyData[hour]!.expense,
          date: hourlyData[hour]!.date,
        );
      } else {
        hourlyData[hour] = ChartDataPoint(
          label: hourlyData[hour]!.label,
          income: hourlyData[hour]!.income,
          expense: hourlyData[hour]!.expense + transaction.amount,
          date: hourlyData[hour]!.date,
        );
      }
    }

    final result = hourlyData.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    return result.isEmpty ? _getEmptyDayData(date) : result;
  }

  /// Get weekly data - transactions aggregated by day for a week
  Future<List<ChartDataPoint>> getWeeklyData(DateTime weekStart) async {
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    final transactions = await _dbHelper.getTransactionsByDateRange(
      startOfWeek,
      endOfWeek,
    );

    // Group by day
    final Map<String, ChartDataPoint> dailyData = {};
    
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      dailyData[key] = ChartDataPoint(
        label: DateFormat('EEE').format(day),
        income: 0,
        expense: 0,
        date: day,
      );
    }

    for (var transaction in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(transaction.date);
      final existing = dailyData[key];
      
      if (existing != null) {
        if (transaction.type.name == 'income') {
          dailyData[key] = ChartDataPoint(
            label: existing.label,
            income: existing.income + transaction.amount,
            expense: existing.expense,
            date: existing.date,
          );
        } else {
          dailyData[key] = ChartDataPoint(
            label: existing.label,
            income: existing.income,
            expense: existing.expense + transaction.amount,
            date: existing.date,
          );
        }
      }
    }

    return dailyData.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get monthly data - transactions aggregated by day for a month
  Future<List<ChartDataPoint>> getMonthlyData(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    final transactions = await _dbHelper.getTransactionsByDateRange(
      startOfMonth,
      endOfMonth,
    );

    final daysInMonth = endOfMonth.day;
    final Map<String, ChartDataPoint> dailyData = {};
    
    for (int i = 1; i <= daysInMonth; i++) {
      final day = DateTime(month.year, month.month, i);
      final key = DateFormat('yyyy-MM-dd').format(day);
      dailyData[key] = ChartDataPoint(
        label: i.toString(),
        income: 0,
        expense: 0,
        date: day,
      );
    }

    for (var transaction in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(transaction.date);
      final existing = dailyData[key];
      
      if (existing != null) {
        if (transaction.type.name == 'income') {
          dailyData[key] = ChartDataPoint(
            label: existing.label,
            income: existing.income + transaction.amount,
            expense: existing.expense,
            date: existing.date,
          );
        } else {
          dailyData[key] = ChartDataPoint(
            label: existing.label,
            income: existing.income,
            expense: existing.expense + transaction.amount,
            date: existing.date,
          );
        }
      }
    }

    return dailyData.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get yearly data - transactions aggregated by month for a year
  Future<List<ChartDataPoint>> getYearlyData(int year) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31, 23, 59, 59);
    
    final transactions = await _dbHelper.getTransactionsByDateRange(
      startOfYear,
      endOfYear,
    );

    // Group by month
    final Map<int, ChartDataPoint> monthlyData = {};
    
    for (int i = 1; i <= 12; i++) {
      final monthDate = DateTime(year, i, 1);
      monthlyData[i] = ChartDataPoint(
        label: DateFormat('MMM').format(monthDate),
        income: 0,
        expense: 0,
        date: monthDate,
      );
    }

    for (var transaction in transactions) {
      final month = transaction.date.month;
      final existing = monthlyData[month]!;
      
      if (transaction.type.name == 'income') {
        monthlyData[month] = ChartDataPoint(
          label: existing.label,
          income: existing.income + transaction.amount,
          expense: existing.expense,
          date: existing.date,
        );
      } else {
        monthlyData[month] = ChartDataPoint(
          label: existing.label,
          income: existing.income,
          expense: existing.expense + transaction.amount,
          date: existing.date,
        );
      }
    }

    return monthlyData.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Calculate summary for a list of chart data points
  PeriodSummary calculateSummary(List<ChartDataPoint> dataPoints) {
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var point in dataPoints) {
      totalIncome += point.income;
      totalExpense += point.expense;
    }

    final dates = dataPoints.map((p) => p.date).toList()..sort();
    
    return PeriodSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      startDate: dates.isNotEmpty ? dates.first : DateTime.now(),
      endDate: dates.isNotEmpty ? dates.last : DateTime.now(),
    );
  }

  /// Get empty data for a day when no transactions exist
  List<ChartDataPoint> _getEmptyDayData(DateTime date) {
    return List.generate(6, (index) {
      final hour = index * 4; // 0, 4, 8, 12, 16, 20
      return ChartDataPoint(
        label: '${hour.toString().padLeft(2, '0')}:00',
        income: 0,
        expense: 0,
        date: DateTime(date.year, date.month, date.day, hour),
      );
    });
  }
}
