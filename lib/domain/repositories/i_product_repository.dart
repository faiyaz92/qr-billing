import '../../data/models/product.dart';

abstract class IProductRepository {
  Future<int> insertProduct(Product product);
  Future<List<Product>> getAllProducts();
  Future<Product?> getProductById(int id);
  Future<int> updateProduct(Product product);
  Future<int> deleteProduct(int id);
}