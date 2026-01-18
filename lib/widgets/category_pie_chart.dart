import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category_data.dart';
import '../utils/currency_formatter.dart';

class CategoryPieChart extends StatelessWidget {
  final CategoryBreakdown breakdown;

  const CategoryPieChart({
    super.key,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    // If no data, show empty state
    if (!breakdown.hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'ไม่มีข้อมูลในช่วงเวลานี้',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'สัดส่วนตามหมวดหมู่',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Income pie chart
            if (breakdown.hasIncomeData) ...[
              _buildSectionTitle('รายรับ', Colors.green),
              const SizedBox(height: 16),
              _buildPieChartSection(
                breakdown.incomeCategories,
                breakdown.totalIncome,
                _getIncomeColors(),
              ),
              const SizedBox(height: 32),
            ],

            // Expense pie chart
            if (breakdown.hasExpenseData) ...[
              _buildSectionTitle('รายจ่าย', Colors.red),
              const SizedBox(height: 16),
              _buildPieChartSection(
                breakdown.expenseCategories,
                breakdown.totalExpense,
                _getExpenseColors(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartSection(
    List<CategoryDataPoint> categories,
    double total,
    List<Color> colors,
  ) {
    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final color = colors[index % colors.length];

                return PieChartSectionData(
                  value: category.amount,
                  title: '${category.percentage.toStringAsFixed(1)}%',
                  color: color,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                );
              }).toList(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Legend with details
        ...categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final color = colors[index % colors.length];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildLegendItem(
              category.category,
              color,
              category.amount,
              category.percentage,
            ),
          );
        }).toList(),

        // Total
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'รวม',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              CurrencyFormatter.formatTHB(total),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    double amount,
    double percentage,
  ) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatTHB(amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Color palette for income categories
  List<Color> _getIncomeColors() {
    return [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF66BB6A),
      const Color(0xFF81C784),
      const Color(0xFF2E7D32),
      const Color(0xFF1B5E20),
      const Color(0xFFA5D6A7),
      const Color(0xFFC8E6C9),
    ];
  }

  // Color palette for expense categories
  List<Color> _getExpenseColors() {
    return [
      const Color(0xFFF44336), // Red
      const Color(0xFFE57373),
      const Color(0xFFEF5350),
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFFFF7043),
      const Color(0xFFFF6F00), // Amber
      const Color(0xFFFFB300),
      const Color(0xFFFFA726),
    ];
  }
}
