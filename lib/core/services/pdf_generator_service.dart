import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGeneratorService {
  /// Generates a standardized, beautiful PDF for a bill.
  /// This centralized method ensures the bill design is identical across the entire app.
  Future<Uint8List> generateBillPdf({
    required String storeName,
    required String customerName,
    required String customerMobile,
    required String date,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> summary,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'BILL RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Store & Customer Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            storeName,
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text('Date: $date'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Customer: $customerName',
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('Mobile: $customerMobile', style: pw.TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Items Header
                pw.Text(
                  'Items:',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),

                // Items Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Item Rows
                    ...items.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(item['name'] ?? 'Unknown Product'),
                                if ((item['discount'] ?? 0.0) > 0)
                                  pw.Text(
                                    '(Discount: Rs. ${((item['discount'] as double) * (item['quantity'] as int)).toStringAsFixed(2)})',
                                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                                  ),
                              ],
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('${item['quantity']}'),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Rs. ${(item['price'] as double).toStringAsFixed(2)}'),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Rs. ${(item['total'] as double).toStringAsFixed(2)}'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Summary Section
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: Rs. ${(summary['subtotal'] as double).toStringAsFixed(2)}'),
                      if ((summary['totalItemDiscounts'] as double) > 0)
                        pw.Text('Item Discounts: Rs. ${(summary['totalItemDiscounts'] as double).toStringAsFixed(2)}'),
                      if ((summary['taxAmount'] as double) > 0)
                        pw.Text('Tax: Rs. ${(summary['taxAmount'] as double).toStringAsFixed(2)}'),
                      if ((summary['discount'] as double) > 0)
                        pw.Text('Additional Discount: Rs. ${(summary['discount'] as double).toStringAsFixed(2)}'),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Final Total: Rs. ${(summary['finalTotal'] as double).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      if ((summary['youSave'] as double) > 0)
                        pw.Text(
                          'You Save: Rs. ${(summary['youSave'] as double).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green700,
                          ),
                        ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Footer
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Powered by QR-Based Billing',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }
}
