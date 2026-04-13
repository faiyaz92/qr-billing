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
      emit(SettingsLoaded(pin: pin, storeSecret: storeSecret, storeName: storeName));
    } catch (e) {
      emit(SettingsError('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> saveSettings({required String pin, required String storeSecret, required String storeName}) async {
    emit(SettingsLoading());
    try {
      await _settingsService.savePin(pin);
      await _settingsService.saveStoreSecret(storeSecret);
      await _settingsService.saveStoreName(storeName);
      emit(SettingsSaved());
      // Reload settings to confirm they were saved
      await loadSettings();
    } catch (e) {
      emit(SettingsError('Failed to save settings: ${e.toString()}'));
    }
  }
}