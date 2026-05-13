import 'package:equatable/equatable.dart';
import '../../data/models/product.dart';
import '../../data/models/scanned_data.dart';

class CartItem extends Equatable {
  final ScannedData data;
  final Product product;
  final int quantity;
  final double itemDiscount;

  const CartItem({
    required this.data,
    required this.product,
    this.quantity = 1,
    this.itemDiscount = 0.0,
  });

  CartItem copyWith({
    int? quantity,
    double? itemDiscount,
  }) {
    return CartItem(
      data: data,
      product: product,
      quantity: quantity ?? this.quantity,
      itemDiscount: itemDiscount ?? this.itemDiscount,
    );
  }

  @override
  List<Object?> get props => [data, product, quantity, itemDiscount];
}

class BillSummaryData extends Equatable {
  final List<CartItem> cart;
  final double subtotal;
  final double taxAmount;
  final double discount;
  final double finalTotal;
  final double totalPurchase;
  final double expectedProfit;
  final double actualProfit;
  final double youSave;
  final bool showProfitLossMode;
  final bool isEditMode;
  final String? customerName;
  final String? customerMobile;

  const BillSummaryData({
    required this.cart,
    required this.subtotal,
    required this.taxAmount,
    required this.discount,
    required this.finalTotal,
    required this.totalPurchase,
    required this.expectedProfit,
    required this.actualProfit,
    required this.youSave,
    required this.showProfitLossMode,
    required this.isEditMode,
    this.customerName,
    this.customerMobile,
  });

  @override
  List<Object?> get props => [
        cart,
        subtotal,
        taxAmount,
        discount,
        finalTotal,
        totalPurchase,
        expectedProfit,
        actualProfit,
        youSave,
        showProfitLossMode,
        isEditMode,
        customerName,
        customerMobile,
      ];
}

abstract class BillingState extends Equatable {
  const BillingState();

  @override
  List<Object?> get props => [];
}

class BillingInitial extends BillingState {}

class BillingLoading extends BillingState {}

class BillingError extends BillingState {
  final String message;
  const BillingError(this.message);

  @override
  List<Object?> get props => [message];
}

class BillingUpdated extends BillingState {
  final List<CartItem> cart;
  final bool isScanningPaused;
  final String? customerMobile;
  final String? customerName;
  final double discount;
  final double taxRate;
  final bool duplicateDetected;
  final String? duplicateProductName;
  final bool showProfitLossMode;
  final bool isEditMode;
  final String? billDate;
  final DateTime? lastUpdated; // To force rebuild when needed if props are same

  const BillingUpdated({
    required this.cart,
    this.isScanningPaused = false,
    this.customerMobile,
    this.customerName,
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.duplicateDetected = false,
    this.duplicateProductName,
    this.showProfitLossMode = false,
    this.isEditMode = false,
    this.billDate,
    this.lastUpdated,
  });

  BillingUpdated copyWith({
    List<CartItem>? cart,
    bool? isScanningPaused,
    String? customerMobile,
    String? customerName,
    double? discount,
    double? taxRate,
    bool? duplicateDetected,
    String? duplicateProductName,
    bool? showProfitLossMode,
    bool? isEditMode,
    String? billDate,
  }) {
    return BillingUpdated(
      cart: cart ?? this.cart,
      isScanningPaused: isScanningPaused ?? this.isScanningPaused,
      customerMobile: customerMobile ?? this.customerMobile,
      customerName: customerName ?? this.customerName,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      duplicateDetected: duplicateDetected ?? false, // Reset by default
      duplicateProductName: duplicateProductName ?? this.duplicateProductName,
      showProfitLossMode: showProfitLossMode ?? this.showProfitLossMode,
      isEditMode: isEditMode ?? this.isEditMode,
      billDate: billDate ?? this.billDate,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    cart, 
    isScanningPaused, 
    customerMobile, 
    customerName, 
    discount, 
    taxRate, 
    duplicateDetected, 
    duplicateProductName, 
    showProfitLossMode, 
    isEditMode,
    billDate,
    lastUpdated
  ];

  BillSummaryData getSummary(double subtotal, double taxAmount, double finalTotal, double youSave, double totalPurchase, double expectedProfit, double actualProfit) {
    return BillSummaryData(
      cart: cart,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: discount,
      finalTotal: finalTotal,
      totalPurchase: totalPurchase,
      expectedProfit: expectedProfit,
      actualProfit: actualProfit,
      youSave: youSave,
      showProfitLossMode: showProfitLossMode,
      isEditMode: isEditMode,
      customerName: customerName,
      customerMobile: customerMobile,
    );
  }
}
