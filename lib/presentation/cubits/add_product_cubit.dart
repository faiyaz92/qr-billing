import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_product_state.dart';
import '../../core/injection.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../data/models/product.dart';
import '../../core/services/i_qr_generator_service.dart';
import '../../core/services/i_encryption_service.dart';
import 'dart:convert';

class AddProductCubit extends Cubit<AddProductState> {
  final IProductRepository _productRepo = getIt<IProductRepository>();
  final IQrGeneratorService _qrGenerator = getIt<IQrGeneratorService>();
  final IEncryptionService _encryption = getIt<IEncryptionService>();

  AddProductCubit() : super(AddProductInitial());

  Future<void> addProduct(Map<String, dynamic> data) async {
    emit(AddProductLoading());
    try {
      // Encrypt sensitive data
      final sensitiveData = {
        'date_of_purchase': data['date_of_purchase'],
        'purchase_price': data['purchase_price'],
      };
      final encryptedSensitive = _encryption.encryptData(jsonEncode(sensitiveData));

      // Prepare data map for QR with compact field names
      final qrDataMap = {
        'n': data['name'],
        'b': data['brand'],
        't': data['tax'],
        'sp': data['selling_price'],
        'op': data['original_price'],
        'esd': encryptedSensitive,
      };

      final qrData = await _qrGenerator.generateQrData(1, qrDataMap);
      final product = Product(
        name: data['name'],
        brand: data['brand'],
        dateOfPurchase: data['date_of_purchase'],
        purchasePrice: data['purchase_price'],
        sellingPrice: data['selling_price'],
        originalPrice: data['original_price'],
        tax: data['tax'],
        qrData: qrData,
      );
      await _productRepo.insertProduct(product);
      emit(AddProductSuccess(qrData));
    } catch (e) {
      emit(AddProductError(e.toString()));
    }
  }
}