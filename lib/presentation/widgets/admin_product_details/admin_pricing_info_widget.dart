import 'package:flutter/material.dart';
import '../../../data/models/product.dart';

class AdminPricingInfoWidget extends StatelessWidget {
  final Product product;

  const AdminPricingInfoWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return _buildInfoCard(
      title: 'Complete Pricing Information',
      icon: Icons.account_balance_wallet,
      children: [
        _buildInfoRow('Purchase Price', '₹${product.purchasePrice.toStringAsFixed(2)}'),
        _buildInfoRow('Selling Price', '₹${product.sellingPrice.toStringAsFixed(2)}'),
        if (product.originalPrice != null)
          _buildInfoRow('Original Price', '₹${product.originalPrice!.toStringAsFixed(2)}'),
        if (product.tax != null)
          _buildInfoRow('Tax Rate', '${product.tax!.toStringAsFixed(2)}%'),
        _buildInfoRow('Profit Margin', '₹${(product.sellingPrice - product.purchasePrice).toStringAsFixed(2)}'),
        if (product.originalPrice != null)
          _buildInfoRow('Discount %', '${(((product.originalPrice! - product.sellingPrice) / product.originalPrice!) * 100).toStringAsFixed(1)}%'),
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