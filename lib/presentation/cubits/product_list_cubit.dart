import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_list_state.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../core/services/print_manager.dart';
import '../../core/services/i_settings_service.dart';
import '../../data/models/product.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProductListCubit extends Cubit<ProductListState> {
  final IProductRepository _productRepo;
  final PrintManager _printManager;
  List<Product> _products = [];
  bool _showQr = false;
  bool _showBarcode = false;

  ProductListCubit(this._productRepo, this._printManager) : super(ProductListInitial()) {
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

  void searchProducts(String query) {
    if (query.isEmpty) {
      emit(ProductListLoaded(_products, showQr: _showQr, showBarcode: _showBarcode));
    } else {
      final filteredProducts = _products.where((product) =>
        (product.name?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
        (product.brand?.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).toList();
      emit(ProductListLoaded(filteredProducts, showQr: _showQr, showBarcode: _showBarcode));
    }
  }

  Future<void> printQRCode(Product product) async {
    try {
      await _printManager.printProductQR(product);
    } catch (e) {
      throw Exception('Print failed: $e');
    }
  }

  Future<void> printBarcode(Product product) async {
    try {
      await _printManager.printProductBarcode(product);
    } catch (e) {
      throw Exception('Print failed: $e');
    }
  }
}