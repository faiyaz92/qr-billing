import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/injection.dart';
import '../cubits/thermal_printer_cubit.dart';

@RoutePage()
class ThermalPrinterScreen extends StatelessWidget {
  const ThermalPrinterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ThermalPrinterCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thermal Printer Settings'),
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
          ),
          child: BlocConsumer<ThermalPrinterCubit, ThermalPrinterState>(
            listener: (context, state) {
              if (state is ThermalPrinterError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is ThermalPrinterLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(state.message),
                    ],
                  ),
                );
              }

              if (state is ThermalPrinterLoaded) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ConnectionStatusCard(isConnected: state.isConnected),
                      const SizedBox(height: 20),
                      _ActionButtonsCard(state: state),
                      const SizedBox(height: 20),
                      if (state.isConnected) ...[
                        const _TestPrintCard(),
                        const SizedBox(height: 20),
                      ],
                      _DiscoveredPrintersCard(state: state),
                    ],
                  ),
                );
              }

              return const Center(child: Text('Initializing...'));
            },
          ),
        ),
      ),
    );
  }
}

// Atomic Components
class _ConnectionStatusCard extends StatelessWidget {
  final bool isConnected;
  const _ConnectionStatusCard({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: isConnected ? Colors.green : Colors.red, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isConnected ? 'Connected' : 'Disconnected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isConnected ? Colors.green : Colors.red)),
                const Text('Thermal Printer Status', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonsCard extends StatelessWidget {
  final ThermalPrinterLoaded state;
  const _ActionButtonsCard({required this.state});

  Future<void> _handleScan(BuildContext context) async {
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    final locationStatus = await Permission.location.request();

    if (bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted && locationStatus.isGranted) {
      if (context.mounted) context.read<ThermalPrinterCubit>().scanPrinters();
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bluetooth permissions required')));
      }
    }
  }

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
            const Text('Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Scan for nearby bluetooth thermal printers.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.isScanning ? null : () => _handleScan(context),
                    icon: state.isScanning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                    label: Text(state.isScanning ? 'Scanning...' : 'Scan Printers'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ),
                if (state.isConnected) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.read<ThermalPrinterCubit>().disconnect(),
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ],
              ],
            ),
            if (state.selectedPrinterAddress != null && !state.isConnected) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<ThermalPrinterCubit>().connect(),
                  icon: const Icon(Icons.bluetooth),
                  label: Text('Connect to ${state.selectedPrinterAddress}'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestPrintCard extends StatelessWidget {
  const _TestPrintCard();
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
            const Text('Test Print', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Send a test receipt to verify connection.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<ThermalPrinterCubit>().testPrint(),
              icon: const Icon(Icons.print),
              label: const Text('Print Test Receipt'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveredPrintersCard extends StatelessWidget {
  final ThermalPrinterLoaded state;
  const _DiscoveredPrintersCard({required this.state});

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
            const Text('Available Printers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (state.discoveredPrinters.isEmpty)
              const Text('No printers found yet. Tap scan above.', style: TextStyle(color: Colors.grey))
            else
              ...state.discoveredPrinters.map((p) => RadioListTile<String>(
                    title: Text(p),
                    value: p,
                    groupValue: state.selectedPrinterAddress,
                    onChanged: (v) => context.read<ThermalPrinterCubit>().selectPrinter(v!),
                    secondary: const Icon(Icons.print, color: Colors.blue),
                  )),
          ],
        ),
      ),
    );
  }
}