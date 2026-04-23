import 'package:flutter/material.dart';
import '../../../data/models/product.dart';
import 'product_card.dart';

class ProductListWidget extends StatelessWidget {
  final List<Product> products;
  final bool showQr;
  final bool showBarcode;
  final VoidCallback onEdit;
  final void Function(Product) onView;
  final void Function(Product) onDelete;
  final void Function(Product) onPrint;

  const ProductListWidget({
    super.key,
    required this.products,
    required this.showQr,
    required this.showBarcode,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: products.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No products yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Tap + to add your first product',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  showQr: showQr,
                  showBarcode: showBarcode,
                  onEdit: onEdit,
                  onView: () => onView(product),
                  onDelete: () => _showDeleteDialog(context, product),
                  onPrint: () => onPrint(product),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

}