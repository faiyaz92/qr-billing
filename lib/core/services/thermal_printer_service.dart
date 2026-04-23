import 'dart:typed_data';
import 'dart:convert';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'i_thermal_printer_service.dart';

class ThermalPrinterServiceImpl implements IThermalPrinterService {
  final BluetoothPrint _bluetoothPrint = BluetoothPrint.instance;
  bool _isConnected = false;
  bool _isBluetoothInitialized = false;

  @override
  bool get isConnected => _isConnected;

  ThermalPrinterServiceImpl();

  void _initBluetooth() {
    if (_isBluetoothInitialized) return;
    _isBluetoothInitialized = true;
    _bluetoothPrint.startScan(timeout: const Duration(seconds: 4));
    _bluetoothPrint.scanResults.listen((devices) {
      // Handle discovered devices
    });
  }

  @override
  Future<bool> connectToPrinter(String deviceAddress) async {
    try {
      _initBluetooth();
      // First scan for devices to get the BluetoothDevice object
      await _bluetoothPrint.startScan(timeout: const Duration(seconds: 4));

      // Wait for scan to complete and find the device
      BluetoothDevice? targetDevice;
      _bluetoothPrint.scanResults.listen((devices) {
        for (var device in devices) {
          if (device.address == deviceAddress || device.name == deviceAddress) {
            targetDevice = device;
            break;
          }
        }
      });

      // Wait a moment for scan results
      await Future.delayed(const Duration(seconds: 2));

      if (targetDevice != null) {
        final result = await _bluetoothPrint.connect(targetDevice!);
        if (result ?? false) {
          _isConnected = true;
          return true;
        }
      }

      _isConnected = false;
      return false;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<bool> printReceipt(List<LineText> printData) async {
    if (!_isConnected) {
      return false;
    }

    try {
      Map<String, dynamic> config = Map();
      await _bluetoothPrint.printReceipt(config, printData);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      await _bluetoothPrint.disconnect();
      _isConnected = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> discoverPrinters() async {
    try {
      _initBluetooth();
      List<BluetoothDevice> devices = [];
      _bluetoothPrint.scanResults.listen((deviceList) {
        devices = deviceList;
      });

      await _bluetoothPrint.startScan(timeout: const Duration(seconds: 4));

      // Wait a bit for scan to complete
      await Future.delayed(const Duration(seconds: 4));

      return devices.map((device) => device.name ?? device.address ?? 'Unknown').toList();
    } catch (e) {
      return [];
    }
  }
}