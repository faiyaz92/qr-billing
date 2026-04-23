import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'i_print_service.dart';
import 'i_thermal_printer_service.dart';
import 'i_settings_service.dart';
import '../../data/models/product.dart';

/// Centralized printing coordinator that handles all printing logic
class PrintManager {
  final IPrintService _printService;
  final IThermalPrinterService _thermalPrinterService;
  final ISettingsService _settingsService;

  PrintManager(
    this._printService,
    this._thermalPrinterService,
    this._settingsService,
  );

  /// Print a bill with customer and item details
  Future<void> printBill({
    required String storeName,
    required String customerName,
    required String customerMobile,
    required String date,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> summary,
  }) async {
    final printerPreference = await _settingsService.getPrinterPreference();

    if (printerPreference == 'bluetooth') {
      if (!_thermalPrinterService.isConnected) {
        throw Exception('BLUETOOTH_PRINTER_NOT_CONNECTED');
      }

      // Format data for thermal printer
      final thermalData = _formatBillForThermal(storeName, customerName, customerMobile, date, items, summary);
      await _thermalPrinterService.printReceipt(thermalData);
    } else {
      // Create PDF for system printer
      final pdfBytes = await _createBillPdf(storeName, customerName, customerMobile, date, items, summary);
      await _printService.printTextPdf(pdfBytes);
    }
  }

  /// Print QR code for a product
  Future<void> printProductQR(Product product) async {
    final data = product.qrData ?? 'No QR data';
    final title = product.name ?? 'Product';
    final storeName = await _settingsService.getStoreName() ?? 'Store';
    final originalPrice = product.originalPrice;
    final sellingPrice = product.sellingPrice;

    final printerPreference = await _settingsService.getPrinterPreference();

    if (printerPreference == 'bluetooth' && _thermalPrinterService.isConnected) {
      final thermalData = _formatQRForThermal(title, data, storeName, originalPrice, sellingPrice);
      await _thermalPrinterService.printReceipt(thermalData);
    } else {
      final pdfBytes = await _createQRCodePdf(data, title, storeName, originalPrice, sellingPrice);
      await _printService.printQRCodePdf(pdfBytes);
    }
  }

  /// Print barcode for a product
  Future<void> printProductBarcode(Product product) async {
    final data = product.qrData ?? 'No data';
    final title = product.name ?? 'Product';

    final printerPreference = await _settingsService.getPrinterPreference();

    if (printerPreference == 'bluetooth' && _thermalPrinterService.isConnected) {
      final thermalData = _formatBarcodeForThermal(title, data);
      await _thermalPrinterService.printReceipt(thermalData);
    } else {
      final pdfBytes = await _createBarcodePdf(data, title);
      await _printService.printBarcodePdf(pdfBytes);
    }
  }

  /// Print custom QR code
  Future<void> printQRCode(String data, String title) async {
    final storeName = await _settingsService.getStoreName() ?? 'Store';
    final printerPreference = await _settingsService.getPrinterPreference();

    if (printerPreference == 'bluetooth' && _thermalPrinterService.isConnected) {
      final thermalData = _formatQRForThermal(title, data, storeName, null, 0.0);
      await _thermalPrinterService.printReceipt(thermalData);
    } else {
      final pdfBytes = await _createQRCodePdf(data, title, storeName, null, 0.0);
      await _printService.printQRCodePdf(pdfBytes);
    }
  }

  /// Print custom barcode
  Future<void> printBarcode(String data, String title) async {
    final printerPreference = await _settingsService.getPrinterPreference();

    if (printerPreference == 'bluetooth' && _thermalPrinterService.isConnected) {
      final thermalData = _formatBarcodeForThermal(title, data);
      await _thermalPrinterService.printReceipt(thermalData);
    } else {
      final pdfBytes = await _createBarcodePdf(data, title);
      await _printService.printBarcodePdf(pdfBytes);
    }
  }

  /// Print custom text
  Future<void> printText(String text, String title) async {
    final printerPreference = await _settingsService.getPrinterPreference();

    if (printerPreference == 'bluetooth' && _thermalPrinterService.isConnected) {
      final thermalData = _formatTextForThermal(title, text);
      await _thermalPrinterService.printReceipt(thermalData);
    } else {
      final pdfBytes = await _createTextPdf(text, title);
      await _printService.printTextPdf(pdfBytes);
    }
  }

  // Private helper methods for formatting

