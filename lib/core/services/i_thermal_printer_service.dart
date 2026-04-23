import 'dart:typed_data';
import 'package:bluetooth_print/bluetooth_print_model.dart';

abstract class IThermalPrinterService {
  Future<bool> connectToPrinter(String deviceAddress);
  Future<bool> printReceipt(List<LineText> printData);
  Future<bool> disconnect();
  Future<List<String>> discoverPrinters();
  bool get isConnected;
}