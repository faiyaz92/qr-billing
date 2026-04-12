import '../../data/models/scanned_data.dart';

abstract class IScanService {
  Future<ScannedData?> scanAndDecode(String qrCode);
}