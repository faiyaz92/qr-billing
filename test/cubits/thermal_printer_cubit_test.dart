import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/thermal_printer_cubit.dart';
import 'package:qr_based_billing/core/services/i_thermal_printer_service.dart';

class MockThermalPrinterService extends Mock implements IThermalPrinterService {}

void main() {
  late ThermalPrinterCubit cubit;
  late MockThermalPrinterService mockService;

  setUp(() {
    mockService = MockThermalPrinterService();
    when(() => mockService.isConnected).thenReturn(false);
    cubit = ThermalPrinterCubit(mockService);
  });

  tearDown(() {
    cubit.close();
  });

  group('ThermalPrinterCubit', () {
    blocTest<ThermalPrinterCubit, ThermalPrinterState>(
      'scanPrinters success updates discoveredPrinters list',
      build: () {
        when(() => mockService.discoverPrinters()).thenAnswer((_) async => ['Printer 1', 'Printer 2']);
        return cubit;
      },
      act: (cubit) => cubit.scanPrinters(),
      expect: () => [
        isA<ThermalPrinterLoaded>().having((s) => s.isScanning, 'scanning start', true),
        isA<ThermalPrinterLoaded>().having((s) => s.discoveredPrinters.length, 'printers count', 2).having((s) => s.isScanning, 'scanning end', false),
      ],
    );

    blocTest<ThermalPrinterCubit, ThermalPrinterState>(
      'connect to printer success updates isConnected',
      build: () {
        when(() => mockService.connectToPrinter(any())).thenAnswer((_) async => true);
        return cubit;
      },
      seed: () => ThermalPrinterLoaded(isConnected: false, discoveredPrinters: ['Addr1'], selectedPrinterAddress: 'Addr1'),
      act: (cubit) => cubit.connect(),
      expect: () => [
        isA<ThermalPrinterLoaded>().having((s) => s.isScanning, 'connecting loading', true),
        isA<ThermalPrinterLoaded>().having((s) => s.isConnected, 'connected', true).having((s) => s.isScanning, 'connecting end', false),
      ],
    );

    blocTest<ThermalPrinterCubit, ThermalPrinterState>(
      'testPrint calls service printReceipt',
      build: () {
        when(() => mockService.printReceipt(any())).thenAnswer((_) async {});
        return cubit;
      },
      seed: () => ThermalPrinterLoaded(isConnected: true, discoveredPrinters: []),
      act: (cubit) => cubit.testPrint(),
      verify: (_) {
        verify(() => mockService.printReceipt(any())).called(1);
      },
    );
  });
}
