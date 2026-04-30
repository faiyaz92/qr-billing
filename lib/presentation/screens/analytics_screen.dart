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
          buildWhen: (prev, curr) => curr is AnalyticsLoaded || curr is AnalyticsLoading || curr is AnalyticsError,
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
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Analytics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
            const SizedBox(height: 8),
            const Text('Track your sales performance and business insights', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            KeyMetricsWidget(state: state),
            const SizedBox(height: 24),
            SalesBarChartWidget(state: state),
            const SizedBox(height: 24),
            SalesPieChartWidget(state: state),
            const SizedBox(height: 16),
            MonthlyOverviewWidget(state: state),
            const SizedBox(height: 24),
            RecentActivityWidget(state: state),
          ],
        ),
      ),
    );
  }
}