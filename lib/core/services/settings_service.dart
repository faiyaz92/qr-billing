import 'package:shared_preferences/shared_preferences.dart';
import 'i_settings_service.dart';

class SettingsServiceImpl implements ISettingsService {
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin', pin);
  }

  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pin');
  }

  Future<void> saveStoreSecret(String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_secret', secret);
  }

  Future<String?> getStoreSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('store_secret');
  }

  Future<void> saveStoreName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_name', name);
  }

  Future<String?> getStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('store_name');
  }

  Future<void> savePrinterPreference(String preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_preference', preference);
  }

  Future<String> getPrinterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('printer_preference') ?? 'bluetooth'; // Default to bluetooth
  }
}