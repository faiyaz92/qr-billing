import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/product_list_cubit.dart';
import 'package:qr_based_billing/presentation/cubits/product_list_state.dart';
import 'package:qr_based_billing/domain/repositories/i_product_repository.dart';
import 'package:qr_based_billing/core/services/print_manager.dart';
import 'package:qr_based_billing/data/models/product.dart';

class MockProductRepository extends Mock implements IProductRepository {}
class MockPrintManager extends Mock implements PrintManager {}

void main() {
  late ProductListCubit cubit;
  late MockProductRepository mockRepo;
  late MockPrintManager mockPrint;

  final testProducts = [
    Product(id: 1, name: 'Milk', brand: 'Amul', sellingPrice: 60, purchasePrice: 50),
    Product(id: 2, name: 'Bread', brand: 'Britannia', sellingPrice: 40, purchasePrice: 30),
  ];

  setUp(() {
    mockRepo = MockProductRepository();
    mockPrint = MockPrintManager();
    when(() => mockRepo.getAllProducts()).thenAnswer((_) async => testProducts);
    cubit = ProductListCubit(mockRepo, mockPrint);
  });

  tearDown(() {
    cubit.close();
  });

  group('ProductListCubit', () {
    blocTest<ProductListCubit, ProductListState>(
      'loadProducts updates state with all products',
      build: () => cubit,
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        isA<ProductListLoaded>().having((s) => s.products.length, 'total products', 2),
      ],
    );

    blocTest<ProductListCubit, ProductListState>(
      'searchProducts filters list correctly',
      build: () => cubit,
      act: (cubit) => cubit.searchProducts('Milk'),
      expect: () => [
        isA<ProductListLoaded>().having((s) => s.products.length, 'filtered count', 1).having((s) => s.products.first.name, 'name', 'Milk'),
      ],
    );

    blocTest<ProductListCubit, ProductListState>(
      'toggleQr updates state flag',
      build: () => cubit,
      act: (cubit) => cubit.toggleQr(true),
      expect: () => [
        isA<ProductListLoaded>().having((s) => s.showQr, 'showQr', true),
      ],
    );

    blocTest<ProductListCubit, ProductListState>(
      'deleteProduct calls repo and reloads',
      build: () {
        when(() => mockRepo.deleteProduct(any())).thenAnswer((_) async => 1);
        return cubit;
      },
      act: (cubit) => cubit.deleteProduct(1),
      verify: (_) {
        verify(() => mockRepo.deleteProduct(1)).called(1);
        verify(() => mockRepo.getAllProducts()).called(greaterThan(0));
      },
    );
  });
}
