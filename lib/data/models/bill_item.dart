class BillItem {
  final int? id;
  final int billId;
  final int? productId; // Made optional
  final String itemName; // Added item name
  final int quantity;
  final double? itemDiscount;
  final double purchasePrice; // Added for profit calculation
  final double sellingPrice; // Added for profit calculation
  final double? originalPrice; // Added for savings calculation
  final double? taxRate; // Added for tax calculation (percentage)

  BillItem({
    this.id,
    required this.billId,
    this.productId, // Made optional
    required this.itemName, // Required item name
    required this.quantity,
    this.itemDiscount,
    required this.purchasePrice, // Required for profit tracking
    required this.sellingPrice, // Required for profit tracking
    this.originalPrice, // Optional for savings tracking
    this.taxRate, // Optional for tax calculation
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'product_id': productId,
      'item_name': itemName,
      'quantity': quantity,
      'item_discount': itemDiscount,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'original_price': originalPrice,
      'tax': taxRate,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'],
      billId: map['bill_id'],
      productId: map['product_id'],
      itemName: map['item_name'] ?? 'Unknown Item',
      quantity: map['quantity'],
      itemDiscount: map['item_discount'],
      purchasePrice: map['purchase_price'] ?? 0.0,
      sellingPrice: map['selling_price'] ?? 0.0,
      originalPrice: map['original_price'],
      taxRate: map['tax'] ?? 0.0,
    );
  }
}