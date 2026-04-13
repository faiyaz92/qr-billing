import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_list_state.dart';
import '../../core/injection.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../core/services/i_print_service.dart';
import '../../core/services/i_thermal_printer_service.dart';
import '../../core/services/i_settings_service.dart';
import '../../data/models/product.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProductListCubit extends Cubit<ProductListState> {
  final IProductRepository _productRepo = getIt<IProductRepository>();
  final IPrintService _printService = getIt<IPrintService>();
  final IThermalPrinterService _thermalPrinterService = getIt<IThermalPrinterService>();
  final ISettingsService _settingsService = getIt<ISettingsService>();
  List<Product> _products = [];
  bool _showQr = false;
  bool _showBarcode = false;

  ProductListCubit() : super(ProductListInitial()) {
    loadProducts();
  }

  void loadProducts() async {
    _products = await _productRepo.getAllProducts();
    emit(ProductListLoaded(_products, showQr: _showQr, showBarcode: _showBarcode));
  }

  void toggleQr(bool show) {
    _showQr = show;
    emit(ProductListLoaded(_products, showQr: _showQr, showBarcode: _showBarcode));
  }

  void toggleBarcode(bool show) {
    _showBarcode = show;
    emit(ProductListLoaded(_products, showQr: _showQr, showBarcode: _showBarcode));
  }

  Future<void> printQRCode(Product product) async {
    try {
      final data = product.qrData ?? 'No QR data';
      final title = product.name ?? 'Product';

      // Get store name
      final storeName = await _settingsService.getStoreName() ?? 'Store';

      // Format prices
      final sellingPrice = product.sellingPrice ?? 0.0;
      final originalPrice = product.originalPrice ?? sellingPrice;

      final payload = '''
$storeName
$title

Price: ₹${sellingPrice.toStringAsFixed(2)}
MRP: ₹${originalPrice.toStringAsFixed(2)}

$data

''';

      if (_thermalPrinterService.isConnected) {
        await _thermalPrinterService.printReceipt(Uint8List.fromList(utf8.encode(payload)));
      } else {
        await _printService.printQRCode(data, title);
      }
    } catch (e) {
      throw Exception('Print failed: $e');
    }
  }

  Future<void> printBarcode(Product product) async {
    try {
      final data = product.qrData ?? 'No data';
      final title = product.name ?? 'Product';

      if (_thermalPrinterService.isConnected) {
        final payload = 'BARCODE|$title|$data\n\n\n\n';
        await _thermalPrinterService.printReceipt(Uint8List.fromList(utf8.encode(payload)));
      } else {
        await _printService.printBarcode(data, title);
      }
    } catch (e) {
      throw Exception('Print failed: $e');
    }
  }
}