  List<LineText> _formatBillForThermal(
    String storeName,
    String customerName,
    String customerMobile,
    String date,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> summary,
  ) {
    List<LineText> list = [];

    // Header
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: storeName,
      weight: 2,
      align: LineText.ALIGN_CENTER,
      fontZoom: 2,
    ));

    list.add(LineText(linefeed: 1));

    // Customer details
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Customer: $customerName',
      align: LineText.ALIGN_LEFT,
    ));

    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Mobile: $customerMobile',
      align: LineText.ALIGN_LEFT,
    ));

    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Date: $date',
      align: LineText.ALIGN_LEFT,
    ));

    list.add(LineText(linefeed: 1));

    // Items header
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '--- Items ---',
      align: LineText.ALIGN_CENTER,
    ));

    list.add(LineText(linefeed: 1));

    // Items
    for (final item in items) {
      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '${item['name']}',
        align: LineText.ALIGN_LEFT,
      ));

      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Qty: ${item['quantity']} x Rs.${item['price'].toStringAsFixed(2)} = Rs.${item['total'].toStringAsFixed(2)}',
        align: LineText.ALIGN_LEFT,
      ));

      if (item['discount'] > 0) {
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '  (Discount: Rs.${(item['discount'] * item['quantity']).toStringAsFixed(2)})',
          align: LineText.ALIGN_LEFT,
        ));
      }

      list.add(LineText(linefeed: 1));
    }

    // Summary header
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '--- Summary ---',
      align: LineText.ALIGN_CENTER,
    ));

    list.add(LineText(linefeed: 1));

    // Summary details
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Subtotal: Rs.${summary['subtotal'].toStringAsFixed(2)}',
      align: LineText.ALIGN_LEFT,
    ));

    if (summary['totalItemDiscounts'] > 0) {
      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Item Discounts: Rs.${summary['totalItemDiscounts'].toStringAsFixed(2)}',
        align: LineText.ALIGN_LEFT,
      ));
    }

    if (summary['taxAmount'] > 0) {
      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Tax: Rs.${summary['taxAmount'].toStringAsFixed(2)}',
        align: LineText.ALIGN_LEFT,
      ));
    }

    if (summary['discount'] > 0) {
      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Additional Discount: Rs.${summary['discount'].toStringAsFixed(2)}',
        align: LineText.ALIGN_LEFT,
      ));
    }

    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Final Total: Rs.${summary['finalTotal'].toStringAsFixed(2)}',
      weight: 1,
      align: LineText.ALIGN_LEFT,
    ));

    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'You Save: Rs.${summary['youSave'].toStringAsFixed(2)}',
      align: LineText.ALIGN_LEFT,
    ));

    list.add(LineText(linefeed: 1));

    // App branding
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Powered by QR-Based Billing',
      align: LineText.ALIGN_CENTER,
      fontZoom: 1,
    ));

    // Spacing for cutting
    list.add(LineText(linefeed: 3));

    return list;
  }

  List<LineText> _formatQRForThermal(String title, String data, String storeName, double? originalPrice, double sellingPrice) {
    List<LineText> list = [];

    // Store name
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: storeName,
      weight: 2,
      align: LineText.ALIGN_CENTER,
      fontZoom: 2,
    ));

    list.add(LineText(linefeed: 1));

    // Product title
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: title,
      align: LineText.ALIGN_CENTER,
    ));

    list.add(LineText(linefeed: 1));

    // Price information (only show if selling price > 0)
    if (sellingPrice > 0.0) {
      if (originalPrice != null && originalPrice > sellingPrice) {
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'MRP: Rs.${originalPrice.toStringAsFixed(2)}',
          align: LineText.ALIGN_CENTER,
        ));
      }

      list.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Price: Rs.${sellingPrice.toStringAsFixed(2)}',
        weight: 1,
        align: LineText.ALIGN_CENTER,
      ));

      list.add(LineText(linefeed: 1));
    }

    // QR Code
    list.add(LineText(
      type: LineText.TYPE_QRCODE,
      content: data,
      align: LineText.ALIGN_CENTER,
      size: 6, // QR code size
    ));

    // Spacing for cutting
    list.add(LineText(linefeed: 3));

    return list;
  }

  List<LineText> _formatBarcodeForThermal(String title, String data) {
    List<LineText> list = [];

    // Header
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'QR-Based Billing',
      weight: 2,
      align: LineText.ALIGN_CENTER,
      fontZoom: 2,
    ));

    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: title,
      align: LineText.ALIGN_CENTER,
    ));

    list.add(LineText(linefeed: 1));

    // Barcode
    list.add(LineText(
      type: LineText.TYPE_BARCODE,
      content: data,
      align: LineText.ALIGN_CENTER,
      width: 2,
      height: 80,
    ));

    list.add(LineText(linefeed: 1));

    // Date
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Date: ${DateTime.now().toString().split(' ')[0]}',
      align: LineText.ALIGN_CENTER,
    ));

    list.add(LineText(linefeed: 1));

    // App branding
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Powered by QR-Based Billing',
      align: LineText.ALIGN_CENTER,
      fontZoom: 1,
    ));

    // Spacing for cutting
    list.add(LineText(linefeed: 3));

    return list;
  }

  List<LineText> _formatTextForThermal(String title, String text) {
    List<LineText> list = [];

    // Header
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'QR-Based Billing',
      weight: 2,
      align: LineText.ALIGN_CENTER,
      fontZoom: 2,
    ));

    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: title,
      align: LineText.ALIGN_CENTER,
    ));

    list.add(LineText(linefeed: 1));

    // Text content
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: text,
      align: LineText.ALIGN_LEFT,
    ));

    list.add(LineText(linefeed: 1));

    // Date
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Date: ${DateTime.now().toString().split(' ')[0]}',
      align: LineText.ALIGN_CENTER,
    ));

    list.add(LineText(linefeed: 1));

    // App branding
    list.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Powered by QR-Based Billing',
      align: LineText.ALIGN_CENTER,
      fontZoom: 1,
    ));

    // Spacing for cutting
    list.add(LineText(linefeed: 3));

    return list;
  }

  Future<Uint8List> _createBillPdf(
    String storeName,
    String customerName,
    String customerMobile,
    String date,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> summary,
  ) async {
    final pdf = pw.Document();

    final billText = StringBuffer();
    billText.writeln(storeName);
    billText.writeln('Customer: $customerName');
    billText.writeln('Mobile: $customerMobile');
    billText.writeln('Date: $date');
    billText.writeln('--- Items ---');

    for (final item in items) {
      billText.writeln('${item['name']} x${item['quantity']} = Rs.${item['total'].toStringAsFixed(2)}');
      if (item['discount'] > 0) {
        billText.writeln('  (Discount: Rs.${(item['discount'] * item['quantity']).toStringAsFixed(2)})');
      }
    }

    billText.writeln('--- Summary ---');
    billText.writeln('Subtotal: Rs.${summary['subtotal'].toStringAsFixed(2)}');

    if (summary['totalItemDiscounts'] > 0) {
      billText.writeln('Item Discounts: Rs.${summary['totalItemDiscounts'].toStringAsFixed(2)}');
    }

    if (summary['taxAmount'] > 0) {
      billText.writeln('Tax: Rs.${summary['taxAmount'].toStringAsFixed(2)}');
    }

    if (summary['discount'] > 0) {
      billText.writeln('Additional Discount: Rs.${summary['discount'].toStringAsFixed(2)}');
    }

    billText.writeln('Final Total: Rs.${summary['finalTotal'].toStringAsFixed(2)}');
    billText.writeln('You Save: Rs.${summary['youSave'].toStringAsFixed(2)}');

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 50),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(storeName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                ...billText.toString().split('\n').map((line) => pw.Text(line, style: pw.TextStyle(fontSize: 12))),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Powered by QR-Based Billing',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey,
                  ),
                ),
                pw.SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  Future<Uint8List> _createQRCodePdf(String data, String title, String storeName, double? originalPrice, double sellingPrice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 50),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(storeName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text(title, style: pw.TextStyle(fontSize: 20)),
                  pw.SizedBox(height: 15),
                  // Price information (only show if selling price > 0)
                  if (sellingPrice > 0.0) ...[
                    if (originalPrice != null && originalPrice > sellingPrice)
                      pw.Text(
                        'MRP: Rs.${originalPrice.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          decoration: pw.TextDecoration.lineThrough,
                          color: PdfColors.grey,
                        ),
                      ),
                    pw.Text(
                      'Price: Rs.${sellingPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: data,
                    width: 200,
                    height: 200,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Scan this QR code', style: pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  Future<Uint8List> _createBarcodePdf(String data, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 50),
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
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Powered by QR-Based Billing',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  Future<Uint8List> _createTextPdf(String text, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 50),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                ...text.split('\n').map((line) => pw.Text(line, style: pw.TextStyle(fontSize: 12))),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Powered by QR-Based Billing',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey,
                  ),
                ),
                pw.SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Check if bluetooth printer is preferred and connected
  Future<bool> isBluetoothPrinterAvailable() async {
    final preference = await _settingsService.getPrinterPreference();
    return preference == 'bluetooth' && _thermalPrinterService.isConnected;
  }

  /// Get current printer preference
  Future<String> getPrinterPreference() async {
    return await _settingsService.getPrinterPreference();
  }
}