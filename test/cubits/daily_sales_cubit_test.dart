import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/daily_sales_cubit.dart';
import 'package:qr_based_billing/presentation/cubits/daily_sales_state.dart';
import 'package:qr_based_billing/domain/repositories/i_bill_repository.dart';
import 'package:qr_based_billing/core/services/i_settings_service.dart';
import 'package:qr_based_billing/core/services/pdf_generator_service.dart';
import 'package:qr_based_billing/data/models/bill.dart';
import 'package:qr_based_billing/data/models/bill_item.dart';

class MockBillRepository extends Mock implements IBillRepository {}
class MockSettingsService extends Mock implements ISettingsService {}
class MockPdfGeneratorService extends Mock implements PdfGeneratorService {}

void main() {
  late DailySalesCubit cubit;
  late MockBillRepository mockRepo;
  late MockSettingsService mockSettings;
  late MockPdfGeneratorService mockPdf;

  final testBills = [
    Bill(id: 1, date: DateTime.now().toIso8601String().split('T')[0], totalAmount: 100, finalTotal: 110, purchaseAmount: 80),
  ];

  setUp(() {
    mockRepo = MockBillRepository();
    mockSettings = MockSettingsService();
    mockPdf = MockPdfGeneratorService();
    
    when(() => mockRepo.getAllBills()).thenAnswer((_) async => testBills);
    when(() => mockRepo.getBillItems(any())).thenAnswer((_) async => [
      BillItem(billId: 1, productId: 1, itemName: 'Test', quantity: 1, sellingPrice: 100, purchasePrice: 80, taxRate: 10),
    ]);

    cubit = DailySalesCubit(mockRepo, mockSettings, mockPdf);
  });

  tearDown(() {
    cubit.close();
  });

  group('DailySalesCubit', () {
    test('initial load triggers loadSales', () async {
      // Setup happens in setUp
      verify(() => mockRepo.getAllBills()).called(1);
    });

    blocTest<DailySalesCubit, DailySalesState>(
      'changeMonth loads sales for new month',
      build: () => cubit,
      act: (cubit) => cubit.changeMonth(1),
      expect: () => [
        isA<DailySalesLoading>(),
        isA<DailySalesLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepo.getAllBills()).called(greaterThan(0));
      },
    );

    blocTest<DailySalesCubit, DailySalesState>(
      'changeYear loads sales for new year',
      build: () => cubit,
      act: (cubit) => cubit.changeYear(2023),
      expect: () => [
        isA<DailySalesLoading>(),
        isA<DailySalesLoaded>(),
      ],
    );

    blocTest<DailySalesCubit, DailySalesState>(
      'setSearchQuery filters bills',
      build: () => cubit,
      act: (cubit) => cubit.setSearchQuery('999'), // No match
      expect: () => [
        isA<DailySalesLoading>(),
        isA<DailySalesLoaded>().having((s) => s.dailySales.isEmpty, 'empty results', true),
      ],
    );
  });
}
