import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../core/services/i_print_service.dart';
import '../../data/models/product.dart';

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
              // Product Header Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E40AF),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? 'Unknown Product',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.brand ?? 'No Brand',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Product ID: ${product.id?.toString().padLeft(6, '0') ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Pricing Information (Admin View)
              _buildInfoCard(
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
              ),

              const SizedBox(height: 16),

              // Purchase Information (Admin Only)
              _buildInfoCard(
                title: 'Purchase Information',
                icon: Icons.shopping_cart,
                children: [
                  _buildInfoRow('Date of Purchase', product.dateOfPurchase ?? 'N/A'),
                  _buildInfoRow('Purchase Price', '₹${product.purchasePrice.toStringAsFixed(2)}'),
                  _buildInfoRow('Current Value', '₹${product.sellingPrice.toStringAsFixed(2)}'),
                  _buildInfoRow('Value Appreciation', '₹${(product.sellingPrice - product.purchasePrice).toStringAsFixed(2)}'),
                ],
              ),

              const SizedBox(height: 16),

              // Product Information
              _buildInfoCard(
                title: 'Product Information',
                icon: Icons.info_outline,
                children: [
                  _buildInfoRow('Product Name', product.name ?? 'N/A'),
                  _buildInfoRow('Brand', product.brand ?? 'N/A'),
                  _buildInfoRow('Product ID', product.id?.toString().padLeft(6, '0') ?? 'N/A'),
                ],
              ),

              const SizedBox(height: 16),

              // QR Code Information
              _buildInfoCard(
                title: 'QR Code Data',
                icon: Icons.qr_code_2,
                children: [
                  const Text(
                    'QR Code contains encrypted data for security',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      product.qrData ?? 'No QR data available',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // QR Code and Barcode Section
              _buildInfoCard(
                title: 'Product QR Code & Barcode',
                icon: Icons.qr_code_2,
                children: [
                  const Text(
                    'Scan QR code or use barcode for quick product identification',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // QR Code
                  const Center(
                    child: Text(
                      'QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: product.qrData ?? 'No QR data',
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Barcode
                  const Center(
                    child: Text(
                      'Barcode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: product.qrData ?? 'No data',
                          width: double.infinity,
                          height: 80,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final printService = GetIt.instance<IPrintService>();
                        try {
                          await printService.printQRCode(
                            product.qrData ?? 'No QR data',
                            product.name ?? 'Product',
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Print failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Print QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final printService = GetIt.instance<IPrintService>();
                        try {
                          await printService.printBarcode(
                            product.qrData ?? 'No data',
                            product.name ?? 'Product',
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Print failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Print Barcode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Products'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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