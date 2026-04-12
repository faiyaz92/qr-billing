import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'i_print_service.dart';

class PrintServiceImpl implements IPrintService {
  @override
  Future<void> printQRCode(String data, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 50), // Add space at bottom for cutting
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(title, style: pw.TextStyle(fontSize: 20)),
                  pw.SizedBox(height: 20),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: data,
                    width: 200,
                    height: 200,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Scan this QR code', style: pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 40), // Extra space for cutting
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Future<void> printBarcode(String data, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 50), // Add space at bottom for cutting
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(title, style: pw.TextStyle(fontSize: 20)),
                  pw.SizedBox(height: 20),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: data,
                    width: 300,
                    height: 100,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(data, style: pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 40), // Extra space for cutting
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Future<void> printText(String text, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 50), // Add space at bottom for cutting
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                ...text.split('\n').map((line) => pw.Text(line, style: pw.TextStyle(fontSize: 12))),
                pw.SizedBox(height: 40), // Extra space for cutting
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}