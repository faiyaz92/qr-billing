import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../data/models/product.dart';
import '../../data/models/scanned_data.dart';
import '../cubits/billing_cubit.dart';
import '../cubits/add_product_cubit.dart';
import '../cubits/add_product_state.dart';

class QuickAddWidget extends StatefulWidget {
  const QuickAddWidget({super.key});

  @override
  State<QuickAddWidget> createState() => _QuickAddWidgetState();
}

class _QuickAddWidgetState extends State<QuickAddWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  bool _saveToDb = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _quickItems = [
    {'name': 'Rice 1kg', 'price': 60.0},
    {'name': 'Sugar 1kg', 'price': 45.0},
    {'name': 'Tea 250g', 'price': 120.0},
    {'name': 'Milk 1L', 'price': 65.0},
    {'name': 'Bread', 'price': 30.0},
    {'name': 'Eggs 12pcs', 'price': 110.0},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _selectQuickItem(Map<String, dynamic> item) {
    _nameController.text = item['name'];
    _priceController.text = item['price'].toString();
    _quantityController.text = '1';
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text);
      final quantity = int.parse(_quantityController.text);

      if (_saveToDb && name.isNotEmpty) {
        // Save to database first
        final productData = {
          'name': name,
          'selling_price': price,
          'purchase_price': price,
          'original_price': price,
          'tax': 0.0,
        };

        final addCubit = getIt<AddProductCubit>();
        await addCubit.addProduct(productData);
      }

      // Add to cart using the same logic as scanProduct
      final product = Product(
        name: name.isNotEmpty ? name : 'Quick Item',
        purchasePrice: price,
        sellingPrice: price,
        originalPrice: price,
        tax: 0.0,
        qrData: 'quick-${DateTime.now().millisecondsSinceEpoch}',
      );

      final scannedData = ScannedData(
        qrCode: product.qrData!,
        data: {
          'name': product.name,
          'selling_price': product.sellingPrice,
          'purchase_price': product.purchasePrice,
          'original_price': product.originalPrice,
          'tax': product.tax,
          'encrypted_sensitive': null,
        },
      );

      final billingCubit = context.read<BillingCubit>();
      billingCubit.addProductToCart(
        product: product,
        scannedData: scannedData,
        quantity: quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $quantity x $name to cart${_saveToDb && name.isNotEmpty ? ' & saved to database' : ''}'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _nameController.clear();
        _priceController.clear();
        _quantityController.text = '1';
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.add_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Quick Add Product',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Items Grid
            const Text(
              'Quick Items:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickItems.length,
                itemBuilder: (context, index) {
                  final item = _quickItems[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () => _selectQuickItem(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${item['price']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      hintText: 'Enter product name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.shopping_bag),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (!_saveToDb) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Product name required to save to database';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Price and Quantity Row
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Price (₹)',
                            hintText: '0.00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.currency_rupee),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Quantity
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            hintText: '1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final qty = int.tryParse(value);
                            if (qty == null || qty <= 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Save to DB Toggle
                  Row(
                    children: [
                      Checkbox(
                        value: _saveToDb,
                        onChanged: (value) => setState(() => _saveToDb = value ?? true),
                      ),
                      const Text('Save to database'),
                      const SizedBox(width: 8),
                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Add to Cart'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}