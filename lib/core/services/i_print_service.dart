abstract class IPrintService {
  Future<void> printQRCode(String data, String title);
  Future<void> printBarcode(String data, String title);
  Future<void> printText(String text, String title);
}