import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../core/injection.dart';
import '../cubits/add_product_cubit.dart';
import '../cubits/add_product_state.dart';

@RoutePage()
class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AddProductCubit>(),
      child: Scaffold(
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
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.router.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Add Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BlocBuilder<AddProductCubit, AddProductState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        if (state is AddProductSuccess)
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Product Added Successfully!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'QR Code:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: QrImageView(
                                      data: state.qrData,
                                      size: 200,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Barcode:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: BarcodeWidget(
                                      barcode: Barcode.code128(),
                                      data: state.qrData,
                                      width: double.infinity,
                                      height: 80,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (state is AddProductError)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Error: ${state.message}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (state is! AddProductSuccess)
                          const Expanded(child: AddProductForm()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key});

  @override
  _AddProductFormState createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {};
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _data['date_of_purchase'] = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Product Name
          Card(
            elevation: 4,
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
                      Icon(Icons.inventory_2, color: Colors.blue.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Product Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Enter product name',
                      hintText: 'e.g., iPhone 15 Pro',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.shopping_bag),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.isEmpty) ? 'Product name is required' : null,
                    onChanged: (value) => _data['name'] = value.trim(),
                    onSaved: (value) => _data['name'] = value?.trim(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Brand
          Card(
            elevation: 4,
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
                      Icon(Icons.business, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Brand',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Enter brand name',
                      hintText: 'e.g., Apple',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.branding_watermark),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => _data['brand'] = value,
                    onSaved: (value) => _data['brand'] = value,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Date of Purchase
          Card(
            elevation: 4,
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
                      Icon(Icons.calendar_today, color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Date of Purchase',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Select purchase date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.date_range),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          color: _selectedDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Purchase Price
          Card(
            elevation: 4,
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
                      Icon(Icons.attach_money, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Purchase Price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Enter purchase price',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value!.isEmpty) return 'Purchase price is required';
                      if (double.tryParse(value) == null) return 'Invalid price';
                      return null;
                    },
                    onChanged: (value) {
                      if (value.isNotEmpty && double.tryParse(value) != null) {
                        _data['purchase_price'] = double.parse(value);
                      }
                    },
                    onSaved: (value) => _data['purchase_price'] = double.parse(value!),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Selling Price
          Card(
            elevation: 4,
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
                      Icon(Icons.sell, color: Colors.purple.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Selling Price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Enter selling price',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value!.isEmpty) return 'Selling price is required';
                      if (double.tryParse(value) == null) return 'Invalid price';
                      return null;
                    },
                    onChanged: (value) {
                      if (value.isNotEmpty && double.tryParse(value) != null) {
                        _data['selling_price'] = double.parse(value);
                      }
                    },
                    onSaved: (value) => _data['selling_price'] = double.parse(value!),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Original Price (Optional)
          Card(
            elevation: 4,
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
                      Icon(Icons.price_check, color: Colors.teal.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Original Price (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Enter original price',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      if (value.isNotEmpty && double.tryParse(value) != null) {
                        _data['original_price'] = double.parse(value);
                      } else if (value.isEmpty) {
                        _data['original_price'] = null;
                      }
                    },
                    onSaved: (value) => _data['original_price'] = (value != null && value.isNotEmpty) ? double.parse(value) : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tax (Optional)
          Card(
            elevation: 4,
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
                      Icon(Icons.account_balance, color: Colors.indigo.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Tax % (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Enter tax percentage',
                      hintText: '18',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      if (value.isNotEmpty && double.tryParse(value) != null) {
                        _data['tax'] = double.parse(value);
                      } else if (value.isEmpty) {
                        _data['tax'] = null;
                      }
                    },
                    onSaved: (value) => _data['tax'] = (value != null && value.isNotEmpty) ? double.parse(value) : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Add Product Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  context.read<AddProductCubit>().addProduct(_data);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Add Product',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}