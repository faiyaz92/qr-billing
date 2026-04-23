import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

class ProductCard extends StatefulWidget {
  final dynamic product;
  final bool showQr;
  final bool showBarcode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;
  final VoidCallback onView;

  const ProductCard({
    super.key,
    required this.product,
    required this.showQr,
    required this.showBarcode,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
    required this.onView,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _showBarcode = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name ?? 'Unnamed Product',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.product.id?.toString().padLeft(6, '0') ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator (placeholder)
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            // Product Details
            if (widget.product.brand != null && widget.product.brand!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Brand: ${widget.product.brand}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],

            // Pricing Info
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '₹${widget.product.sellingPrice?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (widget.product.originalPrice != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '₹${widget.product.originalPrice?.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                if (widget.product.purchasePrice != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Cost: ₹${widget.product.purchasePrice?.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),

            // Tax Info
            if (widget.product.tax != null && widget.product.tax! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Tax: ${widget.product.tax}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                ),
              ),
            ],

            // QR/Barcode Display
            if (widget.showQr || widget.showBarcode) ...[
              const SizedBox(height: 16),
              if (_showBarcode && widget.product.qrData != null) ...[
                Card(
                  color: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        if (widget.showQr) ...[
                          QrImageView(
                            data: widget.product.qrData!,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (widget.showBarcode) ...[
                          BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: widget.product.qrData!,
                            width: double.infinity,
                            height: 60,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => setState(() => _showBarcode = !_showBarcode),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                  icon: Icon(
                    Icons.qr_code,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  tooltip: _showBarcode ? 'Hide QR/Barcode' : 'Show QR/Barcode',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onView,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  icon: Icon(
                    Icons.visibility,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  tooltip: 'View Details',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onPrint,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  icon: Icon(
                    Icons.print,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  tooltip: 'Print',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onEdit,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  tooltip: 'Edit',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onDelete,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  ),
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}