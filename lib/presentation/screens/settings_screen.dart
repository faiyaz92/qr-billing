import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_based_billing/app_router.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pinController = TextEditingController();
  final _storeSecretController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _printerPreference = 'bluetooth'; // Default to bluetooth

  @override
  void initState() {
    super.initState();
    // Load existing settings when screen opens
    context.read<SettingsCubit>().loadSettings();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _storeSecretController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded) {
            // Update controllers with loaded values
            _pinController.text = state.pin ?? '';
            _storeSecretController.text = state.storeSecret ?? '';
            _storeNameController.text = state.storeName ?? '';
            _printerPreference = state.printerPreference;
          } else if (state is SettingsSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings saved successfully!')),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configure your PIN and store secret for QR code security.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // PIN Field
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
                              Icon(Icons.lock, color: Colors.blue.shade700, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Admin PIN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pinController,
                            decoration: InputDecoration(
                              labelText: 'Enter 4-6 digit PIN',
                              hintText: '1234',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.pin),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'PIN is required';
                              }
                              if (value.length < 4) {
                                return 'PIN must be at least 4 digits';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Store Secret Field
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
                              Icon(Icons.security, color: Colors.orange.shade700, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Store Secret',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _storeSecretController,
                            decoration: InputDecoration(
                              labelText: 'Enter store secret key',
                              hintText: 'Your unique store identifier',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.vpn_key),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Store secret is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Store Name Field
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
                              Icon(Icons.store, color: Colors.purple.shade700, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Store Name',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _storeNameController,
                            decoration: InputDecoration(
                              labelText: 'Enter store name',
                              hintText: 'My Store',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.store),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Store name is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
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
                              Icon(Icons.print, color: Colors.blue.shade700, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Default Printer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose your preferred printing method for bills',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          RadioListTile<String>(
                            title: const Text('Bluetooth Thermal Printer'),
                            subtitle: const Text('Fast receipt printing (recommended)'),
                            value: 'bluetooth',
                            groupValue: _printerPreference,
                            onChanged: (value) {
                              setState(() {
                                _printerPreference = value!;
                              });
                              // Save immediately when changed
                              context.read<SettingsCubit>().saveSettings(
                                pin: _pinController.text.trim(),
                                storeSecret: _storeSecretController.text.trim(),
                                storeName: _storeNameController.text.trim(),
                                printerPreference: value,
                              );
                            },
                            activeColor: Colors.blue,
                          ),
                          RadioListTile<String>(
                            title: const Text('System Printer'),
                            subtitle: const Text('PDF printing to any connected printer'),
                            value: 'system',
                            groupValue: _printerPreference,
                            onChanged: (value) {
                              setState(() {
                                _printerPreference = value!;
                              });
                              // Save immediately when changed
                              context.read<SettingsCubit>().saveSettings(
                                pin: _pinController.text.trim(),
                                storeSecret: _storeSecretController.text.trim(),
                                storeName: _storeNameController.text.trim(),
                                printerPreference: value,
                              );
                            },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (_printerPreference == 'bluetooth') Card(
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
                              Icon(Icons.print, color: Colors.green.shade700, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Thermal Printer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Configure Bluetooth thermal printer for receipt printing',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.router.push(const ThermalPrinterRoute());
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Configure Printer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Card(
                    color: Colors.amber.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These settings are crucial for QR code security. Make sure to set them before generating product QR codes.',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveSettings() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SettingsCubit>().saveSettings(
        pin: _pinController.text.trim(),
        storeSecret: _storeSecretController.text.trim(),
        storeName: _storeNameController.text.trim(),
        printerPreference: _printerPreference,
      );
    }
  }
}