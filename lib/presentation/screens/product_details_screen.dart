import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../data/models/scanned_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/cubits/product_list_cubit.dart';
import '../../presentation/cubits/settings_cubit.dart';
import '../../presentation/cubits/settings_state.dart';
import '../../core/injection.dart';
import '../../data/models/product.dart';
import '../../core/services/i_encryption_service.dart';
import 'dart:convert';
import '../widgets/product_details/product_header_card.dart';
import '../widgets/product_details/pricing_info_widget.dart';
import '../widgets/product_details/business_info_widget.dart';
import '../widgets/product_details/product_info_widget.dart';
import '../widgets/product_details/qr_code_display_widget.dart';
import '../widgets/customer_trust_indicators_widget.dart';
import '../widgets/action_buttons_widget.dart';

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
            onPressed: _toggleSensitiveData,
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
              ProductHeaderCard(fullData: _fullData),

              const SizedBox(height: 20),

              // Product Information Cards
              PricingInfoWidget(data: data),

              const SizedBox(height: 16),

              // Business Information (always shown, but purchase price conditional)
              BusinessInfoWidget(
                data: data,
                showSensitiveData: _showSensitiveData,
              ),

              ProductInfoWidget(data: data),

              const SizedBox(height: 16),

              // QR Code Display
              QRCodeDisplayWidget(),

              const SizedBox(height: 20),

              // Customer Trust Indicators
              const CustomerTrustIndicatorsWidget(),

              const SizedBox(height: 20),

              // Action Buttons
              ActionButtonsWidget(product: _product),
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

  void _toggleSensitiveData() async {
    if (_showSensitiveData) {
      // If already showing, just hide without PIN
      setState(() {
        _showSensitiveData = false;
      });
      return;
    }

    // Show PIN dialog to enable sensitive data
    final correctPin = await _showPinDialog();
    if (correctPin == true) {
      setState(() {
        _showSensitiveData = true;
      });
    }
  }

  Future<bool?> _showPinDialog() async {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool? result;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.red.shade700),
            const SizedBox(width: 12),
            const Text('Enter PIN'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your admin PIN to view business details',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  hintText: 'Enter PIN',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PIN is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              result = false;
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                // Get stored PIN from settings
                final settingsCubit = getIt<SettingsCubit>();
                final storedPin = await _getStoredPin(settingsCubit);

                if (pinController.text.trim() == storedPin) {
                  result = true;
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect PIN'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    return result;
  }

  Future<String> _getStoredPin(SettingsCubit settingsCubit) async {
    // Load settings to get the PIN
    await settingsCubit.loadSettings();
    final state = settingsCubit.state;
    if (state is SettingsLoaded) {
      return state.pin ?? '';
    }
    return '';
  }
}