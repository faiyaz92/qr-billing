import 'package:flutter/material.dart';
import '../../cubits/analytics_cubit.dart';

class MonthlyOverviewWidget extends StatelessWidget {
  final AnalyticsLoaded state;

  const MonthlyOverviewWidget({super.key, required this.state});

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
    );
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
          ),
        ),
        Flexible(
          flex: 1,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Flexible(
          flex: 1,
          child: Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: changeColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}