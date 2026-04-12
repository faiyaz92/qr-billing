import 'qr_data.dart';

class ScannedData {
  final QrSignature? signature;
  final Map<String, dynamic> data;
  final String qrCode;

  ScannedData({this.signature, required this.data, required this.qrCode});
}