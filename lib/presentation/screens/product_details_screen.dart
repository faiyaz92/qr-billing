import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../data/models/scanned_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/cubits/product_list_cubit.dart';
import '../../core/injection.dart';
import '../../data/models/product.dart';
import '../../core/services/i_encryption_service.dart';
import 'dart:convert';

@RoutePage()
class ProductDetailsScreen extends StatefulWidget {
  final ScannedData scannedData;

  const ProductDetailsScreen({super.key, required this.scannedData});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _showSensitiveData = false;
  late Product _product;
  late Map<String, dynamic> _fullData;

  @override
  void initState() {
    super.initState();
    // Decrypt sensitive data and merge with scanned data
    final data = widget.scannedData.data;
    _fullData = Map.from(data); // Copy the data

    // Decrypt sensitive data if available
    if (data['encrypted_sensitive'] != null) {
      try {
        final encryptionService = getIt<IEncryptionService>();
        final decryptedSensitive = encryptionService.decryptData(data['encrypted_sensitive']);
        final sensitiveData = jsonDecode(decryptedSensitive) as Map<String, dynamic>;
        _fullData.addAll(sensitiveData); // Merge decrypted data
      } catch (e) {
        print('Failed to decrypt sensitive data in product details: $e');
      }
    }

    _product = Product(
      name: _fullData['name'] as String?,
      brand: _fullData['brand'] as String?,
      purchasePrice: (_fullData['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (_fullData['selling_price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (_fullData['original_price'] as num?)?.toDouble(),
      tax: (_fullData['tax'] as num?)?.toDouble(),
      qrData: widget.scannedData.qrCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _fullData;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showSensitiveData ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showSensitiveData = !_showSensitiveData;
              });
            },
            tooltip: _showSensitiveData ? 'Hide Business Details' : 'Show Business Details',
          ),
        ],
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
              // Product Header Card (full width)
              SizedBox(
                width: double.infinity,
                child: Card(
                  margin: EdgeInsets.zero,
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
                          _fullData['name'] ?? 'Unknown Product',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _fullData['brand'] ?? 'No Brand',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Product Information Cards
              _buildInfoCard(
                title: 'Online Pricing Information',
                icon: Icons.price_check,
                children: [
                  _buildInfoRow('Online Price', '₹${(data['selling_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
                  if (data['original_price'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MRP',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '₹${(data['original_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (data['tax'] != null)
                    _buildInfoRow('Tax Rate', '${(data['tax'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}%'),
                ],
              ),

              const SizedBox(height: 16),

              // Business Information (always shown, but purchase price conditional)
              _buildInfoCard(
                title: 'Business Information',
                icon: Icons.business,
                children: [
                  if (_showSensitiveData && data['purchase_price'] != null)
                    _buildInfoRow('Purchase Price', '₹${(data['purchase_price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
                  if (data['selling_price'] != null && data['purchase_price'] != null)
                    _buildInfoRow(
                      'Profit Margin',
                      '₹${(((data['selling_price'] as num).toDouble() - (data['purchase_price'] as num).toDouble())).toStringAsFixed(2)}',
                    ),
                  if (data['selling_price'] != null && data['purchase_price'] != null)
                    _buildInfoRow(
                      'Profit %',
                      '${((((data['selling_price'] as num).toDouble() - (data['purchase_price'] as num).toDouble()) / (data['purchase_price'] as num).toDouble()) * 100).toStringAsFixed(2)}%',
                    ),
                ],
              ),

              _buildInfoCard(
                title: 'Product Information',
                icon: Icons.info_outline,
                children: [
                  _buildInfoRow('Product Name', data['name'] ?? 'N/A'),
                  _buildInfoRow('Brand', data['brand'] ?? 'N/A'),
                  if (data['date_of_purchase'] != null)
                    _buildInfoRow('Purchase Date', data['date_of_purchase'] ?? 'N/A'),
                  if (data['original_price'] != null && data['selling_price'] != null)
                    _buildInfoRow(
                      'You Save',
                      '₹${(((data['original_price'] as num).toDouble() - (data['selling_price'] as num).toDouble())).toStringAsFixed(2)}',
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // QR Code Display
              _buildInfoCard(
                title: 'Product QR Code',
                icon: Icons.qr_code_2,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text(
                        '✅ Verified Product\nScan Complete',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Customer Trust Indicators
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This product is verified and priced according to our online catalog. The price shown is the official online selling price.',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final cubit = getIt<ProductListCubit>();
                              await cubit.printQRCode(_product);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('QR Code printed successfully')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Print failed: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Print QR'),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final cubit = getIt<ProductListCubit>();
                              await cubit.printBarcode(_product);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Barcode printed successfully')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Print failed: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.view_week),
                          label: const Text('Print Barcode'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
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