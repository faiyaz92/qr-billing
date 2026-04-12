import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_based_billing/app_router.dart';
import '../cubits/product_list_cubit.dart';
import '../cubits/product_list_state.dart';

@RoutePage()
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductListCubit(),
      child: const ProductListView(),
    );
  }
}

class ProductListView extends StatefulWidget {
  const ProductListView({super.key});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top App Bar with Gradient
          Container(
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
                      onPressed: () => context.router.pop(),
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
                    BlocBuilder<ProductListCubit, ProductListState>(
                      builder: (context, state) {
                        bool showQr = false;
                        bool showBarcode = false;
                        if (state is ProductListLoaded) {
                          showQr = state.showQr;
                          showBarcode = state.showBarcode;
                        }
                        return Row(
                          children: [
                            IconButton(
                              onPressed: () => context.read<ProductListCubit>().toggleQr(!showQr),
                              icon: Icon(
                                Icons.qr_code,
                                color: showQr ? Colors.white : Colors.white.withValues(alpha: 0.5),
                              ),
                              tooltip: 'Toggle QR Codes',
                            ),
                            IconButton(
                              onPressed: () => context.read<ProductListCubit>().toggleBarcode(!showBarcode),
                              icon: Icon(
                                Icons.view_week,
                                color: showBarcode ? Colors.white : Colors.white.withValues(alpha: 0.5),
                              ),
                              tooltip: 'Toggle Barcodes',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                // TODO: Implement search functionality in cubit
              },
            ),
          ),

          // Product List
          Expanded(
            child: BlocBuilder<ProductListCubit, ProductListState>(
              builder: (context, state) {
                if (state is ProductListLoaded) {
                  if (state.products.isEmpty) {
                    return const Center(
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
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return ProductCard(
                        product: product,
                        showQr: state.showQr,
                        showBarcode: state.showBarcode,
                        onEdit: () {
                          // TODO: Navigate to edit product
                        },
                        onView: () {
                          context.router.push(AdminProductDetailsRoute(product: product));
                        },
                        onDelete: () {
                          _showDeleteDialog(context, product);
                        },
                        onPrint: () {
                          _showPrintDialog(context, product);
                        },
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.router.push(const AddProductRoute()),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic product) {
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
              // TODO: Implement delete functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete functionality coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPrintDialog(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Print ${product.name}'),
        content: const Text('Choose what to print:'),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        try {
                          await context.read<ProductListCubit>().printQRCode(product);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Print failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        try {
                          await context.read<ProductListCubit>().printBarcode(product);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Print failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('Barcode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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