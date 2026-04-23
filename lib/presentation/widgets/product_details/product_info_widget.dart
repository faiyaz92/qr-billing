import 'package:flutter/material.dart';

class ProductInfoWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProductInfoWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      title: 'Product Information',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow('Product Name', data['name'] ?? 'N/A'),
        _buildInfoRow('Brand', data['brand'] ?? 'N/A'),
        if (data['date_of_purchase'] != null)
          _buildInfoRow('Purchase Date', data['date_of_purchase'] ?? 'N/A'),
        if (data['original_price'] != null && data['selling_price'] != null)
          _buildInfoRow(
            'You Save',
            '₹${(((data['original_price'] as num).toDouble() - (data['selling_price'] as num).toDouble())).toStringAsFixed(2)}',
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