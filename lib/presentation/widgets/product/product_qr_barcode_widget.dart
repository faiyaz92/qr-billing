import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../../data/models/product.dart';

class ProductQrBarcodeWidget extends StatelessWidget {
  final Product product;

  const ProductQrBarcodeWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.qr_code_2, color: const Color(0xFF1E40AF), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Product QR Code & Barcode',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }
}