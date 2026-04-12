abstract class AddProductState {}

class AddProductInitial extends AddProductState {}

class AddProductLoading extends AddProductState {}

class AddProductSuccess extends AddProductState {
  final String qrData;
  AddProductSuccess(this.qrData);
}

class AddProductError extends AddProductState {
  final String message;
  AddProductError(this.message);
}