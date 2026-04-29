import 'package:flutter/material.dart';
import '../../../data/models/product.dart';
import 'product_card.dart';

class ProductListWidget extends StatelessWidget {
  final List<Product> products;
  final bool showQr;
  final bool showBarcode;
  final void Function(Product) onEdit;
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
                  onEdit: () => onEdit(product),
                  onView: () => onView(product),
                  onDelete: () => onDelete(product),
                  onPrint: () => onPrint(product),
                );
              },
            ),
    );
  }
}