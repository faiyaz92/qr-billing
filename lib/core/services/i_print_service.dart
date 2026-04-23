import 'dart:typed_data';

abstract class IPrintService {
  /// Print a pre-formatted PDF document
  Future<void> printPdfDocument(Uint8List pdfBytes);

  /// Print QR code with pre-formatted PDF
  Future<void> printQRCodePdf(Uint8List pdfBytes);

  /// Print barcode with pre-formatted PDF
  Future<void> printBarcodePdf(Uint8List pdfBytes);

  /// Print text with pre-formatted PDF
  Future<void> printTextPdf(Uint8List pdfBytes);
}