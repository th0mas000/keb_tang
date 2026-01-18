/// Data models for category-based chart visualization

/// Represents a single category's data in the pie chart
class CategoryDataPoint {
  final String category;
  final double amount;
  final double percentage;

  CategoryDataPoint({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

/// Holds the complete category breakdown for both income and expenses
class CategoryBreakdown {
  final List<CategoryDataPoint> incomeCategories;
  final List<CategoryDataPoint> expenseCategories;
  final double totalIncome;
  final double totalExpense;

  CategoryBreakdown({
    required this.incomeCategories,
    required this.expenseCategories,
    required this.totalIncome,
    required this.totalExpense,
  });

  bool get hasIncomeData => incomeCategories.isNotEmpty && totalIncome > 0;
  bool get hasExpenseData => expenseCategories.isNotEmpty && totalExpense > 0;
  bool get hasData => hasIncomeData || hasExpenseData;
}
