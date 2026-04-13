abstract class ISettingsService {
  Future<void> savePin(String pin);
  Future<String?> getPin();
  Future<void> saveStoreSecret(String secret);
  Future<String?> getStoreSecret();
  Future<void> saveStoreName(String name);
  Future<String?> getStoreName();
}