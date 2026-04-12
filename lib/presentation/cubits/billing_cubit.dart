import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection.dart';
import '../../core/services/i_print_service.dart';
import '../../core/services/i_thermal_printer_service.dart';
import '../../core/services/i_scan_service.dart';
import '../../core/services/i_encryption_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../data/models/scanned_data.dart';
import '../../data/database_helper.dart';
import '../../data/models/bill.dart';
import '../../data/models/bill_item.dart';
import '../../data/models/product.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class CartItem {
  final ScannedData data;
  final Product product;
  int quantity;
  double itemDiscount; // Individual item discount

  CartItem({required this.data, required this.product, this.quantity = 1, this.itemDiscount = 0.0});
}

abstract class BillingState {}

class BillingLoading extends BillingState {}

class BillingUpdated extends BillingState {
  final List<CartItem> cart;
  final bool isScanningPaused;
  final String? customerMobile;
  final String? customerName;
  final double discount;
  final double taxRate; // Tax rate in percentage (e.g., 18.0 for 18%)
  final bool duplicateDetected;
  final String? duplicateProductName;
  final bool showProfitLossMode; // New field for profit/loss toggle
  final bool isEditMode; // New field for edit mode

  BillingUpdated(this.cart, {this.isScanningPaused = false, this.customerMobile, this.customerName, this.discount = 0.0, this.taxRate = 0.0, this.duplicateDetected = false, this.duplicateProductName, this.showProfitLossMode = false, this.isEditMode = false});
}

class BillingError extends BillingState {
  final String message;
  BillingError(this.message);
}

class BillingCubit extends Cubit<BillingState> {
  final IScanService _scanService = getIt<IScanService>();
  final IPrintService _printService = getIt<IPrintService>();
  final IThermalPrinterService _thermalPrinterService = getIt<IThermalPrinterService>();
  final IEncryptionService _encryptionService = getIt<IEncryptionService>();
  List<CartItem> _cart = [];
  bool _showProfitLossMode = false; // Track profit/loss mode
  int? _currentBillId; // Track current bill ID for updates
  bool _isEditMode = false; // Track if we're in edit mode

  BillingCubit() : super(BillingUpdated([], showProfitLossMode: false, isEditMode: false, taxRate: 0.0));

  void toggleProfitLossMode() {
    _showProfitLossMode = !_showProfitLossMode;
    final currentState = state as BillingUpdated;
    emit(BillingUpdated(
      List.from(_cart),
      isScanningPaused: currentState.isScanningPaused,
      customerMobile: currentState.customerMobile,
      customerName: currentState.customerName,
      discount: currentState.discount,
      taxRate: currentState.taxRate,
      duplicateDetected: currentState.duplicateDetected,
      duplicateProductName: currentState.duplicateProductName,
      showProfitLossMode: _showProfitLossMode,
      isEditMode: _isEditMode,
    ));
  }

