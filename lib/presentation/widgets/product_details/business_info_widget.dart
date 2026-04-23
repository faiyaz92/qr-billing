import 'package:flutter/material.dart';

class BusinessInfoWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool showSensitiveData;

  const BusinessInfoWidget({super.key, required this.data, required this.showSensitiveData});

  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      title: 'Business Information',
      icon: Icons.business,
      children: [
        if (showSensitiveData && data['purchase_price'] != null)
          _buildInfoRow('Purchase Price', '₹${(data['purchase_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
        if (data['selling_price'] != null && data['purchase_price'] != null)
          _buildInfoRow(
            'Profit Margin',
            '₹${(((data['selling_price'] as num).toDouble() - (data['purchase_price'] as num).toDouble())).toStringAsFixed(2)}',
          ),
        if (data['selling_price'] != null && data['purchase_price'] != null)
          _buildInfoRow(
            'Profit %',
            '${((((data['selling_price'] as num).toDouble() - (data['purchase_price'] as num).toDouble()) / (data['purchase_price'] as num).toDouble()) * 100).toStringAsFixed(2)}%',
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
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
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}