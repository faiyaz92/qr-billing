import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/print_manager.dart';
import '../../core/services/pdf_generator_service.dart';
import '../../core/services/i_scan_service.dart';
import '../../core/services/i_encryption_service.dart';
import '../../core/services/i_settings_service.dart';
import '../../domain/repositories/i_bill_repository.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../data/models/scanned_data.dart';
import '../../data/models/bill.dart';
import '../../data/models/bill_item.dart';
import '../../data/models/product.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import 'billing_state.dart';

class BillingCubit extends Cubit<BillingState> {
  final IScanService _scanService;
  final PrintManager _printManager;
  final IEncryptionService _encryptionService;
  final ISettingsService _settingsService;
  final IBillRepository _billRepository;
  final PdfGeneratorService _pdfGeneratorService;
  List<CartItem> _cart = [];
  bool _showProfitLossMode = false; // Track profit/loss mode
  int? _currentBillId; // Track current bill ID for updates
  bool _isEditMode = false; // Track if we're in edit mode

  BillingCubit({
    required IScanService scanService,
    required PrintManager printManager,
    required IEncryptionService encryptionService,
    required ISettingsService settingsService,
    required IBillRepository billRepository,
    required PdfGeneratorService pdfGeneratorService,
  }) : _scanService = scanService,
       _printManager = printManager,
       _encryptionService = encryptionService,
       _settingsService = settingsService,
       _billRepository = billRepository,
       _pdfGeneratorService = pdfGeneratorService,
       super(const BillingUpdated(cart: [], showProfitLossMode: false, isEditMode: false, taxRate: 0.0));

  void toggleProfitLossMode() {
    _showProfitLossMode = !_showProfitLossMode;
    final currentState = state;
    if (currentState is BillingUpdated) {
      emit(currentState.copyWith(showProfitLossMode: _showProfitLossMode));
    }
  }

  void addProductToCart({
    required Product product,
    required ScannedData scannedData,
    int quantity = 1,
  }) {
    if (quantity <= 0) return;

    final existingIndex = _cart.indexWhere((item) {
      final newQr = scannedData.qrCode;
      final oldQr = item.data.qrCode;
      if (newQr.isNotEmpty && oldQr.isNotEmpty) {
        return oldQr == newQr;
      }
      return item.product.name == product.name && item.product.brand == product.brand;
    });

    if (existingIndex == -1) {
      _cart.add(CartItem(
        data: scannedData,
        product: product,
        quantity: quantity,
      ));
    } else {
      _cart[existingIndex] = _cart[existingIndex].copyWith(
        quantity: _cart[existingIndex].quantity + quantity,
      );
    }

    final currentState = state;
    if (currentState is BillingUpdated) {
      emit(currentState.copyWith(
        cart: List.from(_cart),
        duplicateDetected: false,
        duplicateProductName: null,
      ));
      return;
    }

    emit(BillingUpdated(
      cart: List.from(_cart),
      showProfitLossMode: _showProfitLossMode,
      isEditMode: _isEditMode,
    ));
  }

