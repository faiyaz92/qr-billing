import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

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
  group('Billing Logic Verification (Pure Dart)', () {
    test('Total Calculation Logic', () {
      final cart = [
        CartItem(Product('Sugar', 100), 2, itemDiscount: 10), // (100 - 10) * 2 = 180
        CartItem(Product('Milk', 50), 1), // 50 * 1 = 50
      ];

      final total = cart.fold(0.0, (sum, item) => sum + ((item.product.sellingPrice - item.itemDiscount) * item.quantity));
      
      expect(total, 230.0);
    });

    test('Tax Calculation Logic', () {
      final cart = [
        CartItem(Product('Sugar', 100), 1),
      ];
      const taxRate = 10.0;
      
      final subtotal = cart.fold(0.0, (sum, item) => sum + (item.product.sellingPrice * item.quantity));
      final taxAmount = subtotal * (taxRate / 100);
      
      expect(taxAmount, 10.0);
    });
  });
}
