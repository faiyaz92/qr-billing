import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../widgets/admin_product_details/admin_product_header_card.dart';
import '../widgets/admin_product_details/admin_pricing_info_widget.dart';
import '../widgets/admin_product_details/admin_purchase_info_widget.dart';
import '../widgets/admin_product_details/admin_product_info_widget.dart';
import '../widgets/admin_product_details/admin_qr_data_widget.dart';
import '../widgets/product/product_qr_barcode_widget.dart';
import '../widgets/admin_product_details/admin_print_actions_widget.dart';

@RoutePage()
class AdminProductDetailsScreen extends StatelessWidget {
  final Product product;

  const AdminProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details (Admin)'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminProductHeaderCard(product: product),
              const SizedBox(height: 20),
              AdminPricingInfoWidget(product: product),
              const SizedBox(height: 16),
              AdminPurchaseInfoWidget(product: product),
              const SizedBox(height: 16),
              AdminProductInfoWidget(product: product),
              const SizedBox(height: 16),
              AdminQrDataWidget(product: product),
              ProductQrBarcodeWidget(product: product),
              const SizedBox(height: 20),
              AdminPrintActionsWidget(product: product),
            ],
          ),
        ),
      ),
    );
  }
}