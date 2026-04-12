abstract class IQrGeneratorService {
  Future<String> generateQrData(int type, Map<String, dynamic> data);
}