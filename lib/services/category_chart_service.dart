import '../models/transaction.dart';
import '../models/category_data.dart';
import '../database/database_helper.dart';

/// Service for aggregating transaction data by category
class CategoryChartService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get category breakdown for a specific date range
  Future<CategoryBreakdown> getCategoryBreakdown(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final transactions = await _dbHelper.getTransactionsByDateRange(
      startDate,
      endDate,
    );

    // Separate income and expense transactions
    final incomeTransactions = transactions
        .where((t) => t.type.name == 'income')
        .toList();
    final expenseTransactions = transactions
        .where((t) => t.type.name == 'expense')
        .toList();

    // Aggregate by category
    final incomeByCategory = _aggregateByCategory(incomeTransactions);
    final expenseByCategory = _aggregateByCategory(expenseTransactions);

    // Calculate totals
    final totalIncome = incomeByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    final totalExpense = expenseByCategory.values.fold(0.0, (sum, amount) => sum + amount);

    // Convert to CategoryDataPoint lists with percentages
    final incomeCategories = _createCategoryDataPoints(incomeByCategory, totalIncome);
    final expenseCategories = _createCategoryDataPoints(expenseByCategory, totalExpense);

    return CategoryBreakdown(
      incomeCategories: incomeCategories,
      expenseCategories: expenseCategories,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }

  /// Aggregate transactions by category
  Map<String, double> _aggregateByCategory(List<Transaction> transactions) {
    final Map<String, double> categoryMap = {};
    
    for (var transaction in transactions) {
      final category = transaction.category;
      categoryMap[category] = (categoryMap[category] ?? 0) + transaction.amount;
    }
    
    return categoryMap;
  }

  /// Convert category map to sorted list of CategoryDataPoint
  List<CategoryDataPoint> _createCategoryDataPoints(
    Map<String, double> categoryMap,
    double total,
  ) {
    if (total == 0) return [];

    final dataPoints = categoryMap.entries.map((entry) {
      return CategoryDataPoint(
        category: entry.key,
        amount: entry.value,
        percentage: (entry.value / total) * 100,
      );
    }).toList();

    // Sort by amount (descending) to show largest categories first
    dataPoints.sort((a, b) => b.amount.compareTo(a.amount));

    return dataPoints;
  }
}