  Future<void> scanProduct(String qrCode, {bool continuousScan = false}) async {
    emit(BillingLoading());
    try {
      final scannedData = await _scanService.scanAndDecode(qrCode);
      if (scannedData != null) {
        // Debug: Print scanned data
        print('Scanned data: ${scannedData.data}');
        final productData = scannedData.data;
        
        // Decrypt sensitive data to get purchase price
        double purchasePrice = 0.0;
        if (productData['encrypted_sensitive'] != null) {
          try {
            final decryptedSensitive = _encryptionService.decryptData(productData['encrypted_sensitive']);
            final sensitiveData = jsonDecode(decryptedSensitive) as Map<String, dynamic>;
            purchasePrice = double.tryParse(sensitiveData['purchase_price']?.toString() ?? '0') ?? 0.0;
            print('Decrypted purchase price: $purchasePrice');
          } catch (e) {
            print('Failed to decrypt sensitive data: $e');
            purchasePrice = 0.0;
          }
        }
        
        final product = Product(
          name: productData['name']?.toString(),
          brand: productData['brand']?.toString(),
          sellingPrice: double.tryParse(productData['selling_price']?.toString() ?? '0') ?? 0.0,
          originalPrice: double.tryParse(productData['original_price']?.toString() ?? '0'),
          tax: double.tryParse(productData['tax']?.toString() ?? '0'),
          qrData: scannedData.qrCode,
          purchasePrice: purchasePrice, // Use decrypted purchase price
        );
        
        // Don't save product to database - bills will be created entirely from scanned data
        // Product ID will be null for bill items
        final productWithId = Product(
          id: null, // No product ID - bill items won't depend on products table
          name: product.name,
          brand: product.brand,
          sellingPrice: product.sellingPrice,
          originalPrice: product.originalPrice,
          tax: product.tax,
          qrData: product.qrData,
          purchasePrice: product.purchasePrice,
        );
        
        // Debug: Print created product
        print('Created product: ${productWithId.name}, ID: ${productWithId.id}, selling: ${productWithId.sellingPrice}, purchase: ${productWithId.purchasePrice}');

        // Check if already in cart (by QR code to prevent duplicates)
        final existingIndex = _cart.indexWhere((item) => item.data.qrCode == scannedData.qrCode);
        if (existingIndex == -1) {
          _cart.add(CartItem(data: scannedData, product: productWithId));
          print('Added new item to cart. Cart size: ${_cart.length}');
          emit(BillingUpdated(List.from(_cart), isScanningPaused: !continuousScan, showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
          print('Emitted BillingUpdated state with ${_cart.length} items, paused: ${!continuousScan}');
        } else {
          print('Product already in cart, emitting duplicate notification');
          // For duplicate, emit BillingUpdated with current cart and duplicate flag
          emit(BillingUpdated(List.from(_cart), isScanningPaused: false, duplicateDetected: true, duplicateProductName: productWithId.name ?? 'Unknown Product', showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
        }
        // Pause handled in screen
      } else {
        emit(BillingError('Invalid QR'));
      }
    } catch (e, stackTrace) {
      print('Error in scanProduct: $e');
      print('Stack trace: $stackTrace');
      emit(BillingError(e.toString()));
    }
  }

  void updateQuantity(int index, int delta) {
    if (index >= 0 && index < _cart.length) {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) {
        _cart.removeAt(index);
      }
      emit(BillingUpdated(List.from(_cart), showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
    }
  }

  void updateItemDiscount(int index, double discount) {
    if (index >= 0 && index < _cart.length) {
      _cart[index].itemDiscount = discount;
      emit(BillingUpdated(List.from(_cart), showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _cart.length) {
      _cart.removeAt(index);
      emit(BillingUpdated(List.from(_cart), showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
    }
  }

  void clearCart() {
    _cart.clear();
    _currentBillId = null; // Reset bill ID when clearing cart
    _isEditMode = false; // Reset edit mode when clearing cart
    emit(BillingUpdated(List.from(_cart), showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
  }

  Future<void> saveBill(double discount) async {
    final currentState = state as BillingUpdated;
    final db = DatabaseHelper();
    final total = calculateTotal();
    final finalTotal = total - discount;
    
    // Calculate total purchase amount for profit tracking
    final purchaseAmount = _cart.fold(0.0, (sum, item) => sum + (item.product.purchasePrice * item.quantity));
    
    final bill = Bill(
      id: _currentBillId, // Use existing ID if updating
      date: DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD
      totalAmount: total,
      discount: discount,
      finalTotal: finalTotal,
      purchaseAmount: purchaseAmount,
      customerName: currentState.customerName,
      customerMobile: currentState.customerMobile,
    );
    
    int billId;
    if (_currentBillId != null) {
      // Update existing bill
      await db.updateBill(bill);
      billId = _currentBillId!;
      
      // Delete existing bill items and re-insert (simpler than updating each one)
      await db.deleteBillItems(billId);
    } else {
      // Insert new bill
      billId = await db.insertBill(bill);
      _currentBillId = billId; // Store the bill ID for future updates
    }
    
    // Save individual bill items with prices for profit tracking
    for (final item in _cart) {
      final billItem = BillItem(
        billId: billId,
        productId: item.product.id, // Now optional - can be null
        itemName: item.data.data['name']?.toString() ?? 'Unknown Item', // Save item name from scanned data
        quantity: item.quantity,
        itemDiscount: item.itemDiscount, // Use actual item discount
        purchasePrice: item.product.purchasePrice,
        sellingPrice: item.product.sellingPrice,
        taxRate: item.product.tax ?? 0.0,
      );
      await db.insertBillItem(billItem);
    }
    
    // Don't clear cart here - only clear when starting new bill
  }

  Future<void> markBillAsPaid() async {
    final currentState = state as BillingUpdated;
    await saveBill(currentState.discount);
    clearCart(); // Clear cart after payment
  }

  void setCustomerMobile(String mobile) {
    final currentState = state as BillingUpdated;
    emit(BillingUpdated(List.from(_cart), customerMobile: mobile, customerName: currentState.customerName, discount: currentState.discount, taxRate: currentState.taxRate, showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
  }

  void setCustomerName(String name) {
    final currentState = state as BillingUpdated;
    emit(BillingUpdated(List.from(_cart), customerMobile: currentState.customerMobile, customerName: name, discount: currentState.discount, taxRate: currentState.taxRate, showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
  }

  void setDiscount(double discount) {
    final currentState = state as BillingUpdated;
    emit(BillingUpdated(List.from(_cart), customerMobile: currentState.customerMobile, customerName: currentState.customerName, discount: discount, taxRate: currentState.taxRate, showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
  }

  void setTaxRate(double taxRate) {
    // No longer needed - using per-product taxes
  }

  double getTaxRate() => 0.0; // Return 0 for backward compatibility

  Future<void> printBill() async {
    final currentState = state as BillingUpdated;
    
    // Save bill before printing (will update if already exists)
    await saveBill(currentState.discount);
    
    // Check if thermal printer is connected
    if (_thermalPrinterService.isConnected) {
      // Use thermal printer
      final billData = StringBuffer();
      billData.writeln('BILL|Bill Receipt|');
      billData.writeln('Customer: ${currentState.customerName ?? 'N/A'}');
      billData.writeln('Mobile: ${currentState.customerMobile ?? 'N/A'}');
      billData.writeln('Date: ${DateTime.now().toString().split(' ')[0]}');
      billData.writeln('--- Items ---');
      
      for (final item in _cart) {
        final itemTotal = (item.product.sellingPrice - item.itemDiscount) * item.quantity;
        billData.writeln('${item.product.name} x${item.quantity} = ₹${itemTotal.toStringAsFixed(2)}');
        if (item.itemDiscount > 0) {
          billData.writeln('  (Discount: ₹${(item.itemDiscount * item.quantity).toStringAsFixed(2)})');
        }
      }
      
      billData.writeln('--- Summary ---');
      billData.writeln('Subtotal: ₹${calculateTotal().toStringAsFixed(2)}');
      
      // Calculate and show total item discounts
      final totalItemDiscounts = _cart.fold<double>(0.0, (sum, item) => sum + (item.itemDiscount * item.quantity));
      if (totalItemDiscounts > 0) {
        billData.writeln('Item Discounts: ₹${totalItemDiscounts.toStringAsFixed(2)}');
      }
      
      final taxAmount = calculateTaxAmount();
      if (taxAmount > 0) {
        billData.writeln('Tax: ₹${taxAmount.toStringAsFixed(2)}');
      }
      if (currentState.discount > 0) {
        billData.writeln('Additional Discount: ₹${currentState.discount.toStringAsFixed(2)}');
      }
      final finalTotal = calculateFinalTotal();
      billData.writeln('Final Total: ₹${finalTotal.toStringAsFixed(2)}');
      billData.writeln(''); // Empty line for spacing
      billData.writeln(''); // Empty line for cutting
      billData.writeln(''); // Empty line for cutting
      billData.writeln(''); // Empty line for cutting
      
      final payload = 'TEXT|Bill Receipt|${billData.toString()}';
      await _thermalPrinterService.printReceipt(Uint8List.fromList(utf8.encode(payload)));
    } else {
      // Fall back to system printer
      final billData = StringBuffer();
      billData.writeln('Bill Receipt');
      billData.writeln('Customer: ${currentState.customerName ?? 'N/A'}');
      billData.writeln('Mobile: ${currentState.customerMobile ?? 'N/A'}');
      billData.writeln('Date: ${DateTime.now().toString().split(' ')[0]}');
      billData.writeln('--- Items ---');
      
      for (final item in _cart) {
        final itemTotal = (item.product.sellingPrice - item.itemDiscount) * item.quantity;
        billData.writeln('${item.product.name} x${item.quantity} = ₹${itemTotal.toStringAsFixed(2)}');
        if (item.itemDiscount > 0) {
          billData.writeln('  (Discount: ₹${(item.itemDiscount * item.quantity).toStringAsFixed(2)})');
        }
      }
      
      billData.writeln('--- Summary ---');
      billData.writeln('Subtotal: ₹${calculateTotal().toStringAsFixed(2)}');
      
      // Calculate and show total item discounts
      final totalItemDiscounts = _cart.fold<double>(0.0, (sum, item) => sum + (item.itemDiscount * item.quantity));
      if (totalItemDiscounts > 0) {
        billData.writeln('Item Discounts: ₹${totalItemDiscounts.toStringAsFixed(2)}');
      }
      
      final taxAmount = calculateTaxAmount();
      if (taxAmount > 0) {
        billData.writeln('Tax: ₹${taxAmount.toStringAsFixed(2)}');
      }
      if (currentState.discount > 0) {
        billData.writeln('Additional Discount: ₹${currentState.discount.toStringAsFixed(2)}');
      }
      final finalTotal = calculateFinalTotal();
      billData.writeln('Final Total: ₹${finalTotal.toStringAsFixed(2)}');
      billData.writeln(''); // Empty line for spacing
      billData.writeln(''); // Empty line for cutting
      billData.writeln(''); // Empty line for cutting
      billData.writeln(''); // Empty line for cutting
      
      await _printService.printText(billData.toString(), 'Bill Receipt');
    }
  }

  Future<void> shareViaEmail(String email) async {
    final currentState = state as BillingUpdated;
    await saveBill(currentState.discount);
    // Generate PDF
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

                // Customer Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Customer: ${currentState.customerName ?? 'N/A'}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Mobile: ${currentState.customerMobile ?? 'N/A'}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Date: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Items Header
                pw.Text(
                  'Items:',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),

                // Items List
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header Row
                    pw.TableRow(
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
                    ..._cart.map((item) {
                      final data = item.data.data;
                      final sellingPrice = double.tryParse(data['selling_price']?.toString() ?? '0') ?? 0.0;
                      final itemTotal = sellingPrice * item.quantity;
                      return pw.TableRow(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(data['name'] ?? 'Unknown Product'),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('${item.quantity}'),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('₹${sellingPrice.toStringAsFixed(2)}'),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('₹${itemTotal.toStringAsFixed(2)}'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Summary
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Subtotal: ₹${calculateTotal().toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      if (calculateTaxAmount() > 0)
                        pw.Text(
                          'Tax: ₹${calculateTaxAmount().toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      if (currentState.discount > 0)
                        pw.Text(
                          'Discount: ₹${currentState.discount.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      pw.Text(
                        'Final Total: ₹${calculateFinalTotal().toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share via Email - opens share dialog with email apps
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Bill Receipt for $email',
      subject: 'Bill Receipt',
    );
  }

  Future<void> shareViaWhatsApp(String mobile) async {
    final currentState = state as BillingUpdated;
    await saveBill(currentState.discount);
    // Generate PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Bill Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              ..._cart.map((item) {
                return pw.Row(
                  children: [
                    pw.Text('${item.product.name} x${item.quantity}'),
                    pw.Spacer(),
                    pw.Text('${(item.product.sellingPrice * item.quantity).toStringAsFixed(2)}'),
                  ],
                );
              }),
              pw.Divider(),
              if (calculateTaxAmount() > 0) pw.Text('Tax: ${calculateTaxAmount().toStringAsFixed(2)}'),
              if (currentState.discount > 0) pw.Text('Discount: ${currentState.discount.toStringAsFixed(2)}'),
              pw.Text('Total: ${calculateFinalTotal().toStringAsFixed(2)}'),
            ],
          );
        },
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share to WhatsApp
    final whatsappUrl = 'whatsapp://send?phone=$mobile&text=Here is your bill';
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
      // Note: Sharing file via WhatsApp URL is limited; user can attach manually or use share_plus with WhatsApp
    } else {
      // Fallback to general share
      await Share.shareXFiles([XFile(file.path)], text: 'Bill Receipt for $mobile');
    }
  }

  Future<void> loadBillForView(int billId) async {
    print('Loading bill for view: $billId');
    final db = DatabaseHelper();
    final items = await db.getBillItems(billId);
    final bill = await db.getAllBills().then((bills) => bills.firstWhere((b) => b.id == billId));
    print('Bill data: discount=${bill.discount}, totalAmount=${bill.totalAmount}');
    
    // Clear cart
    _cart.clear();
    _currentBillId = billId; // Set current bill ID for updates
    _isEditMode = true; // Enable edit mode
    // Add items - create ScannedData from bill item data
    for (final item in items) {
      print('Processing bill item: id=${item.id}, productId=${item.productId}, itemName=${item.itemName}, taxRate=${item.taxRate}');
      
      // Use item name directly from bill item (no dependency on products table)
      String productName = item.itemName;
      String? brand = null; // Brand not stored in bill items
      double taxRate = item.taxRate ?? 0.0;
      
      print('Using item name from bill: $productName, tax: $taxRate');
      
      // Create a Product from bill item data
      final product = Product(
        id: item.productId,
        name: productName,
        brand: brand,
        sellingPrice: item.sellingPrice,
        purchasePrice: item.purchasePrice,
        originalPrice: null,
        tax: taxRate,
        qrData: null,
      );
      
      // Create ScannedData from bill item data
      final data = {
        'name': productName,
        'brand': brand,
        'selling_price': item.sellingPrice.toString(),
        'original_price': null,
        'tax': taxRate.toString(),
      };
      final scannedData = ScannedData(
        data: data,
        qrCode: '', // No QR code for loaded bills
      );
      
      _cart.add(CartItem(data: scannedData, product: product, quantity: item.quantity, itemDiscount: item.itemDiscount ?? 0.0));
    }
    emit(BillingUpdated(List.from(_cart), discount: bill.discount ?? 0.0, customerName: bill.customerName, customerMobile: bill.customerMobile, showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
  }

  double calculateTotal() {
    return _cart.fold(0.0, (sum, item) => sum + ((item.product.sellingPrice - item.itemDiscount) * item.quantity));
  }

  double calculateTaxAmount() {
    return _cart.fold(0.0, (sum, item) {
      final itemTotal = (item.product.sellingPrice - item.itemDiscount) * item.quantity;
      final taxRate = item.product.tax ?? 0.0;
      final itemTax = itemTotal * (taxRate / 100);
      return sum + itemTax;
    });
  }

  double calculateFinalTotal() {
    final subtotal = calculateTotal();
    final taxAmount = calculateTaxAmount();
    final currentState = state as BillingUpdated;
    return subtotal + taxAmount - currentState.discount;
  }

  // Temporary method for testing in emulator - adds dummy products to cart
  void addDummyProductsForTesting() {
    _currentBillId = null; // Reset bill ID for new cart
    _isEditMode = false; // Reset edit mode for new cart
    // ... existing code ...
    final dummyProducts = [
      {
        'name': 'Lays Classic Salted',
        'brand': 'Lays',
        'selling_price': '20.0',
        'purchase_price': '15.0',
        'original_price': '25.0',
        'tax': '5.0',
      },
      {
        'name': 'Coca Cola 500ml',
        'brand': 'Coca Cola',
        'selling_price': '45.0',
        'purchase_price': '35.0',
        'original_price': '50.0',
        'tax': '10.0',
      },
      {
        'name': 'Parle-G Biscuit',
        'brand': 'Parle',
        'selling_price': '10.0',
        'purchase_price': '7.0',
        'original_price': '12.0',
        'tax': '2.0',
      },
      {
        'name': 'Amul Milk 1L',
        'brand': 'Amul',
        'selling_price': '65.0',
        'purchase_price': '55.0',
        'original_price': '70.0',
        'tax': '8.0',
      },
    ];

    for (final productData in dummyProducts) {
      final product = Product(
        name: productData['name'],
        brand: productData['brand'],
        sellingPrice: double.parse(productData['selling_price']!),
        purchasePrice: double.parse(productData['purchase_price']!),
        originalPrice: double.tryParse(productData['original_price'] ?? '0'),
        tax: double.tryParse(productData['tax'] ?? '0'),
        qrData: 'dummy_qr_${productData['name']}',
      );

      final scannedData = ScannedData(
        data: productData,
        qrCode: 'dummy_qr_${productData['name']}',
      );

      // Check if already in cart
      final existingIndex = _cart.indexWhere((item) => item.product.name == product.name);
      if (existingIndex == -1) {
        _cart.add(CartItem(data: scannedData, product: product));
      }
    }

    emit(BillingUpdated(List.from(_cart), showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
  }

  Future<void> shareBillPdf() async {
    final currentState = state as BillingUpdated;

    // Save bill before sharing (will update if already exists)
    await saveBill(currentState.discount);

    // Generate PDF with actual bill data
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

                // Customer Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Customer: ${currentState.customerName ?? 'N/A'}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Mobile: ${currentState.customerMobile ?? 'N/A'}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Date: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Items Header
                pw.Text(
                  'Items:',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),

                // Items List
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header Row
                    pw.TableRow(
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
                    ..._cart.map((item) {
                      final data = item.data.data;
                      final sellingPrice = double.tryParse(data['selling_price']?.toString() ?? '0') ?? 0.0;
                      final itemTotal = sellingPrice * item.quantity;
                      return pw.TableRow(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(data['name'] ?? 'Unknown Product'),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('${item.quantity}'),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('₹${sellingPrice.toStringAsFixed(2)}'),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('₹${itemTotal.toStringAsFixed(2)}'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Summary
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Subtotal: ₹${calculateTotal().toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 14),
                      ),
                      if (calculateTaxAmount() > 0)
                        pw.Text(
                          'Tax: ₹${calculateTaxAmount().toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      if (currentState.discount > 0)
                        pw.Text(
                          'Discount: ₹${currentState.discount.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      pw.Text(
                        'Final Total: ₹${calculateFinalTotal().toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save PDF to temporary file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share the PDF file
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Bill Receipt - ${currentState.customerName ?? 'Customer'}',
      subject: 'Bill Receipt',
    );
  }
}