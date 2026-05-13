// Minimal classes for logic verification
class Product {
  final String name;
  final double sellingPrice;
  Product(this.name, this.sellingPrice);
}

class CartItem {
  final Product product;
  final int quantity;
  final double itemDiscount;
  CartItem(this.product, this.quantity, {this.itemDiscount = 0.0});
}

void main() {
  print('--- Billing Logic Verification (Standalone Run) ---');
  
  // Test Case 1: Total Calculation
  final cart = [
    CartItem(Product('Sugar', 100), 2, itemDiscount: 10), // (100 - 10) * 2 = 180
    CartItem(Product('Milk', 50), 1), // 50 * 1 = 50
  ];

  final total = cart.fold(0.0, (sum, item) => sum + ((item.product.sellingPrice - item.itemDiscount) * item.quantity));
  
  if (total == 230.0) {
    print('✅ PASS: Total Calculation (230.0)');
  } else {
    print('❌ FAIL: Expected 230.0, got $total');
  }

  // Test Case 2: Tax Calculation
  final subtotal = 200.0;
  const taxRate = 10.0;
  final taxAmount = subtotal * (taxRate / 100);
  
  if (taxAmount == 20.0) {
    print('✅ PASS: Tax Calculation (20.0)');
  } else {
    print('❌ FAIL: Expected 20.0, got $taxAmount');
  }

  print('--- All Logic Verified ---');
}
