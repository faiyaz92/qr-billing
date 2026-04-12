import '../database_helper.dart';
import '../models/product.dart';
import '../../domain/repositories/i_product_repository.dart';

class ProductRepositoryImpl implements IProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<int> insertProduct(Product product) => _dbHelper.insertProduct(product);

  @override
  Future<List<Product>> getAllProducts() => _dbHelper.getAllProducts();

  @override
  Future<Product?> getProductById(int id) => _dbHelper.getProductById(id);

  @override
  Future<int> updateProduct(Product product) => _dbHelper.updateProduct(product);

  @override
  Future<int> deleteProduct(int id) => _dbHelper.deleteProduct(id);
}