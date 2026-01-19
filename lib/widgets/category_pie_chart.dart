import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category_data.dart';
import '../utils/currency_formatter.dart';

class CategoryPieChart extends StatefulWidget {
  final CategoryBreakdown breakdown;
  final String chartType; // 'income', 'expense', or 'all'

  const CategoryPieChart({
    super.key,
    required this.breakdown,
    this.chartType = 'all',
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _touchedIncomeIndex;
  int? _touchedExpenseIndex;

  @override
  Widget build(BuildContext context) {
    // If no data, show empty state
    if (!widget.breakdown.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'ไม่มีข้อมูลในช่วงเวลานี้',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    String title = 'สัดส่วนตามหมวดหมู่';
    if (widget.chartType == 'income') title = 'สัดส่วนรายรับ';
    if (widget.chartType == 'expense') title = 'สัดส่วนรายจ่าย';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with close button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF64748B),
                const Color(0xFF475569),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 24,
              ),
            ],
          ),
        ),

        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Income pie chart
                if ((widget.chartType == 'all' || widget.chartType == 'income') && widget.breakdown.hasIncomeData) ...[
                  if (widget.chartType == 'all') ...[
                    _buildSectionTitle('รายรับ', Colors.green),
                    const SizedBox(height: 20),
                  ],
                  _buildPieChartSection(
                    widget.breakdown.incomeCategories,
                    widget.breakdown.totalIncome,
                    _getIncomeColors(),
                    isIncome: true,
                  ),
                  if (widget.chartType == 'all' && widget.breakdown.hasExpenseData)
                    const SizedBox(height: 32),
                ],

                // Expense pie chart
                if ((widget.chartType == 'all' || widget.chartType == 'expense') && widget.breakdown.hasExpenseData) ...[
                  if (widget.chartType == 'all') ...[
                    _buildSectionTitle('รายจ่าย', Colors.red),
                    const SizedBox(height: 20),
                  ],
                  _buildPieChartSection(
                    widget.breakdown.expenseCategories,
                    widget.breakdown.totalExpense,
                    _getExpenseColors(),
                    isIncome: false,
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
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
    List<Color> colors, {
    required bool isIncome,
  }) {
    final touchedIndex = isIncome ? _touchedIncomeIndex : _touchedExpenseIndex;

    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: 280,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 70,
              sections: categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final color = colors[index % colors.length];
                final isTouched = touchedIndex == index;

                return PieChartSectionData(
                  value: category.amount,
                  title: '${category.percentage.toStringAsFixed(1)}%',
                  color: color,
                  radius: isTouched ? 95 : 85,
                  titleStyle: TextStyle(
                    fontSize: isTouched ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                );
              }).toList(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      if (isIncome) {
                        _touchedIncomeIndex = null;
                      } else {
                        _touchedExpenseIndex = null;
                      }
                      return;
                    }
                    if (isIncome) {
                      _touchedIncomeIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    } else {
                      _touchedExpenseIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
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
          final isTouched = touchedIndex == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: isTouched
                  ? color.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTouched ? color.withOpacity(0.3) : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isIncome) {
                    _touchedIncomeIndex =
                        _touchedIncomeIndex == index ? null : index;
                  } else {
                    _touchedExpenseIndex =
                        _touchedExpenseIndex == index ? null : index;
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildLegendItem(
                  category.category,
                  color,
                  category.amount,
                  category.percentage,
                  isTouched,
                ),
              ),
            ),
          );
        }).toList(),

        // Total
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF64748B).withOpacity(0.1),
                const Color(0xFF475569).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF64748B).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.functions_rounded,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'รวมทั้งหมด',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatTHB(total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    double amount,
    double percentage,
    bool isHighlighted,
  ) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isHighlighted ? 24 : 20,
          height: isHighlighted ? 24 : 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? 15 : 14,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
              color: isHighlighted ? Colors.black87 : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatTHB(amount),
              style: TextStyle(
                fontSize: isHighlighted ? 15 : 14,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
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
      const Color(0xFF10B981), // Emerald
      const Color(0xFF059669),
      const Color(0xFF34D399),
      const Color(0xFF6EE7B7),
      const Color(0xFF047857),
      const Color(0xFF065F46),
      const Color(0xFFA7F3D0),
    ];
  }

  // Color palette for expense categories
  List<Color> _getExpenseColors() {
    return [
      const Color(0xFFEF4444), // Red
      const Color(0xFFF87171),
      const Color(0xFFDC2626),
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFFFF7043),
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFFBBF24),
      const Color(0xFFFCA5A5),
    ];
  }
}
