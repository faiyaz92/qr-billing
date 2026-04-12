import 'dart:convert';
import 'i_qr_generator_service.dart';
import 'i_encryption_service.dart';
import 'i_settings_service.dart';
import '../../data/models/qr_data.dart';

class QrGeneratorServiceImpl implements IQrGeneratorService {
  final IEncryptionService _encryption;
  final ISettingsService _settings;
  static const String _appSignature = 'QR_BILLING_APP';

  QrGeneratorServiceImpl(this._encryption, this._settings);

  @override
  Future<String> generateQrData(int type, Map<String, dynamic> data) async {
    final storeSecret = await _settings.getStoreSecret();
    if (storeSecret == null) throw Exception('Store secret not set');

    final qrSignature = QrSignature(
      appSignature: _appSignature,
      storeSignature: storeSecret,
      type: type,
    );

    final encryptedSignature = _encryption.encryptData(jsonEncode(qrSignature.toJson()));

    final qrData = QrData(
      encryptedSignature: encryptedSignature,
      data: data,
    );

    return jsonEncode(qrData.toJson());
  }
}