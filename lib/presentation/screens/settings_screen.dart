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
  String _printerPreference = 'bluetooth';

  @override
  void initState() {
    super.initState();
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
      bottomNavigationBar: _SaveButton(onPressed: _saveSettings),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        buildWhen: (prev, curr) => curr is SettingsLoaded || curr is SettingsLoading || curr is SettingsError,
        listener: (context, state) {
          if (state is SettingsLoaded) {
            _pinController.text = state.pin ?? '';
            _storeSecretController.text = state.storeSecret ?? '';
            _storeNameController.text = state.storeName ?? '';
            setState(() => _printerPreference = state.printerPreference);
          } else if (state is SettingsSaved) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully!')));
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderSection(),
                  const SizedBox(height: 32),
                  _SecurityCard(pinController: _pinController),
                  const SizedBox(height: 24),
                  _StoreSecretCard(secretController: _storeSecretController),
                  const SizedBox(height: 24),
                  _StoreNameCard(nameController: _storeNameController),
                  const SizedBox(height: 24),
                  _PrinterPreferenceCard(
                    groupValue: _printerPreference,
                    onChanged: (value) {
                      setState(() => _printerPreference = value);
                      _saveSettings(silent: true);
                    },
                  ),
                  if (_printerPreference == 'bluetooth') ...[
                    const SizedBox(height: 24),
                    const _ThermalPrinterActionCard(),
                  ],
                  const SizedBox(height: 24),
                  const _InfoCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveSettings({bool silent = false}) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SettingsCubit>().saveSettings(
        pin: _pinController.text.trim(),
        storeSecret: _storeSecretController.text.trim(),
        storeName: _storeNameController.text.trim(),
        printerPreference: _printerPreference,
        silent: silent,
      );
    }
  }
}

// Atomic Components
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Security Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
        SizedBox(height: 8),
        Text('Configure your PIN and store secret for QR code security.', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final TextEditingController pinController;
  const _SecurityCard({required this.pinController});

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsCard(
      icon: Icons.lock,
      iconColor: Colors.blue.shade700,
      title: 'Admin PIN',
      child: TextFormField(
        controller: pinController,
        decoration: InputDecoration(labelText: 'Enter 4-6 digit PIN', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.pin)),
        keyboardType: TextInputType.number,
        maxLength: 6,
        validator: (v) => (v == null || v.isEmpty) ? 'PIN is required' : (v.length < 4 ? 'PIN must be at least 4 digits' : null),
      ),
    );
  }
}

class _StoreSecretCard extends StatelessWidget {
  final TextEditingController secretController;
  const _StoreSecretCard({required this.secretController});

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsCard(
      icon: Icons.security,
      iconColor: Colors.orange.shade700,
      title: 'Store Secret',
      child: TextFormField(
        controller: secretController,
        decoration: InputDecoration(labelText: 'Enter store secret key', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.vpn_key)),
        validator: (v) => (v == null || v.isEmpty) ? 'Store secret is required' : null,
      ),
    );
  }
}

class _StoreNameCard extends StatelessWidget {
  final TextEditingController nameController;
  const _StoreNameCard({required this.nameController});

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsCard(
      icon: Icons.store,
      iconColor: Colors.purple.shade700,
      title: 'Store Name',
      child: TextFormField(
        controller: nameController,
        decoration: InputDecoration(labelText: 'Enter store name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.store)),
        validator: (v) => (v == null || v.isEmpty) ? 'Store name is required' : null,
      ),
    );
  }
}

class _PrinterPreferenceCard extends StatelessWidget {
  final String groupValue;
  final ValueChanged<String> onChanged;
  const _PrinterPreferenceCard({required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _BaseSettingsCard(
      icon: Icons.print,
      iconColor: Colors.blue.shade700,
      title: 'Default Printer',
      child: Column(
        children: [
          const Text('Choose your preferred printing method for bills', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          RadioListTile<String>(title: const Text('Bluetooth Thermal Printer'), subtitle: const Text('Fast receipt printing'), value: 'bluetooth', groupValue: groupValue, onChanged: (v) => onChanged(v!), activeColor: Colors.blue),
          RadioListTile<String>(title: const Text('System Printer'), subtitle: const Text('PDF printing to any printer'), value: 'system', groupValue: groupValue, onChanged: (v) => onChanged(v!), activeColor: Colors.blue),
        ],
      ),
    );
  }
}

class _ThermalPrinterActionCard extends StatelessWidget {
  const _ThermalPrinterActionCard();
  @override
  Widget build(BuildContext context) {
    return _BaseSettingsCard(
      icon: Icons.print,
      iconColor: Colors.green.shade700,
      title: 'Thermal Printer',
      child: Column(
        children: [
          const Text('Configure Bluetooth thermal printer for receipt printing', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => context.router.push(const ThermalPrinterRoute()), icon: const Icon(Icons.settings), label: const Text('Configure Printer'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)))),
        ],
      ),
    );
  }
}

class _BaseSettingsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _BaseSettingsCard({required this.icon, required this.iconColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: iconColor, size: 24), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))]),
        child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E40AF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Save Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade700, size: 24),
            const SizedBox(width: 12),
            const Expanded(child: Text('These settings are crucial for QR code security. Make sure to set them before generating product QR codes.', style: TextStyle(color: Color(0xFF92400E), fontSize: 14))),
          ],
        ),
      ),
    );
  }
}