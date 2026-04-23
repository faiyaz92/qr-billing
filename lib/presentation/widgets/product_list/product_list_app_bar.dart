import 'package:flutter/material.dart';

class ProductListAppBar extends StatelessWidget {
  final bool showQr;
  final bool showBarcode;
  final VoidCallback onToggleQr;
  final VoidCallback onToggleBarcode;
  final VoidCallback? onBackPressed;

  const ProductListAppBar({
    super.key,
    required this.showQr,
    required this.showBarcode,
    required this.onToggleQr,
    required this.onToggleBarcode,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF1E40AF), // Deep Blue
            Color(0xFF06B6D4), // Teal
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Text(
                'Product Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggleQr,
                icon: Icon(
                  Icons.qr_code,
                  color: showQr ? Colors.white : Colors.white.withValues(alpha: 0.5),
                ),
                tooltip: 'Toggle QR Codes',
              ),
              IconButton(
                onPressed: onToggleBarcode,
                icon: Icon(
                  Icons.view_week,
                  color: showBarcode ? Colors.white : Colors.white.withValues(alpha: 0.5),
                ),
                tooltip: 'Toggle Barcodes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}