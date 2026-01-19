import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_data.dart';
import '../utils/currency_formatter.dart';

class PeriodChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final String period;

  const PeriodChart({
    super.key,
    required this.data,
    required this.period,
  });

  @override
  State<PeriodChart> createState() => _PeriodChartState();
}

class _PeriodChartState extends State<PeriodChart> with SingleTickerProviderStateMixin {
  int? _selectedBarIndex;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBarTapped(int index) {
    setState(() {
      if (_selectedBarIndex == index) {
        // Deselect if tapping the same bar
        _selectedBarIndex = null;
        _animationController.reverse();
      } else {
        _selectedBarIndex = index;
        if (_animationController.status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
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

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                      _onBarTapped(barTouchResponse.spot!.touchedBarGroupIndex);
                    }
                  },
                  // Tooltips disabled - use detail card instead
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 0,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return null; // No tooltip
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
                        if (value.toInt() >= 0 && value.toInt() < widget.data.length) {
                          final isSelected = _selectedBarIndex == value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              widget.data[value.toInt()].label,
                              style: TextStyle(
                                fontSize: isSelected ? 11 : 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF64748B) : Colors.black87,
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
          ),
        ),
        // Detail card at the bottom
        if (_selectedBarIndex != null)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: _buildDetailCard(widget.data[_selectedBarIndex!]),
          ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(widget.data.length, (index) {
      final dataPoint = widget.data[index];
      final isSelected = _selectedBarIndex == index;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dataPoint.expense + dataPoint.income,
            color: Colors.green, // This will be overridden by rodStackItems
            width: _getBarWidth(),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(4),
              topRight: const Radius.circular(4),
            ),
            rodStackItems: [
              BarChartRodStackItem(
                0,
                dataPoint.expense,
                isSelected 
                    ? const Color(0xFFEF4444).withOpacity(0.8) 
                    : const Color(0xFFEF4444),
              ),
              BarChartRodStackItem(
                dataPoint.expense,
                dataPoint.expense + dataPoint.income,
                isSelected 
                    ? const Color(0xFF10B981).withOpacity(0.8) 
                    : const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildDetailCard(ChartDataPoint dataPoint) {
    // Create a list of values to sort
    final values = [
      {'label': 'รายรับ', 'amount': dataPoint.income, 'color': const Color(0xFF10B981)},
      {'label': 'รายจ่าย', 'amount': dataPoint.expense, 'color': const Color(0xFFEF4444)},
    ];
    
    // Sort by amount (highest to lowest)
    values.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF64748B).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dataPoint.label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'รายละเอียด',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _onBarTapped(_selectedBarIndex!),
                icon: const Icon(Icons.close_rounded),
                color: Colors.grey.shade600,
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Values sorted from highest to lowest
          ...values.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (item['color'] as Color).withOpacity(0.05),
                    (item['color'] as Color).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (item['color'] as Color).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatTHB(item['amount'] as double),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: item['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    (item['label'] as String) == 'รายรับ' 
                        ? Icons.arrow_upward_rounded 
                        : Icons.arrow_downward_rounded,
                    color: item['color'] as Color,
                    size: 28,
                  ),
                ],
              ),
            );
          }).toList(),
          // Total
          Container(
            margin: const EdgeInsets.only(top: 8),
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
                color: const Color(0xFF64748B).withOpacity(0.3),
                width: 1.5,
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
                  CurrencyFormatter.formatTHB(dataPoint.income + dataPoint.expense),
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
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var point in widget.data) {
      final total = point.income + point.expense;
      if (total > max) max = total;
    }
    // Add 20% padding to max value, ensure minimum of 1 to avoid zero interval
    return max > 0 ? max * 1.2 : 1;
  }

  double _getBarWidth() {
    // Adjust bar width based on number of data points
    if (widget.data.length <= 7) return 16;
    if (widget.data.length <= 12) return 12;
    if (widget.data.length <= 31) return 8;
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
