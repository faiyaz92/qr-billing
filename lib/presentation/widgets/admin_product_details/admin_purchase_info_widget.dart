import 'package:flutter/material.dart';
import '../../../data/models/product.dart';

class AdminPurchaseInfoWidget extends StatelessWidget {
  final Product product;

  const AdminPurchaseInfoWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      title: 'Purchase Information',
      icon: Icons.shopping_cart,
      children: [
        _buildInfoRow('Date of Purchase', product.dateOfPurchase ?? 'N/A'),
        _buildInfoRow('Purchase Price', '₹${product.purchasePrice.toStringAsFixed(2)}'),
        _buildInfoRow('Current Value', '₹${product.sellingPrice.toStringAsFixed(2)}'),
        _buildInfoRow('Value Appreciation', '₹${(product.sellingPrice - product.purchasePrice).toStringAsFixed(2)}'),
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