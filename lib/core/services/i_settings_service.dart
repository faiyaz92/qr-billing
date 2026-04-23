abstract class ISettingsService {
  Future<void> savePin(String pin);
  Future<String?> getPin();
  Future<void> saveStoreSecret(String secret);
  Future<String?> getStoreSecret();
  Future<void> saveStoreName(String name);
  Future<String?> getStoreName();
  Future<void> savePrinterPreference(String preference); // 'bluetooth' or 'system'
  Future<String> getPrinterPreference(); // returns 'bluetooth' or 'system', defaults to 'bluetooth'
}