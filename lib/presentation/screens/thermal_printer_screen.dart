import 'dart:typed_data';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import '../../core/services/i_thermal_printer_service.dart';

@RoutePage()
class ThermalPrinterScreen extends StatefulWidget {
  const ThermalPrinterScreen({super.key});

  @override
  State<ThermalPrinterScreen> createState() => _ThermalPrinterScreenState();
}

class _ThermalPrinterScreenState extends State<ThermalPrinterScreen> {
  final IThermalPrinterService _printerService = GetIt.instance<IThermalPrinterService>();
  bool _isConnected = false;
  bool _isScanning = false;
  bool _isInitializing = false;
  bool _isInitialized = false;
  List<String> _discoveredPrinters = [];
  String? _selectedPrinterAddress;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    setState(() {
      _isConnected = _printerService.isConnected;
      _isInitialized = _printerService.isConnected;
    });
  }

  Future<bool> _requestPermissions() async {
    try {
      // Request Bluetooth permissions
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      final locationStatus = await Permission.location.request();

      if (bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted && locationStatus.isGranted) {
        return true;
      } else if (bluetoothScanStatus.isDenied || bluetoothConnectStatus.isDenied || locationStatus.isDenied) {
        // Show dialog to guide user to settings
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Permissions Required'),
                content: const Text(
                  'Bluetooth and location permissions are required to connect to thermal printers. '
                  'Please grant these permissions in your device settings.'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              );
            },
          );
        }
        return false;
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission error: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _initializeBluetooth() async {
    setState(() => _isInitializing = true);

    try {
      // Request permissions first
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        setState(() => _isInitializing = false);
        return;
      }

      // Try to initialize Bluetooth
      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth initialized successfully')),
      );
    } catch (e) {
      setState(() => _isInitializing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Initialization error: $e')),
      );
    }
  }

  Future<void> _connectToPrinter() async {
    if (_selectedPrinterAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a printer first')),
      );
      return;
    }

    setState(() => _isScanning = true);

    try {
      final success = await _printerService.connectToPrinter(_selectedPrinterAddress!);
      setState(() {
        _isConnected = success;
        _isScanning = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to thermal printer')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to printer')),
        );
      }
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  Future<void> _disconnectPrinter() async {
    try {
      await _printerService.disconnect();
      setState(() => _isConnected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected from printer')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnect error: $e')),
      );
    }
  }

  Future<void> _scanForPrinters() async {
    setState(() => _isScanning = true);

    try {
      final printers = await _printerService.discoverPrinters();
      setState(() {
        _discoveredPrinters = printers;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan error: $e')),
      );
    }
  }

  Future<void> _testPrint() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to printer first')),
      );
      return;
    }

    try {
      // Create sample receipt data
      final testData = [
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'Test Print',
          align: LineText.ALIGN_CENTER,
        ),
        LineText(linefeed: 2),
      ];
      final success = await _printerService.printReceipt(testData);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test print sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              // Connection Status
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                        color: _isConnected ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isConnected ? 'Connected' : 'Disconnected',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isConnected ? Colors.green : Colors.red,
                              ),
                            ),
                            const Text(
                              'Thermal Printer Status',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Manual Connection
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
                      const Text(
                        'Bluetooth Connection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'First initialize Bluetooth, then scan for available thermal printers.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedPrinterAddress != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bluetooth, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selected: $_selectedPrinterAddress',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _selectedPrinterAddress = null),
                                icon: const Icon(Icons.clear),
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (!_isInitialized) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isInitializing ? null : _initializeBluetooth,
                                icon: _isInitializing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.bluetooth),
                                label: Text(_isInitializing ? 'Initializing...' : 'Initialize Bluetooth'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ] else ...[
                            if (_selectedPrinterAddress != null) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isScanning ? null : _connectToPrinter,
                                  icon: _isScanning
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.bluetooth),
                                  label: Text(_isScanning ? 'Connecting...' : 'Connect'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isScanning || !_isInitialized) ? null : _scanForPrinters,
                                icon: _isScanning
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.search),
                                label: Text(_isScanning ? 'Scanning...' : 'Scan for Printers'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isInitialized ? Colors.orange : Colors.grey,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            if (_isConnected) ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _disconnectPrinter,
                                icon: const Icon(Icons.bluetooth_disabled),
                                label: const Text('Disconnect'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Test Print
              if (_isConnected)
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
                        const Text(
                          'Test Print',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Send a test receipt to verify printer connection',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _testPrint,
                          icon: const Icon(Icons.print),
                          label: const Text('Print Test Receipt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Discovered Printers
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
                          const Text(
                            'Discovered Printers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: (_isScanning || !_isInitialized) ? null : _scanForPrinters,
                            icon: _isScanning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                            label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isInitialized ? Colors.orange : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_discoveredPrinters.isEmpty)
                        Text(
                          _isInitialized
                              ? 'No printers found. Try scanning again.'
                              : 'Initialize Bluetooth first to scan for printers.',
                          style: const TextStyle(color: Colors.grey),
                        )
                      else
                        ..._discoveredPrinters.map((printer) => RadioListTile<String>(
                              title: Text(printer),
                              value: printer,
                              groupValue: _selectedPrinterAddress,
                              onChanged: (value) {
                                setState(() => _selectedPrinterAddress = value);
                              },
                              secondary: const Icon(Icons.print),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}