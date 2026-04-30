import 'package:flutter_test/flutter_test.dart';
import 'package:qr_based_billing/core/services/encryption_service.dart';

void main() {
  late EncryptionServiceImpl encryptionService;

  setUp(() {
    encryptionService = EncryptionServiceImpl();
  });

  group('EncryptionServiceImpl', () {
    test('encryptData should return a different string for valid input', () {
      const data = 'Hello123';
      final encrypted = encryptionService.encryptData(data);
      expect(encrypted, isNot(equals(data)));
    });

    test('decryptData should return original string after encryption', () {
      const originalData = 'Sugar 1kg ₹45';
      final encrypted = encryptionService.encryptData(originalData);
      final decrypted = encryptionService.decryptData(encrypted);
      expect(decrypted, equals(originalData));
    });

    test('encryption should handle special characters correctly', () {
      const data = r'!@#$%^&*()_+ ';
      final encrypted = encryptionService.encryptData(data);
      final decrypted = encryptionService.decryptData(encrypted);
      expect(decrypted, equals(data));
    });

    test('encryption should maintain string length (critical for QR capacity)', () {
      const data = 'Product:Milk,Price:60,Qty:2';
      final encrypted = encryptionService.encryptData(data);
      expect(encrypted.length, equals(data.length));
    });

    test('encryption should handle non-ASCII characters by returning them as is', () {
      const data = 'Hindi: नमस्ते';
      final encrypted = encryptionService.encryptData(data);
      final decrypted = encryptionService.decryptData(encrypted);
      expect(decrypted, equals(data));
    });
  });
}
