import 'package:flutter/material.dart';

class PricingInfoWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const PricingInfoWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      title: 'Online Pricing Information',
      icon: Icons.price_check,
      children: [
        _buildInfoRow('Online Price', '₹${(data['selling_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
        if (data['original_price'] != null && data['selling_price'] != null && 
            (data['original_price'] as num).toDouble() > (data['selling_price'] as num).toDouble())
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MRP',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '₹${(data['original_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        if (data['tax'] != null)
          _buildInfoRow('Tax Rate', '${(data['tax'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}%'),
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