class Bill {
  final int? id;
  final String date;
  final double totalAmount;
  final double? discount;
  final double finalTotal;
  final double? purchaseAmount; // Total purchase cost for profit calculation
  final String? customerName;
  final String? customerMobile;

  Bill({
    this.id,
    required this.date,
    required this.totalAmount,
    this.discount,
    required this.finalTotal,
    this.purchaseAmount,
    this.customerName,
    this.customerMobile,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total_amount': totalAmount,
      'discount': discount,
      'final_total': finalTotal,
      'purchase_amount': purchaseAmount,
      'customer_name': customerName,
      'customer_mobile': customerMobile,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'],
      date: map['date'],
      totalAmount: map['total_amount'],
      discount: map['discount'],
      finalTotal: map['final_total'],
      purchaseAmount: map['purchase_amount'],
      customerName: map['customer_name'],
      customerMobile: map['customer_mobile'],
    );
  }
}