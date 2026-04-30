import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/i_settings_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final ISettingsService _settingsService;

  SettingsCubit(this._settingsService) : super(SettingsInitial());

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    try {
      final pin = await _settingsService.getPin();
      final storeSecret = await _settingsService.getStoreSecret();
      final storeName = await _settingsService.getStoreName();
      final printerPreference = await _settingsService.getPrinterPreference();
      emit(SettingsLoaded(pin: pin, storeSecret: storeSecret, storeName: storeName, printerPreference: printerPreference));
    } catch (e) {
      emit(SettingsError('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> saveSettings({
    required String pin,
    required String storeSecret,
    required String storeName,
    String? printerPreference,
    bool silent = false,
  }) async {
    if (!silent) emit(SettingsLoading());
    try {
      await _settingsService.savePin(pin);
      await _settingsService.saveStoreSecret(storeSecret);
      await _settingsService.saveStoreName(storeName);
      if (printerPreference != null) {
        await _settingsService.savePrinterPreference(printerPreference);
      }
      if (!silent) {
        emit(SettingsSaved());
        await loadSettings();
      }
    } catch (e) {
      emit(SettingsError('Failed to save settings: ${e.toString()}'));
    }
  }
}