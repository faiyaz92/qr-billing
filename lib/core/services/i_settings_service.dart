abstract class ISettingsService {
  Future<void> savePin(String pin);
  Future<String?> getPin();
  Future<void> saveStoreSecret(String secret);
  Future<String?> getStoreSecret();
}