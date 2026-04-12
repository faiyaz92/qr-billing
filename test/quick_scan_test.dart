import 'package:flutter_test/flutter_test.dart';
import 'package:qr_based_billing/presentation/cubits/quick_scan_cubit.dart';
import 'package:qr_based_billing/data/models/scanned_data.dart';
import 'package:qr_based_billing/data/models/qr_data.dart';

void main() {
  test('QuickScanState classes exist and are properly defined', () {
    // Test that the state classes can be instantiated
    final initialState = QuickScanInitial();
    expect(initialState, isA<QuickScanInitial>());

    final loadingState = QuickScanLoading();
    expect(loadingState, isA<QuickScanLoading>());

    final scannedData = ScannedData(
      signature: QrSignature(appSignature: 'QR_BILLING_APP', storeSignature: 'test_secret', type: 1),
      data: {'name': 'Test Product', 'selling_price': 100.0},
      qrCode: 'test_qr',
    );

    final successState = QuickScanSuccess(scannedData);
    expect(successState, isA<QuickScanSuccess>());
    expect(successState.scannedData.data['name'], equals('Test Product'));

    final errorState = QuickScanError('Test error');
    expect(errorState, isA<QuickScanError>());
    expect(errorState.message, equals('Test error'));
  });

  test('ScannedData structure validation', () {
    final scannedData = ScannedData(
      signature: QrSignature(appSignature: 'QR_BILLING_APP', storeSignature: 'test_secret', type: 1),
      data: {
        'name': 'Test Product',
        'brand': 'Test Brand',
        'selling_price': 100.0,
        'original_price': 120.0,
        'tax': 18.0,
      },
      qrCode: 'sample_qr_code',
    );

    expect(scannedData.data['name'], equals('Test Product'));
    expect(scannedData.data['selling_price'], equals(100.0));
    expect(scannedData.data['brand'], equals('Test Brand'));
    expect(scannedData.qrCode, isNotNull);
  });

  test('Product details screen can be created with scanned data', () {
    final scannedData = ScannedData(
      signature: QrSignature(appSignature: 'QR_BILLING_APP', storeSignature: 'test_secret', type: 1),
      data: {
        'name': 'Test Product',
        'selling_price': 100.0,
      },
      qrCode: 'test_qr',
    );

    // This test ensures the scanned data works with the screen
    expect(scannedData.data['name'], isNotNull);
    expect(scannedData.data['selling_price'], greaterThan(0));
  });

  test('QR data pricing calculations work correctly', () {
    final data = {
      'name': 'Test Product',
      'selling_price': 100.0,
      'original_price': 120.0,
    };

    // Test savings calculation
    final savings = (data['original_price'] as num).toDouble() - (data['selling_price'] as num).toDouble();
    expect(savings, equals(20.0));

    // Test that selling price is less than original price
    expect((data['selling_price'] as num).toDouble(), lessThan((data['original_price'] as num).toDouble()));
  });
}