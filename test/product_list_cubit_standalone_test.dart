import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/product_list_cubit.dart';
import 'package:qr_based_billing/presentation/cubits/product_list_state.dart';
import 'package:qr_based_billing/domain/repositories/i_product_repository.dart';
import 'package:qr_based_billing/core/services/print_manager.dart';
import 'package:qr_based_billing/data/models/product.dart';

class MockProductRepository extends Mock implements IProductRepository {}
class MockPrintManager extends Mock implements PrintManager {}

void main() async {
  print('--- ProductListCubit Standalone Tests ---');
  
  late ProductListCubit cubit;
  late MockProductRepository mockRepo;
  late MockPrintManager mockPrintManager;

  final testProducts = [
    Product(id: 1, name: 'Sugar', brand: 'Madhur', sellingPrice: 45.0, purchasePrice: 40.0),
    Product(id: 2, name: 'Milk', brand: 'Amul', sellingPrice: 60.0, purchasePrice: 55.0),
  ];

  mockRepo = MockProductRepository();
  mockPrintManager = MockPrintManager();

  // Setup default behavior
  when(() => mockRepo.getAllProducts()).thenAnswer((_) async => testProducts);

  print('Testing: loadProducts()...');
  cubit = ProductListCubit(mockRepo, mockPrintManager);
  
  // Wait for initial load
  await Future.delayed(Duration(milliseconds: 100));

  if (cubit.state is ProductListLoaded) {
    final state = cubit.state as ProductListLoaded;
    if (state.products.length == 2) {
      print('✅ PASS: Initial products loaded successfully');
    } else {
      print('❌ FAIL: Products length mismatch. Expected 2, got ${state.products.length}');
    }
  } else {
    print('❌ FAIL: Expected ProductListLoaded state');
  }

  print('\nTesting: searchProducts("Milk")...');
  cubit.searchProducts('Milk');
  
  if (cubit.state is ProductListLoaded) {
    final state = cubit.state as ProductListLoaded;
    if (state.products.length == 1 && state.products.first.name == 'Milk') {
      print('✅ PASS: Search filtered correctly');
    } else {
      print('❌ FAIL: Search filtering failed');
    }
  }

  print('\nTesting: toggleQr(true)...');
  cubit.toggleQr(true);
  if (cubit.state is ProductListLoaded) {
    final state = cubit.state as ProductListLoaded;
    if (state.showQr == true) {
      print('✅ PASS: toggleQr works');
    } else {
      print('❌ FAIL: toggleQr failed');
    }
  }

  print('\n--- All Cubit Tests Completed ---');
  cubit.close();
}
