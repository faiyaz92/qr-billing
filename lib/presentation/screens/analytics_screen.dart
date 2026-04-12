import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/injection.dart';
import '../cubits/analytics_cubit.dart';

@RoutePage()
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AnalyticsCubit>()..loadAnalytics(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics Dashboard'),
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AnalyticsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AnalyticsCubit>().loadAnalytics(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is AnalyticsLoaded) {
              return _buildAnalyticsContent(state);
            }
            return const Center(child: Text('Loading analytics...'));
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(AnalyticsLoaded state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Business Analytics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your sales performance and business insights',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Key Metrics
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Today\'s Sales',
                          value: '₹${state.todaySales.toStringAsFixed(2)}',
                          change: state.todaySales > 0 ? '+${(state.todaySales * 0.125).toStringAsFixed(1)}%' : '0%',
                          changeColor: state.todaySales > 0 ? Colors.green : Colors.grey,
                          icon: Icons.trending_up,
                          useExpanded: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Bills',
                          value: '${state.recentActivities.length}',
                          change: '+${(state.recentActivities.length * 0.12).toInt()}',
                          changeColor: Colors.blue,
                          icon: Icons.receipt_long,
                          useExpanded: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Avg. Order',
                          value: '₹${state.averageOrderValue.toStringAsFixed(2)}',
                          change: state.averageOrderValue > 0 ? '+${(state.averageOrderValue * 0.052).toStringAsFixed(1)}%' : '0%',
                          changeColor: state.averageOrderValue > 0 ? Colors.green : Colors.grey,
                          icon: Icons.receipt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Monthly Profit',
                          value: '₹${state.monthlyProfit.toStringAsFixed(2)}',
                          change: state.monthlyProfit >= 0 ? '+${(state.monthlyProfit * 0.15).toStringAsFixed(1)}%' : '${(state.monthlyProfit * 0.15).toStringAsFixed(1)}%',
                          changeColor: state.monthlyProfit >= 0 ? Colors.green : Colors.red,
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Weekly Sales Chart
              Card(
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
                        'Weekly Sales Trend',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxYValue(state),
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const titles = ['Today', 'Month', 'Avg Order'];
                                    if (value.toInt() < titles.length) {
                                      return Text(
                                        titles[value.toInt()],
                                        style: const TextStyle(
                                          color: Color(0xFF1E40AF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
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
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '₹${value.toInt()}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: _getMaxYValue(state) / 5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: state.todaySales,
                                    color: const Color(0xFF10B981),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: state.monthlySales,
                                    color: const Color(0xFF3B82F6),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 2,
                                barRods: [
                                  BarChartRodData(
                                    toY: state.averageOrderValue,
                                    color: const Color(0xFFF59E0B),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Category Distribution and Monthly Overview
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Categories Pie Chart
                  Card(
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
                  ),

                  const SizedBox(height: 16),

                  // Monthly Performance
                  Card(
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
                            'Monthly Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildMonthlyStat('This Month', '₹${state.monthlySales.toStringAsFixed(2)}', '+${(state.monthlySales * 0.183).toStringAsFixed(1)}%', Colors.green),
                          const SizedBox(height: 16),
                          _buildMonthlyStat('Monthly Profit', '₹${state.monthlyProfit.toStringAsFixed(2)}', '+${(state.monthlyProfit * 0.15).toStringAsFixed(1)}%', state.monthlyProfit >= 0 ? Colors.green : Colors.red),
                          const SizedBox(height: 16),
                          _buildMonthlyStat('Total Bills', '${state.recentActivities.length}', '+${(state.recentActivities.length * 0.12).toInt()}', Colors.blue),
                          const SizedBox(height: 16),
                          _buildMonthlyStat('Inventory Items', '${state.totalProducts}', '+${(state.totalProducts * 0.08).toInt()}', Colors.purple),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Activity
              Card(
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
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...state.recentActivities.map((activity) => _buildActivityItem(
                        activity.title,
                        activity.subtitle,
                        activity.time,
                        activity.icon,
                        activity.color,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String change,
    required Color changeColor,
    required IconData icon,
    bool useExpanded = false,
  }) {
    final card = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1E40AF), size: 24),
                const Spacer(),
                Text(
                  change,
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );

    return useExpanded ? Expanded(child: card) : card;
  }

  Widget _buildMonthlyStat(String label, String value, String change, Color changeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          flex: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              if (change.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 12,
                      color: changeColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxYValue(AnalyticsLoaded state) {
    final values = [
      state.todaySales,
      state.monthlySales,
      state.averageOrderValue,
    ];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    // Round up to next nice number for better chart scaling
    final scale = maxValue > 1000 ? 1000 : maxValue > 100 ? 100 : 10;
    return ((maxValue / scale).ceil() * scale).toDouble();
  }

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
}