import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/injection.dart';
import '../cubits/analytics_cubit.dart';
import '../widgets/analytics/sales_bar_chart_widget.dart';
import '../widgets/analytics/sales_pie_chart_widget.dart';
import '../widgets/analytics/key_metrics_widget.dart';
import '../widgets/analytics/monthly_overview_widget.dart';
import '../widgets/analytics/recent_activity_widget.dart';

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
            KeyMetricsWidget(state: state),

            const SizedBox(height: 24),

            // Weekly Sales Chart
            SalesBarChartWidget(state: state),

            const SizedBox(height: 24),

            // Category Distribution and Monthly Overview
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Categories Pie Chart
                SalesPieChartWidget(state: state),

                const SizedBox(height: 16),

                // Monthly Performance
                MonthlyOverviewWidget(state: state),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity
            RecentActivityWidget(state: state),
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
}