  Future<void> scanProduct(String qrCode, {bool continuousScan = false}) async {
    emit(BillingLoading());
    try {
      final scannedData = await _scanService.scanAndDecode(qrCode);
      if (scannedData != null) {
        final productData = scannedData.data;
        
        // Decrypt sensitive data to get purchase price
        double purchasePrice = 0.0;
        if (productData['encrypted_sensitive'] != null) {
          try {
            final decryptedSensitive = _encryptionService.decryptData(productData['encrypted_sensitive']);
            final sensitiveData = jsonDecode(decryptedSensitive) as Map<String, dynamic>;
            purchasePrice = double.tryParse(sensitiveData['purchase_price']?.toString() ?? '0') ?? 0.0;
          } catch (e) {
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

        // Check if already in cart (by QR code to prevent duplicates)
        final existingIndex = _cart.indexWhere((item) => item.data.qrCode == scannedData.qrCode);
        if (existingIndex == -1) {
          _cart.add(CartItem(data: scannedData, product: productWithId));
          final currentState = state;
          if (currentState is BillingUpdated) {
             emit(currentState.copyWith(
               cart: List.from(_cart),
               isScanningPaused: !continuousScan,
             ));
          } else {
            emit(BillingUpdated(cart: List.from(_cart), isScanningPaused: !continuousScan, showProfitLossMode: _showProfitLossMode, isEditMode: _isEditMode));
          }
        } else {
          final currentState = state;
          if (currentState is BillingUpdated) {
            emit(currentState.copyWith(
              duplicateDetected: true,
              duplicateProductName: productWithId.name ?? 'Unknown Product',
            ));
          }
        }
        // Pause handled in screen
      } else {
        emit(BillingError('Invalid QR'));
      }
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }

  void updateQuantity(int index, int delta) {
    if (index >= 0 && index < _cart.length) {
      final newQuantity = _cart[index].quantity + delta;
      if (newQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
      }
      emit(BillingUpdated(
        cart: List.from(_cart), 
        showProfitLossMode: _showProfitLossMode, 
        isEditMode: _isEditMode
      ));
    }
  }

  void updateItemDiscount(int index, double discount) {
    if (index >= 0 && index < _cart.length) {
      _cart[index] = _cart[index].copyWith(itemDiscount: discount);
      emit(BillingUpdated(
        cart: List.from(_cart), 
        showProfitLossMode: _showProfitLossMode, 
        isEditMode: _isEditMode
      ));
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _cart.length) {
      _cart.removeAt(index);
      emit(BillingUpdated(
        cart: List.from(_cart), 
        showProfitLossMode: _showProfitLossMode, 
        isEditMode: _isEditMode
      ));
    }
  }

  void clearCart() {
    _cart.clear();
    _currentBillId = null; // Reset bill ID when clearing cart
    _isEditMode = false; // Reset edit mode when clearing cart
    emit(BillingUpdated(
      cart: List.from(_cart), 
      showProfitLossMode: _showProfitLossMode, 
      isEditMode: _isEditMode
    ));
  }

  Future<void> saveBill() async {
    final currentState = state;
    if (currentState is! BillingUpdated) return;

    final discount = currentState.discount;
    final total = calculateTotal();
    final taxAmount = calculateTaxAmount();
    final finalTotal = total + taxAmount - discount;

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
      // Update existing bill and replace all existing bill items
      billId = _currentBillId!;
      await _billRepository.updateBill(bill);
      await _billRepository.deleteBillItems(billId);
    } else {
      // Insert new bill
      billId = await _billRepository.insertBill(bill);
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
        originalPrice: item.product.originalPrice, // Save original price (MRP)
        taxRate: item.product.tax ?? 0.0,
      );
      await _billRepository.insertBillItem(billItem);
    }

    // Don't clear cart here - only clear when starting new bill
  }

  Future<void> markBillAsPaid() async {
    await saveBill();
    clearCart(); // Clear cart after payment
  }

  void setCustomerMobile(String mobile) {
    final currentState = state;
    if (currentState is BillingUpdated) {
      emit(currentState.copyWith(customerMobile: mobile));
    }
  }

  void setCustomerName(String name) {
    final currentState = state;
    if (currentState is BillingUpdated) {
      emit(currentState.copyWith(customerName: name));
    }
  }

  void setDiscount(double discount) {
    final currentState = state;
    if (currentState is BillingUpdated) {
      emit(currentState.copyWith(discount: discount));
    }
  }

  BillSummaryData getSummaryData() {
    final currentState = state;
    if (currentState is! BillingUpdated) {
      return BillSummaryData(
        cart: [],
        subtotal: 0,
        taxAmount: 0,
        discount: 0,
        finalTotal: 0,
        totalPurchase: 0,
        expectedProfit: 0,
        actualProfit: 0,
        youSave: 0,
        showProfitLossMode: _showProfitLossMode,
        isEditMode: _isEditMode,
      );
    }

    final subtotal = calculateTotal();
    final taxAmount = calculateTaxAmount();
    final finalTotal = calculateFinalTotal();
    final youSave = calculateYouSave();

    final totalPurchase = _showProfitLossMode
        ? _cart.fold<double>(
            0.0,
            (sum, item) => sum + (item.product.purchasePrice * item.quantity),
          )
        : 0.0;

    final expectedProfit = subtotal - totalPurchase;
    final actualProfit = (subtotal - currentState.discount) - totalPurchase;

    return currentState.getSummary(
      subtotal,
      taxAmount,
      finalTotal,
      youSave,
      totalPurchase,
      expectedProfit,
      actualProfit,
    );
  }

  void setTaxRate(double taxRate) {
    // No longer needed - using per-product taxes
  }

  double getTaxRate() => 0.0; // Return 0 for backward compatibility

  Future<void> printBill() async {
    final currentState = state as BillingUpdated;
    await saveBill();

    final storeName = await _settingsService.getStoreName() ?? 'Store';
    final reportData = _prepareReportData();

    await _printManager.printBill(
      storeName: storeName,
      customerName: currentState.customerName ?? 'N/A',
      customerMobile: currentState.customerMobile ?? 'N/A',
      date: DateTime.now().toString().split(' ')[0],
      items: reportData['items'] as List<Map<String, dynamic>>,
      summary: reportData['summary'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _prepareReportData() {
    final currentState = state as BillingUpdated;
    final summary = getSummaryData();

    final items = _cart.map((item) {
      final sellingPrice = item.product.sellingPrice;
      final discount = item.itemDiscount;
      final effectivePrice = sellingPrice - discount;
      final itemTotalBeforeTax = effectivePrice * item.quantity;
      final taxRate = item.product.tax ?? 0.0;
      final taxAmount = itemTotalBeforeTax * (taxRate / 100);
      final itemTotalAfterTax = itemTotalBeforeTax + taxAmount;

      return {
        'name': item.product.name,
        'quantity': item.quantity,
        'mrp': item.product.originalPrice ?? sellingPrice,
        'price': sellingPrice,
        'discount': discount,
        'amtExclTax': itemTotalBeforeTax, // Price after discount, before tax
        'taxRate': taxRate,
        'taxAmount': taxAmount,
        'total': itemTotalAfterTax, // Item total including tax
      };
    }).toList();

    return {
      'items': items,
      'summary': {
        'subtotal': summary.subtotal,
        'totalItemDiscounts': _cart.fold<double>(0.0, (sum, item) => sum + (item.itemDiscount * item.quantity)),
        'taxAmount': summary.taxAmount,
        'discount': summary.discount,
        'finalTotal': summary.finalTotal,
        'youSave': summary.youSave,
      }
    };
  }

  Future<void> shareViaEmail(String email) async {
    final currentState = state as BillingUpdated;
    await saveBill();

    final storeName = await _settingsService.getStoreName() ?? 'Store';
    final reportData = _prepareReportData();

    final pdfBytes = await _pdfGeneratorService.generateBillPdf(
      storeName: storeName,
      customerName: currentState.customerName ?? 'N/A',
      customerMobile: currentState.customerMobile ?? 'N/A',
      date: DateTime.now().toString().split(' ')[0],
      items: reportData['items'] as List<Map<String, dynamic>>,
      summary: reportData['summary'] as Map<String, dynamic>,
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(pdfBytes);

    // Share via Email - opens share dialog with email apps
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '$storeName bill for $email',
      subject: '$storeName Bill',
    );
  }

  Future<void> shareViaWhatsApp(String mobile) async {
    final currentState = state as BillingUpdated;
    await saveBill();

    final storeName = await _settingsService.getStoreName() ?? 'Store';
    final reportData = _prepareReportData();

    final pdfBytes = await _pdfGeneratorService.generateBillPdf(
      storeName: storeName,
      customerName: currentState.customerName ?? 'N/A',
      customerMobile: currentState.customerMobile ?? 'N/A',
      date: DateTime.now().toString().split(' ')[0],
      items: reportData['items'] as List<Map<String, dynamic>>,
      summary: reportData['summary'] as Map<String, dynamic>,
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill.pdf');
    await file.writeAsBytes(pdfBytes);

    // Share to WhatsApp
    final whatsappUrl = 'whatsapp://send?phone=$mobile&text=Here is your bill';
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
      // Note: Sharing file via WhatsApp URL is limited; user can attach manually or use share_plus with WhatsApp
    } else {
      // Fallback to general share
      await Share.shareXFiles([XFile(file.path)], text: '$storeName bill for $mobile');
    }
  }

  Future<void> loadBillForView(int billId) async {
    final items = await _billRepository.getBillItems(billId);
    final bill = await _billRepository.getBillById(billId);
    
    if (bill == null) {
      emit(BillingError('Bill not found'));
      return;
    }
    
    // Clear cart
    _cart.clear();
    _currentBillId = billId; // Set current bill ID for updates
    _isEditMode = true; // Enable edit mode
    // Add items - create ScannedData from bill item data
    for (final item in items) {
      // Use item name directly from bill item (no dependency on products table)
      String productName = item.itemName;
      String? brand = null; // Brand not stored in bill items
      double taxRate = item.taxRate ?? 0.0;
      
      // Create a Product from bill item data
      final product = Product(
        id: item.productId,
        name: productName,
        brand: brand,
        sellingPrice: item.sellingPrice,
        purchasePrice: item.purchasePrice,
        originalPrice: item.originalPrice, // Restore original price (MRP)
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
    emit(BillingUpdated(
      cart: List.from(_cart), 
      discount: bill.discount ?? 0.0, 
      customerName: bill.customerName, 
      customerMobile: bill.customerMobile, 
      showProfitLossMode: _showProfitLossMode, 
      isEditMode: _isEditMode
    ));
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

  double calculateYouSave() {
    final originalTotal = _cart.fold(0.0, (sum, item) => sum + ((item.product.originalPrice ?? item.product.sellingPrice) * item.quantity));
    final subtotal = calculateTotal();
    final taxAmount = calculateTaxAmount();
    
    // Estimate tax on MRP using the average tax rate of current items
    final taxRate = subtotal > 0 ? (taxAmount / subtotal) : 0.0;
    final originalTotalWithTax = originalTotal + (originalTotal * taxRate);
    
    final finalTotal = calculateFinalTotal();
    return originalTotalWithTax - finalTotal;
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

    emit(BillingUpdated(
      cart: List.from(_cart), 
      showProfitLossMode: _showProfitLossMode, 
      isEditMode: _isEditMode
    ));
  }

  Future<void> shareBillPdf() async {
    final currentState = state as BillingUpdated;

    // Save bill before sharing (will update if already exists)
    await saveBill();

    // Get store name
    final storeName = await _settingsService.getStoreName() ?? 'Store';

    // Generate PDF using centralized service
    final items = _cart.map((item) => {
      'name': item.data.data['name'] ?? 'Unknown',
      'quantity': item.quantity,
      'price': double.tryParse(item.data.data['selling_price']?.toString() ?? '0') ?? 0.0,
      'total': (double.tryParse(item.data.data['selling_price']?.toString() ?? '0') ?? 0.0) * item.quantity,
      'discount': 0.0,
    }).toList();

    final summary = {
      'subtotal': calculateTotal(),
      'totalItemDiscounts': 0.0,
      'taxAmount': calculateTaxAmount(),
      'discount': currentState.discount,
      'finalTotal': calculateFinalTotal(),
      'youSave': calculateYouSave(),
    };

    final pdfBytes = await _pdfGeneratorService.generateBillPdf(
      storeName: storeName,
      customerName: currentState.customerName ?? 'N/A',
      customerMobile: currentState.customerMobile ?? 'N/A',
      date: DateTime.now().toString().split(' ')[0],
      items: items,
      summary: summary,
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(pdfBytes);

    // Share the PDF file
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Bill Receipt - ${currentState.customerName ?? 'Customer'}',
      subject: 'Bill Receipt',
    );
  }
}