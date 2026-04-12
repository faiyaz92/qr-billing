import 'dart:convert';
import 'i_encryption_service.dart';

class EncryptionServiceImpl implements IEncryptionService {
  // Simple shift cipher for minimal size increase (same length)
  static const int _shift = 13; // Caesar cipher shift

  @override
  String encryptData(String data) {
    // Use simple shift for same length (less secure but no size increase)
    return _shiftEncrypt(data);
  }

  @override
  String decryptData(String encryptedData) {
    // Decrypt shift
    return _shiftDecrypt(encryptedData);
  }

  String _shiftEncrypt(String text) {
    return text.runes.map((rune) {
      if (rune >= 32 && rune <= 126) { // Printable ASCII
        return String.fromCharCode((rune - 32 + _shift) % 95 + 32);
      }
      return String.fromCharCode(rune);
    }).join();
  }

  String _shiftDecrypt(String text) {
    return text.runes.map((rune) {
      if (rune >= 32 && rune <= 126) {
        return String.fromCharCode((rune - 32 - _shift + 95) % 95 + 32);
      }
      return String.fromCharCode(rune);
    }).join();
  }
}