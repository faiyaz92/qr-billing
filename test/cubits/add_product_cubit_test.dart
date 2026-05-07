import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/add_product_cubit.dart';
import 'package:qr_based_billing/presentation/cubits/add_product_state.dart';
import 'package:qr_based_billing/domain/repositories/i_product_repository.dart';
import 'package:qr_based_billing/core/services/i_qr_generator_service.dart';
import 'package:qr_based_billing/core/services/i_encryption_service.dart';

class MockProductRepository extends Mock implements IProductRepository {}
class MockQrGeneratorService extends Mock implements IQrGeneratorService {}
class MockEncryptionService extends Mock implements IEncryptionService {}

void main() {
  late AddProductCubit cubit;
  late MockProductRepository mockRepo;
  late MockQrGeneratorService mockQr;
  late MockEncryptionService mockEncryption;

  setUp(() {
    mockRepo = MockProductRepository();
    mockQr = MockQrGeneratorService();
    mockEncryption = MockEncryptionService();
    cubit = AddProductCubit(mockRepo, mockQr, mockEncryption);
  });

  tearDown(() {
    cubit.close();
  });

  group('AddProductCubit', () {
    test('initial state is AddProductInitial', () {
      expect(cubit.state, isA<AddProductInitial>());
    });

    final testData = {
      'name': 'Milk',
      'brand': 'Amul',
      'date_of_purchase': '2024-01-01',
      'purchase_price': 50.0,
      'selling_price': 60.0,
      'original_price': 65.0,
      'tax': 5.0,
    };

    blocTest<AddProductCubit, AddProductState>(
      'addProduct successfully encrypts, generates QR, and saves product',
      build: () {
        when(() => mockEncryption.encryptData(any())).thenReturn('encrypted_data');
        when(() => mockQr.generateQrData(any(), any())).thenAnswer((_) async => 'qr_code_string');
        when(() => mockRepo.insertProduct(any())).thenAnswer((_) async => 1);
        return cubit;
      },
      act: (cubit) => cubit.addProduct(testData),
      expect: () => [
        isA<AddProductLoading>(),
        isA<AddProductSuccess>(),
      ],
      verify: (_) {
        verify(() => mockEncryption.encryptData(any())).called(1);
        verify(() => mockQr.generateQrData(1, any())).called(1);
        verify(() => mockRepo.insertProduct(any())).called(1);
      },
    );

    blocTest<AddProductCubit, AddProductState>(
      'addProduct emits Error when repository fails',
      build: () {
        when(() => mockEncryption.encryptData(any())).thenReturn('enc');
        when(() => mockQr.generateQrData(any(), any())).thenAnswer((_) async => 'qr');
        when(() => mockRepo.insertProduct(any())).thenThrow(Exception('DB Fail'));
        return cubit;
      },
      act: (cubit) => cubit.addProduct(testData),
      expect: () => [
        isA<AddProductLoading>(),
        isA<AddProductError>().having((e) => e.message, 'error message', contains('DB Fail')),
      ],
    );
  });
}
