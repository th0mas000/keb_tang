import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data.dart';
import '../utils/currency_formatter.dart';

class IncomePieChart extends StatelessWidget {
  final PeriodSummary summary;

  const IncomePieChart({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    // If no data, show empty state
    if (summary.totalIncome == 0 && summary.totalExpense == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'ไม่มีข้อมูลในช่วงเวลานี้',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    final total = summary.totalIncome + summary.totalExpense;
    final incomePercentage = (summary.totalIncome / total * 100).toStringAsFixed(1);
    final expensePercentage = (summary.totalExpense / total * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Pie Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  // Income section
                  if (summary.totalIncome > 0)
                    PieChartSectionData(
                      value: summary.totalIncome,
                      title: '$incomePercentage%',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  // Expense section
                  if (summary.totalExpense > 0)
                    PieChartSectionData(
                      value: summary.totalExpense,
                      title: '$expensePercentage%',
                      color: Colors.red,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (summary.totalIncome > 0) ...[
                _buildLegendItem(
                  'รายรับ',
                  Colors.green,
                  CurrencyFormatter.formatTHB(summary.totalIncome),
                  incomePercentage,
                ),
                const SizedBox(width: 24),
              ],
              if (summary.totalExpense > 0)
                _buildLegendItem(
                  'รายจ่าย',
                  Colors.red,
                  CurrencyFormatter.formatTHB(summary.totalExpense),
                  expensePercentage,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String amount, String percentage) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$percentage%',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
