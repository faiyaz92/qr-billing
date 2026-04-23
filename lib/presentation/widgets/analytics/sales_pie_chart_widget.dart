import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cubits/analytics_cubit.dart';

class SalesPieChartWidget extends StatelessWidget {
  final AnalyticsLoaded state;

  const SalesPieChartWidget({super.key, required this.state});

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> categorySales) {
    final colors = [
      const Color(0xFF1E40AF), // Blue
      const Color(0xFF06B6D4), // Teal
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444), // Red
    ];

    final total = categorySales.values.fold<double>(0, (sum, value) => sum + value);

    return categorySales.entries.map((entry) {
      final percentage = total > 0 ? (entry.value / total * 100) : 0;
      final colorIndex = categorySales.keys.toList().indexOf(entry.key) % colors.length;

      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        color: colors[colorIndex],
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales by Brand',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: state.categorySales.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No sales data available',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sales data will appear here once you start selling products',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(state.categorySales),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}