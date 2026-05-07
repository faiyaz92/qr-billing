import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/analytics_cubit.dart';
import 'package:qr_based_billing/domain/repositories/i_bill_repository.dart';
import 'package:qr_based_billing/domain/repositories/i_product_repository.dart';
import 'package:qr_based_billing/data/models/bill.dart';

class MockBillRepository extends Mock implements IBillRepository {}
class MockProductRepository extends Mock implements IProductRepository {}

void main() {
  late AnalyticsCubit cubit;
  late MockBillRepository mockBillRepo;
  late MockProductRepository mockProductRepo;

  setUp(() {
    mockBillRepo = MockBillRepository();
    mockProductRepo = MockProductRepository();
    cubit = AnalyticsCubit(mockBillRepo, mockProductRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('AnalyticsCubit', () {
    test('initial state is AnalyticsInitial', () {
      expect(cubit.state, isA<AnalyticsInitial>());
    });

    final testBills = [
      Bill(id: 1, date: DateTime.now().toIso8601String().split('T')[0], totalAmount: 100, finalTotal: 110, purchaseAmount: 80),
    ];

    blocTest<AnalyticsCubit, AnalyticsState>(
      'loadAnalytics emits Loading and then Loaded with correct data',
      build: () {
        when(() => mockBillRepo.getAllBills()).thenAnswer((_) async => testBills);
        when(() => mockProductRepo.getAllProducts()).thenAnswer((_) async => []);
        return cubit;
      },
      act: (cubit) => cubit.loadAnalytics(),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsLoaded>().having((s) => s.todaySales, 'today sales', 110.0),
      ],
    );

    blocTest<AnalyticsCubit, AnalyticsState>(
      'loadAnalytics emits Error when repository fails',
      build: () {
        when(() => mockBillRepo.getAllBills()).thenThrow(Exception('DB Error'));
        return cubit;
      },
      act: (cubit) => cubit.loadAnalytics(),
      expect: () => [
        isA<AnalyticsLoading>(),
        isA<AnalyticsError>().having((e) => e.message, 'error message', contains('DB Error')),
      ],
    );
  });
}
