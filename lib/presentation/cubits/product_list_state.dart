import '../../data/models/product.dart';

abstract class ProductListState {}

class ProductListInitial extends ProductListState {}

class ProductListLoading extends ProductListState {}

class ProductListLoaded extends ProductListState {
  final List<Product> products;
  final bool showQr;
  final bool showBarcode;
  ProductListLoaded(this.products, {this.showQr = false, this.showBarcode = false});
}