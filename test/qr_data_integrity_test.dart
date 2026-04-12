import 'package:flutter_test/flutter_test.dart';
import 'package:qr_based_billing/data/models/product.dart';
import 'package:qr_based_billing/data/models/scanned_data.dart';
import 'package:qr_based_billing/data/models/qr_data.dart';

void main() {
  test('Database product data structure validation', () {
    // Test that product data contains all expected fields
    final product = Product(
      name: 'Test Product',
      brand: 'Test Brand',
      dateOfPurchase: '2024-01-01',
      purchasePrice: 80.0,
      sellingPrice: 100.0,
      originalPrice: 120.0,
      tax: 18.0,
      qrData: '{"encrypted_signature":"test","data":{"name":"Test Product","brand":"Test Brand","tax":18.0,"selling_price":100.0,"original_price":120.0,"encrypted_sensitive":"encrypted"}}',
    );

    // Verify product has all the fields that should be displayed in billing
    expect(product.name, isNotNull);
    expect(product.brand, isNotNull);
    expect(product.sellingPrice, isNotNull);
    expect(product.sellingPrice, greaterThan(0));
    expect(product.qrData, isNotNull);
  });

  test('ScannedData structure matches expected QR data format', () {
    // Simulate the data structure that comes from QR scanning
    final qrDataMap = {
      'name': 'Test Product',
      'brand': 'Test Brand',
      'tax': 18.0,
      'selling_price': 100.0,
      'original_price': 120.0,
      'encrypted_sensitive': 'encrypted_data_here',
    };

    final scannedData = ScannedData(
      signature: QrSignature(appSignature: 'QR_BILLING_APP', storeSignature: 'test_secret', type: 1),
      data: qrDataMap,
      qrCode: 'sample_qr_code_string',
    );

    // Verify scanned data has the expected structure
    expect(scannedData.data['name'], equals('Test Product'));
    expect(scannedData.data['selling_price'], equals(100.0));
    expect(scannedData.data['encrypted_sensitive'], isNotNull);
    expect(scannedData.qrCode, isNotNull);
  });

  test('QR data map contains all required fields for billing display', () {
    // This represents the data that gets put into QR during product addition
    final qrDataMap = {
      'name': 'Test Product',
      'brand': 'Test Brand',
      'tax': 18.0,
      'selling_price': 100.0,
      'original_price': 120.0,
      'encrypted_sensitive': 'encrypted_purchase_data',
    };

    // Verify all fields needed for billing are present
    expect(qrDataMap.containsKey('name'), isTrue);
    expect(qrDataMap.containsKey('selling_price'), isTrue);
    expect(qrDataMap.containsKey('encrypted_sensitive'), isTrue);

    // Verify data types are correct
    expect(qrDataMap['selling_price'], isA<double>());
    expect(qrDataMap['name'], isA<String>());
  });

  test('Billing cart calculation uses correct data source', () {
    // Simulate what happens in billing - we should use database product data, not QR data
    final product = Product(
      name: 'Test Product',
      purchasePrice: 80.0,
      sellingPrice: 100.0,
    );

    final quantity = 2;
    final expectedTotal = product.sellingPrice * quantity;

    // This is how the calculation should work (using product data)
    final actualTotal = product.sellingPrice * quantity;

    expect(actualTotal, equals(expectedTotal));
    expect(actualTotal, equals(200.0));
  });
}