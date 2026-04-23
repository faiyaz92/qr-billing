import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../core/injection.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../data/models/product.dart';
import '../../data/models/scanned_data.dart';
import '../cubits/billing_cubit.dart';
import '../cubits/add_product_cubit.dart';
import '../cubits/add_product_state.dart';

class ProductListDrawer extends StatefulWidget {
  const ProductListDrawer({super.key});

  @override
  State<ProductListDrawer> createState() => _ProductListDrawerState();
}

class _ProductListDrawerState extends State<ProductListDrawer> {
  final IProductRepository _productRepo = getIt<IProductRepository>();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      _products = await _productRepo.getAllProducts();
      _filteredProducts = List.from(_products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final name = product.name?.toLowerCase() ?? '';
        final brand = product.brand?.toLowerCase() ?? '';
        return name.contains(query) || brand.contains(query);
      }).toList();
    });
  }

  Future<void> _addProductToCart(Product product, int quantity) async {
    try {
      // Create ScannedData from product (similar to QR scan)
      final scannedData = ScannedData(
        qrCode: product.qrData ?? 'manual-${product.name}',
        data: {
          'name': product.name,
          'brand': product.brand,
          'selling_price': product.sellingPrice,
          'original_price': product.originalPrice,
          'tax': product.tax,
          'encrypted_sensitive': null, // No encrypted data for manual adds
        },
      );

      // Add to cart via BillingCubit API (keeps _cart + calculations in sync)
      final billingCubit = context.read<BillingCubit>();
      billingCubit.addProductToCart(
        product: Product(
          id: product.id,
          name: product.name,
          brand: product.brand,
          sellingPrice: product.sellingPrice,
          originalPrice: product.originalPrice,
          tax: product.tax,
          qrData: product.qrData,
          purchasePrice: product.purchasePrice,
        ),
        scannedData: scannedData,
        quantity: quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${product.name} x$quantity to cart')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      }
    }
  }

  void _showAddNewProductDialog() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => getIt<AddProductCubit>(),
        child: const AddQuickProductDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1E40AF), Color(0xFF06B6D4)],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Products',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Add New Product Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddNewProductDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                            ? 'No products found'
                            : 'No products match "${_searchController.text}"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ProductListItem(
                        product: product,
                        onAddToCart: (quantity) => _addProductToCart(product, quantity),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ProductListItem extends StatefulWidget {
  final Product product;
  final Function(int quantity) onAddToCart;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<ProductListItem> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name and Brand
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name ?? 'Unnamed Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.product.brand != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.product.brand!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${widget.product.sellingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (widget.product.originalPrice != null &&
                        widget.product.originalPrice! > widget.product.sellingPrice) ...[
                      const SizedBox(height: 2),
                      Text(
                        '₹${widget.product.originalPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quantity Selector and Add Button
            Row(
              children: [
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                        icon: const Icon(Icons.remove, size: 16),
                        padding: const EdgeInsets.all(4),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            vertical: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          _quantity.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add, size: 16),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Add to Cart Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onAddToCart(_quantity);
                      setState(() => _quantity = 1); // Reset quantity
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Add x$_quantity'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddQuickProductDialog extends StatefulWidget {
  const AddQuickProductDialog({super.key});

  @override
  State<AddQuickProductDialog> createState() => _AddQuickProductDialogState();
}

class _AddQuickProductDialogState extends State<AddQuickProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {};
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _saveToDatabase = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Create product for cart (no DB save if name is empty)
      final product = Product(
        name: _data['name']?.toString().trim().isNotEmpty == true ? _data['name'] : 'Quick Item',
        purchasePrice: double.parse(_priceController.text),
        sellingPrice: double.parse(_priceController.text),
        qrData: 'quick-${DateTime.now().millisecondsSinceEpoch}',
      );

      // Create ScannedData
      final scannedData = ScannedData(
        qrCode: product.qrData!,
        data: {
          'name': product.name,
          'selling_price': product.sellingPrice,
          'original_price': null,
          'tax': null,
          'encrypted_sensitive': null,
        },
      );

      // Add to cart via BillingCubit API
      context.read<BillingCubit>().addProductToCart(
        product: product,
        scannedData: scannedData,
        quantity: 1,
      );

      // Save to database if name provided
      if (_saveToDatabase && _data['name']?.toString().trim().isNotEmpty == true) {
        context.read<AddProductCubit>().addProduct(_data);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to cart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Quick Product'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Name (Optional)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name (Optional)',
                hintText: 'Leave empty for quick add',
              ),
              onChanged: (value) => _data['name'] = value,
            ),

            const SizedBox(height: 16),

            // Price (Required)
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price *',
                hintText: '0.00',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Price is required';
                if (double.tryParse(value) == null) return 'Invalid price';
                return null;
              },
              onChanged: (value) {
                if (value.isNotEmpty && double.tryParse(value) != null) {
                  _data['selling_price'] = double.parse(value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Save to Database Checkbox
            CheckboxListTile(
              title: const Text('Save to database for future use'),
              value: _saveToDatabase,
              onChanged: (value) {
                setState(() => _saveToDatabase = value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addToCart,
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}