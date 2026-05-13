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
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3), // Item Name
                    1: const pw.FlexColumnWidth(0.8), // Qty
                    2: const pw.FlexColumnWidth(1.8), // Price (MRP/Sell)
                    3: const pw.FlexColumnWidth(1.2), // Disc
                    4: const pw.FlexColumnWidth(1.8), // Amt (Excl. Tax)
                    5: const pw.FlexColumnWidth(1.8), // Tax (%/Amt)
                    6: const pw.FlexColumnWidth(2), // Total
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildHeaderCell('Item'),
                        _buildHeaderCell('Qty'),
                        _buildHeaderCell('Price'),
                        _buildHeaderCell('Disc'),
                        _buildHeaderCell('Amt\n(Excl Tax)'),
                        _buildHeaderCell('Tax'),
                        _buildHeaderCell('Total'),
                      ],
                    ),
                    // Item Rows
                    ...items.map((item) {
                      final mrp = (item['mrp'] ?? item['price'] ?? 0.0) as double;
                      final sellingPrice = (item['price'] ?? 0.0) as double;
                      final discount = (item['discount'] ?? 0.0) as double;
                      final amtExclTax = (item['amtExclTax'] ?? 0.0) as double;
                      final taxRate = (item['taxRate'] ?? 0.0) as double;
                      final taxAmount = (item['taxAmount'] ?? 0.0) as double;
                      final total = (item['total'] ?? 0.0) as double;

                      return pw.TableRow(
                        children: [
                          _buildCell(item['name'] ?? 'Unknown'),
                          _buildCell('${item['quantity']}'),
                          _buildCell(
                            mrp > sellingPrice 
                              ? 'MRP: ${mrp.toStringAsFixed(0)}\nSell: ${sellingPrice.toStringAsFixed(0)}'
                              : sellingPrice.toStringAsFixed(0),
                            align: pw.TextAlign.right
                          ),
                          _buildCell(discount > 0 ? discount.toStringAsFixed(0) : '-', align: pw.TextAlign.right),
                          _buildCell(amtExclTax.toStringAsFixed(0), align: pw.TextAlign.right),
                          _buildCell('${taxRate.toStringAsFixed(0)}%\n(${taxAmount.toStringAsFixed(1)})', align: pw.TextAlign.right),
                          _buildCell(total.toStringAsFixed(2), align: pw.TextAlign.right, isBold: true),
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
                      pw.Text('Subtotal: Rs. ${(summary['subtotal'] ?? 0.0 as double).toStringAsFixed(2)}'),
                      if ((summary['totalItemDiscounts'] ?? 0.0 as double) > 0)
                        pw.Text('Item Discounts: Rs. ${(summary['totalItemDiscounts'] as double).toStringAsFixed(2)}'),
                      if ((summary['taxAmount'] ?? 0.0 as double) > 0)
                        pw.Text('Tax: Rs. ${(summary['taxAmount'] as double).toStringAsFixed(2)}'),
                      if ((summary['discount'] ?? 0.0 as double) > 0)
                        pw.Text('Additional Discount: Rs. ${(summary['discount'] as double).toStringAsFixed(2)}'),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Final Total: Rs. ${(summary['finalTotal'] ?? 0.0 as double).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      if ((summary['youSave'] ?? 0.0 as double) > 0)
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

  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}
