import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/quick_scan_cubit.dart';
import 'package:qr_based_billing/core/services/i_scan_service.dart';
import 'package:qr_based_billing/data/models/scanned_data.dart';
import 'package:qr_based_billing/data/models/qr_data.dart';

class MockScanService extends Mock implements IScanService {}

void main() {
  late QuickScanCubit cubit;
  late MockScanService mockScan;

  setUp(() {
    mockScan = MockScanService();
    cubit = QuickScanCubit(mockScan);
  });

  tearDown(() {
    cubit.close();
  });

  group('QuickScanCubit', () {
    blocTest<QuickScanCubit, QuickScanState>(
      'quickScanProduct success emits Loading and Success',
      build: () {
        when(() => mockScan.scanAndDecode(any())).thenAnswer((_) async => ScannedData(
          data: {},
          qrCode: 'qr',
          signature: QrSignature(appSignature: 'APP', storeSignature: 'STORE', type: 1),
        ));
        return cubit;
      },
      act: (cubit) => cubit.quickScanProduct('valid_qr'),
      expect: () => [
        isA<QuickScanLoading>(),
        isA<QuickScanSuccess>(),
      ],
    );

    blocTest<QuickScanCubit, QuickScanState>(
      'quickScanProduct wrong type emits Error',
      build: () {
        when(() => mockScan.scanAndDecode(any())).thenAnswer((_) async => ScannedData(
          data: {},
          qrCode: 'qr',
          signature: QrSignature(appSignature: 'APP', storeSignature: 'STORE', type: 2),
        ));
        return cubit;
      },
      act: (cubit) => cubit.quickScanProduct('wrong_type_qr'),
      expect: () => [
        isA<QuickScanLoading>(),
        isA<QuickScanError>().having((e) => e.message, 'message', contains('Type: 2')),
      ],
    );
  });
}
