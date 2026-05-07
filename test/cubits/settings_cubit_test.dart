import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/settings_cubit.dart';
import 'package:qr_based_billing/presentation/cubits/settings_state.dart';
import 'package:qr_based_billing/core/services/i_settings_service.dart';

class MockSettingsService extends Mock implements ISettingsService {}

void main() {
  late SettingsCubit cubit;
  late MockSettingsService mockService;

  setUp(() {
    mockService = MockSettingsService();
    cubit = SettingsCubit(mockService);
  });

  tearDown(() {
    cubit.close();
  });

  group('SettingsCubit', () {
    blocTest<SettingsCubit, SettingsState>(
      'loadSettings emits Loading and then Loaded with settings',
      build: () {
        when(() => mockService.getPin()).thenAnswer((_) async => '1234');
        when(() => mockService.getStoreSecret()).thenAnswer((_) async => 'secret');
        when(() => mockService.getStoreName()).thenAnswer((_) async => 'My Store');
        when(() => mockService.getPrinterPreference()).thenAnswer((_) async => 'Thermal');
        return cubit;
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        isA<SettingsLoading>(),
        isA<SettingsLoaded>()
            .having((s) => s.pin, 'pin', '1234')
            .having((s) => s.storeName, 'storeName', 'My Store'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveSettings updates settings and emits Loaded',
      build: () {
        when(() => mockService.savePin(any())).thenAnswer((_) async {});
        when(() => mockService.saveStoreSecret(any())).thenAnswer((_) async {});
        when(() => mockService.saveStoreName(any())).thenAnswer((_) async {});
        when(() => mockService.savePrinterPreference(any())).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.saveSettings(pin: '4321', storeSecret: 'new_secret', storeName: 'New Store'),
      expect: () => [
        isA<SettingsLoading>(),
        isA<SettingsLoaded>().having((s) => s.pin, 'pin', '4321'),
      ],
      verify: (_) {
        verify(() => mockService.savePin('4321')).called(1);
      },
    );
  });
}
