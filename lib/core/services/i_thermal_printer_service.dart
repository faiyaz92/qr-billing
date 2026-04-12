import 'dart:typed_data';

abstract class IThermalPrinterService {
  Future<bool> connectToPrinter(String deviceAddress);
  Future<bool> printReceipt(Uint8List receiptData);
  Future<bool> disconnect();
  Future<List<String>> discoverPrinters();
  bool get isConnected;
}