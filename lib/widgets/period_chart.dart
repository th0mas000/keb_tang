import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data.dart';
import '../utils/currency_formatter.dart';

class PeriodChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final String period;

  const PeriodChart({
    super.key,
    required this.data,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
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

    final maxY = _getMaxY();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dataPoint = data[groupIndex];
                // rodIndex in stacked bars refers to stack items: 0=expense, 1=income
                final isIncome = rodIndex == 1;
                final amount = isIncome ? dataPoint.income : dataPoint.expense;
                final total = dataPoint.income + dataPoint.expense;
                return BarTooltipItem(
                  '${isIncome ? 'รายรับ' : 'รายจ่าย'}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: CurrencyFormatter.formatTHB(amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '\nรวม: ${CurrencyFormatter.formatTHB(total)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[value.toInt()].label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatYAxis(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.grey.withOpacity(0.3)),
              bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
          ),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(data.length, (index) {
      final dataPoint = data[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dataPoint.expense + dataPoint.income,
            color: Colors.green, // This will be overridden by rodStackItems
            width: _getBarWidth(),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            rodStackItems: [
              BarChartRodStackItem(0, dataPoint.expense, Colors.red),
              BarChartRodStackItem(
                dataPoint.expense,
                dataPoint.expense + dataPoint.income,
                Colors.green,
              ),
            ],
          ),
        ],
      );
    });
  }

  double _getMaxY() {
    double max = 0;
    for (var point in data) {
      final total = point.income + point.expense;
      if (total > max) max = total;
    }
    // Add 20% padding to max value, ensure minimum of 1 to avoid zero interval
    return max > 0 ? max * 1.2 : 1;
  }

  double _getBarWidth() {
    // Adjust bar width based on number of data points
    if (data.length <= 7) return 16;
    if (data.length <= 12) return 12;
    if (data.length <= 31) return 8;
    return 6;
  }

  String _formatYAxis(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }
}
