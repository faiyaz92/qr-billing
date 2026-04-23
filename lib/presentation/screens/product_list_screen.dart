import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_based_billing/app_router.dart';
import '../../core/injection.dart';
import '../cubits/product_list_cubit.dart';
import '../cubits/product_list_state.dart';
import '../widgets/product_list/product_list_app_bar.dart';
import '../widgets/product_list/product_list_search_bar.dart';
import '../widgets/product_list/product_list_widget.dart';

@RoutePage()
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductListCubit>(),
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
    return BlocBuilder<ProductListCubit, ProductListState>(
      builder: (context, state) {
        if (state is ProductListLoaded) {
          return Scaffold(
            body: Column(
              children: [
                ProductListAppBar(
                  showQr: state.showQr,
                  showBarcode: state.showBarcode,
                  onToggleQr: () => context.read<ProductListCubit>().toggleQr(!state.showQr),
                  onToggleBarcode: () => context.read<ProductListCubit>().toggleBarcode(!state.showBarcode),
                  onBackPressed: () => context.router.pop(),
                ),
                ProductListSearchBar(
                  onSearchChanged: (value) => context.read<ProductListCubit>().searchProducts(value),
                ),
                ProductListWidget(
                  products: state.products,
                  showQr: state.showQr,
                  showBarcode: state.showBarcode,
                  onEdit: () {
                    // TODO: Navigate to edit product
                  },
                  onView: (product) {
                    context.router.push(AdminProductDetailsRoute(product: product));
                  },
                  onDelete: (product) {
                    _showDeleteDialog(context, product);
                  },
                  onPrint: (product) {
                    _showPrintDialog(context, product);
                  },
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
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
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