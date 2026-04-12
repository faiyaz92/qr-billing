abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String? pin;
  final String? storeSecret;

  SettingsLoaded({this.pin, this.storeSecret});
}

class SettingsSaved extends SettingsState {}

class SettingsError extends SettingsState {
  final String message;

  SettingsError(this.message);
}