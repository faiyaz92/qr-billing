import 'dart:convert';
import '../../data/models/scanned_data.dart';
import '../../data/models/qr_data.dart';
import 'i_scan_service.dart';
import 'i_encryption_service.dart';
import 'i_settings_service.dart';

class ScanServiceImpl implements IScanService {
  final IEncryptionService _encryption;
  final ISettingsService _settings;

  ScanServiceImpl(this._encryption, this._settings);

  @override
  Future<ScannedData?> scanAndDecode(String qrCode) async {
    try {
      final qrData = QrData.fromJson(jsonDecode(qrCode));
      final decryptedSignatureJson = _encryption.decryptData(qrData.encryptedSignature);
      final qrSignature = QrSignature.fromJson(jsonDecode(decryptedSignatureJson));

      // Validate signatures
      final currentSecret = await _settings.getStoreSecret();
      if (qrSignature.appSignature != 'QR_BILLING_APP' || qrSignature.storeSignature != currentSecret) {
        return null; // Invalid signature
      }

      // Map compact field names back to full field names for backward compatibility
      final mappedData = _mapCompactFields(qrData.data);

      // Return raw data with decrypted signature
      return ScannedData(signature: qrSignature, data: mappedData, qrCode: qrCode);
    } catch (e) {
      return null; // Invalid QR or decryption failed
    }
  }

  // Map compact field names to full field names
  Map<String, dynamic> _mapCompactFields(Map<String, dynamic> compactData) {
    return {
      'name': compactData['n'] ?? compactData['name'], // Support both compact and full names
      'brand': compactData['b'] ?? compactData['brand'],
      'tax': compactData['t'] ?? compactData['tax'],
      'selling_price': compactData['sp'] ?? compactData['selling_price'],
      'original_price': compactData['op'] ?? compactData['original_price'],
      'encrypted_sensitive': compactData['esd'] ?? compactData['encrypted_sensitive'],
    };
  }
}