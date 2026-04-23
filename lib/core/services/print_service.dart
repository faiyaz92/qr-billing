import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'i_print_service.dart';

class PrintServiceImpl implements IPrintService {
  @override
  Future<void> printPdfDocument(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  @override
  Future<void> printQRCodePdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  @override
  Future<void> printBarcodePdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  @override
  Future<void> printTextPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }
}