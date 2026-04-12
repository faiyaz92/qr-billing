class Product {
  final int? id;
  final String? name;
  final String? brand;
  final String? dateOfPurchase;
  final double purchasePrice;
  final double sellingPrice;
  final double? originalPrice;
  final double? tax;
  final String? qrData;

  Product({
    this.id,
    this.name,
    this.brand,
    this.dateOfPurchase,
    required this.purchasePrice,
    required this.sellingPrice,
    this.originalPrice,
    this.tax,
    this.qrData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'date_of_purchase': dateOfPurchase,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'original_price': originalPrice,
      'tax': tax,
      'qr_data': qrData,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
      dateOfPurchase: map['date_of_purchase'],
      purchasePrice: map['purchase_price'] ?? 0.0,
      sellingPrice: map['selling_price'] ?? 0.0,
      originalPrice: map['original_price'],
      tax: map['tax'],
      qrData: map['qr_data'],
    );
  }
}