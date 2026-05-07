import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/billing_cubit.dart';
import 'package:qr_based_billing/presentation/cubits/billing_state.dart';
import 'package:qr_based_billing/core/services/i_scan_service.dart';
import 'package:qr_based_billing/core/services/print_manager.dart';
import 'package:qr_based_billing/core/services/i_encryption_service.dart';
import 'package:qr_based_billing/core/services/i_settings_service.dart';
import 'package:qr_based_billing/core/services/pdf_generator_service.dart';
import 'package:qr_based_billing/domain/repositories/i_bill_repository.dart';
import 'package:qr_based_billing/data/models/scanned_data.dart';
import 'package:qr_based_billing/data/models/bill_item.dart';
import 'package:qr_based_billing/data/models/product.dart';
import 'package:qr_based_billing/data/models/bill.dart';
import 'package:qr_based_billing/data/models/qr_data.dart';

class MockScanService extends Mock implements IScanService {}
class MockPrintManager extends Mock implements PrintManager {}
class MockEncryptionService extends Mock implements IEncryptionService {}
class MockSettingsService extends Mock implements ISettingsService {}
class MockBillRepository extends Mock implements IBillRepository {}
class MockPdfGeneratorService extends Mock implements PdfGeneratorService {}

void main() {
  late BillingCubit billingCubit;
  late MockScanService mockScanService;
  late MockPrintManager mockPrintManager;
  late MockEncryptionService mockEncryptionService;
  late MockSettingsService mockSettingsService;
  late MockBillRepository mockBillRepository;
  late MockPdfGeneratorService mockPdfGeneratorService;

  setUp(() {
    mockScanService = MockScanService();
    mockPrintManager = MockPrintManager();
    mockEncryptionService = MockEncryptionService();
    mockSettingsService = MockSettingsService();
    mockBillRepository = MockBillRepository();
    mockPdfGeneratorService = MockPdfGeneratorService();

    billingCubit = BillingCubit(
      scanService: mockScanService,
      printManager: mockPrintManager,
      encryptionService: mockEncryptionService,
      settingsService: mockSettingsService,
      billRepository: mockBillRepository,
      pdfGeneratorService: mockPdfGeneratorService,
    );
  });

  tearDown(() {
    billingCubit.close();
  });

  group('BillingCubit', () {
    test('initial state is correct', () {
      expect(billingCubit.state, const BillingUpdated(cart: [], showProfitLossMode: false, isEditMode: false, taxRate: 0.0));
    });

    blocTest<BillingCubit, BillingState>(
      'toggleProfitLossMode emits state with updated showProfitLossMode',
      build: () => billingCubit,
      act: (cubit) => cubit.toggleProfitLossMode(),
      expect: () => [
        isA<BillingUpdated>().having((s) => s.showProfitLossMode, 'showProfitLossMode', true),
      ],
    );

    final testProduct = Product(
      id: 1,
      name: 'Test Product',
      brand: 'Test Brand',
      sellingPrice: 100.0,
      purchasePrice: 80.0,
      tax: 10.0,
    );

    final testScannedData = ScannedData(
      data: {
        'name': 'Test Product',
        'brand': 'Test Brand',
        'selling_price': 100.0,
        'tax': 10.0,
      },
      qrCode: 'test_qr',
    );

    blocTest<BillingCubit, BillingState>(
      'addProductToCart adds product to cart and emits updated state',
      build: () => billingCubit,
      act: (cubit) => cubit.addProductToCart(product: testProduct, scannedData: testScannedData),
      expect: () => [
        isA<BillingUpdated>().having((s) => s.cart.length, 'cart length', 1),
      ],
    );

    blocTest<BillingCubit, BillingState>(
      'adding same product twice updates quantity instead of adding new item',
      build: () => billingCubit,
      act: (cubit) {
        cubit.addProductToCart(product: testProduct, scannedData: testScannedData);
        cubit.addProductToCart(product: testProduct, scannedData: testScannedData);
      },
      expect: () => [
        isA<BillingUpdated>().having((s) => s.cart.length, 'cart length', 1),
        isA<BillingUpdated>().having((s) => s.cart.first.quantity, 'quantity', 2),
      ],
    );

    blocTest<BillingCubit, BillingState>(
      'scanProduct success with encrypted sensitive data',
      build: () {
        when(() => mockScanService.scanAndDecode(any())).thenAnswer((_) async => ScannedData(
          data: {
            'name': 'Encrypted Product',
            'selling_price': '200',
            'encrypted_sensitive': 'enc_data'
          },
          qrCode: 'qr_code',
        ));
        when(() => mockEncryptionService.decryptData('enc_data')).thenReturn('{"purchase_price": "150"}');
        return billingCubit;
      },
      act: (cubit) => cubit.scanProduct('qr_code'),
      expect: () => [
        isA<BillingLoading>(),
        isA<BillingUpdated>().having((s) => s.cart.first.product.purchasePrice, 'purchasePrice', 150.0),
      ],
    );

    blocTest<BillingCubit, BillingState>(
      'scanProduct invalid QR emits BillingError',
      build: () {
        when(() => mockScanService.scanAndDecode(any())).thenAnswer((_) async => null);
        return billingCubit;
      },
      act: (cubit) => cubit.scanProduct('invalid'),
      expect: () => [
        isA<BillingLoading>(),
        isA<BillingError>().having((e) => e.message, 'message', 'Invalid QR'),
      ],
    );

    blocTest<BillingCubit, BillingState>(
      'updateQuantity increments quantity',
      build: () => billingCubit,
      seed: () => BillingUpdated(cart: [CartItem(product: testProduct, data: testScannedData, quantity: 1)]),
      act: (cubit) => cubit.updateQuantity(0, 1),
      expect: () => [
        isA<BillingUpdated>().having((s) => s.cart.first.quantity, 'quantity', 2),
      ],
    );

    blocTest<BillingCubit, BillingState>(
      'updateQuantity removes item when quantity reaches zero',
      build: () => billingCubit,
      seed: () => BillingUpdated(cart: [CartItem(product: testProduct, data: testScannedData, quantity: 1)]),
      act: (cubit) => cubit.updateQuantity(0, -1),
      expect: () => [
        isA<BillingUpdated>().having((s) => s.cart.length, 'cart length', 0),
      ],
    );

    blocTest<BillingCubit, BillingState>(
      'updateItemDiscount updates discount correctly',
      build: () => billingCubit,
      seed: () => BillingUpdated(cart: [CartItem(product: testProduct, data: testScannedData, quantity: 1)]),
      act: (cubit) => cubit.updateItemDiscount(0, 10.0),
      expect: () => [
        isA<BillingUpdated>().having((s) => s.cart.first.itemDiscount, 'discount', 10.0),
      ],
    );

    blocTest<BillingCubit, BillingState>(
      'clearCart resets cart and edit mode',
      build: () => billingCubit,
      seed: () => BillingUpdated(cart: [CartItem(product: testProduct, data: testScannedData)], isEditMode: true),
      act: (cubit) => cubit.clearCart(),
      expect: () => [
        isA<BillingUpdated>().having((s) => s.cart.length, 'cart length', 0).having((s) => s.isEditMode, 'isEditMode', false),
      ],
    );

    blocTest<BillingCubit, BillingState>(
      'saveBill inserts new bill when _currentBillId is null',
      build: () {
        when(() => mockBillRepository.insertBill(any())).thenAnswer((_) async => 101);
        when(() => mockBillRepository.insertBillItem(any())).thenAnswer((_) async => 1);
        return billingCubit;
      },
      seed: () => BillingUpdated(cart: [CartItem(product: testProduct, data: testScannedData)]),
      act: (cubit) => cubit.saveBill(),
      verify: (_) {
        verify(() => mockBillRepository.insertBill(any())).called(1);
        verify(() => mockBillRepository.insertBillItem(any())).called(1);
      },
    );

    blocTest<BillingCubit, BillingState>(
      'loadBillForView sets edit mode and populates cart',
      build: () {
        when(() => mockBillRepository.getBillById(any())).thenAnswer((_) async => Bill(id: 1, date: '2024-01-01', totalAmount: 100, finalTotal: 110));
        when(() => mockBillRepository.getBillItems(any())).thenAnswer((_) async => [
          BillItem(billId: 1, productId: 1, itemName: 'Item 1', quantity: 1, sellingPrice: 100, purchasePrice: 80, taxRate: 10),
        ]);
        return billingCubit;
      },
      act: (cubit) => cubit.loadBillForView(1),
      expect: () => [
        isA<BillingUpdated>().having((s) => s.isEditMode, 'isEditMode', true).having((s) => s.cart.length, 'cart length', 1),
      ],
    );

    test('calculateTotal returns correct amount', () {
      final cart = [
        CartItem(
          product: Product(
            id: 1, 
            name: 'Test', 
            brand: 'Test', 
            sellingPrice: 100, 
            purchasePrice: 80
          ), 
          data: testScannedData, 
          quantity: 2, 
          itemDiscount: 10
        ),
      ];
      billingCubit.emit(BillingUpdated(cart: cart));
      // (100 - 10) * 2 = 180
      expect(billingCubit.calculateTotal(), 180.0);
    });

    test('calculateTaxAmount returns correct amount', () {
      final cart = [
        CartItem(
          product: Product(
            id: 1, 
            name: 'Test', 
            brand: 'Test', 
            sellingPrice: 100, 
            purchasePrice: 80, 
            tax: 10
          ), 
          data: testScannedData, 
          quantity: 1, 
          itemDiscount: 0
        ),
      ];
      billingCubit.emit(BillingUpdated(cart: cart));
      // 100 * 0.1 = 10
      expect(billingCubit.calculateTaxAmount(), 10.0);
    });

    test('calculateYouSave returns correct amount', () {
      final cart = [
        CartItem(
          product: Product(
            id: 1, 
            name: 'Test', 
            brand: 'Test', 
            sellingPrice: 100, 
            purchasePrice: 80, 
            originalPrice: 150, 
            tax: 10
          ),
          data: testScannedData,
          quantity: 1,
          itemDiscount: 10
        ),
      ];
      billingCubit.emit(BillingUpdated(cart: cart, discount: 5));
      // Selling: (100-10) = 90. Tax: 9. Final: 99 + 5(additional) -> No wait, discount is minus from total
      // Subtotal = 90. Tax = 9. FinalTotal = 90 + 9 - 5 = 94.
      // MRP = 150. MRP Tax Estimate = 150 * (9/90) = 15. MRP Total = 165.
      // You Save = 165 - 94 = 71.
      expect(billingCubit.calculateYouSave(), 71.0);
    });
    
  });
}
