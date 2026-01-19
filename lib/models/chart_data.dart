/// Data model for chart visualization
class ChartDataPoint {
  final String label; // e.g., "Mon", "Jan", "1", etc.
  final double income;
  final double expense;
  final DateTime date;

  ChartDataPoint({
    required this.label,
    required this.income,
    required this.expense,
    required this.date,
  });

  /// Calculate net amount (income - expense)
  double get net => income - expense;

  /// Get the maximum value between income and expense for chart scaling
  double get maxValue => income > expense ? income : expense;

  /// Check if there's any data for this point
  bool get hasData => income > 0 || expense > 0;

  @override
  String toString() {
    return 'ChartDataPoint(label: $label, income: $income, expense: $expense, net: $net)';
  }
}

/// Summary statistics for a time period
class PeriodSummary {
  final double totalIncome;
  final double totalExpense;
  final DateTime startDate;
  final DateTime endDate;

  PeriodSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.startDate,
    required this.endDate,
  });

  double get net => totalIncome - totalExpense;
  
  String get netLabel => net >= 0 ? 'กำไร' : 'ขาดทุน';
}
