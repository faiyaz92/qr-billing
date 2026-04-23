import 'package:flutter/material.dart';
import '../../cubits/analytics_cubit.dart';

class KeyMetricsWidget extends StatelessWidget {
  final AnalyticsLoaded state;

  const KeyMetricsWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
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
}