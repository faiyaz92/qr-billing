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
            Expanded(child: _MetricCard(title: 'Today\'s Sales', value: '₹${state.todaySales.toStringAsFixed(0)}', icon: Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(title: 'Total Products', value: '${state.totalProducts}', icon: Icons.inventory_2)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricCard(title: 'Avg. Order', value: '₹${state.averageOrderValue.toStringAsFixed(0)}', icon: Icons.receipt)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(title: 'Monthly Profit', value: '₹${state.monthlyProfit.toStringAsFixed(0)}', icon: Icons.account_balance_wallet, isPositive: state.monthlyProfit >= 0)),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isPositive;

  const _MetricCard({required this.title, required this.value, required this.icon, this.isPositive = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1E40AF), size: 24),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isPositive ? const Color(0xFF1E40AF) : Colors.red)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}