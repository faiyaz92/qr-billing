import 'package:qr_based_billing/core/services/encryption_service.dart';

void main() {
  print('--- EncryptionService Standalone Tests ---');
  final encryptionService = EncryptionServiceImpl();
  int passed = 0;
  int failed = 0;

  void expect(dynamic actual, dynamic expected, String message) {
    if (actual == expected) {
      print('✅ PASS: $message');
      passed++;
    } else {
      print('❌ FAIL: $message');
      print('   Expected: $expected');
      print('   Actual:   $actual');
      failed++;
    }
  }

  // Test 1: Basic Encryption
  const data1 = 'Hello123';
  final encrypted1 = encryptionService.encryptData(data1);
  expect(encrypted1 != data1, true, 'Encryption should change the string');

  // Test 2: Decryption Integrity
  const data2 = 'Sugar 1kg ₹45';
  final encrypted2 = encryptionService.encryptData(data2);
  final decrypted2 = encryptionService.decryptData(encrypted2);
  expect(decrypted2, data2, 'Decryption should return original string');

  // Test 3: Special Characters
  const data3 = r'!@#$%^&*()_+ ';
  final encrypted3 = encryptionService.encryptData(data3);
  final decrypted3 = encryptionService.decryptData(encrypted3);
  expect(decrypted3, data3, 'Should handle special characters correctly');

  // Test 4: Length Maintenance
  const data4 = 'Product:Milk,Price:60,Qty:2';
  final encrypted4 = encryptionService.encryptData(data4);
  expect(encrypted4.length, data4.length, 'Should maintain string length for QR capacity');

  // Test 5: Non-ASCII characters
  const data5 = 'Hindi: नमस्ते';
  final encrypted5 = encryptionService.encryptData(data5);
  final decrypted5 = encryptionService.decryptData(encrypted5);
  expect(decrypted5, data5, 'Should handle non-ASCII characters by returning as is');

  print('\n--- Results ---');
  print('Total: ${passed + failed}');
  print('Passed: $passed');
  print('Failed: $failed');

  if (failed > 0) {
    print('\n⚠️ Some tests failed!');
  } else {
    print('\n🎉 All tests passed successfully!');
  }
}
