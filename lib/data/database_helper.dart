import 'package:qr_based_billing/data/models/bill.dart';
import 'package:qr_based_billing/data/models/bill_item.dart';
import 'package:qr_based_billing/data/models/product.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Resets the singleton so next access reopens the DB from disk.
  /// Call this after replacing the underlying .db file during import.
  static Future<void> resetInstance() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _instance = DatabaseHelper._internal();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'billing.db');
    Database db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        brand TEXT,
        date_of_purchase TEXT,
        purchase_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        original_price REAL,
        tax REAL,
        qr_data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        discount REAL,
        final_total REAL NOT NULL,
        purchase_amount REAL,
        customer_name TEXT,
        customer_mobile TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE bill_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id INTEGER NOT NULL,
        product_id INTEGER,
        quantity INTEGER NOT NULL,
        item_discount REAL,
        purchase_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        tax REAL DEFAULT 0.0,
        item_name TEXT,
        FOREIGN KEY (bill_id) REFERENCES bills (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  // Product methods
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Bill methods
  Future<int> insertBill(Bill bill) async {
    final db = await database;
    return await db.insert('bills', bill.toMap());
  }

  Future<int> updateBill(Bill bill) async {
    final db = await database;
    return await db.update('bills', bill.toMap(), where: 'id = ?', whereArgs: [bill.id]);
  }

  Future<List<Bill>> getBillsByDate(String date) async {
    final db = await database;
    final maps = await db.query('bills', where: 'date = ?', whereArgs: [date]);
    return maps.map((map) => Bill.fromMap(map)).toList();
  }

  Future<List<Bill>> getAllBills() async {
    final db = await database;
    final maps = await db.query('bills');
    return maps.map((map) => Bill.fromMap(map)).toList();
  }

  Future<Bill?> getBillById(int id) async {
    final db = await database;
    final maps = await db.query('bills', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Bill.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertBillItem(BillItem item) async {
    final db = await database;
    
    // Create map with tax if column exists
    var map = item.toMap();
    if (item.taxRate != null && item.taxRate! > 0) {
      map['tax'] = item.taxRate;
    }
    
    print('Saving bill item: $map');
    final result = await db.insert('bill_items', map);
    print('Bill item saved with ID: $result');
    return result;
  }

  Future<int> deleteBillItems(int billId) async {
    final db = await database;
    return await db.delete('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
  }

  Future<List<BillItem>> getBillItems(int billId) async {
    final db = await database;
    final maps = await db.query('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
    print('Loading bill items for bill $billId: ${maps.length} items found');
    for (var map in maps) {
      print('Bill item data: $map');
    }
    return maps.map((map) => BillItem.fromMap(map)).toList();
  }

  Future<double> getBillProfit(int billId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        (SUM(p.selling_price * bi.quantity - COALESCE(bi.item_discount, 0)) - COALESCE(b.discount, 0)) - SUM(p.purchase_price * bi.quantity) AS profit
      FROM bills b
      JOIN bill_items bi ON b.id = bi.bill_id
      JOIN products p ON bi.product_id = p.id
      WHERE b.id = ?
      GROUP BY b.id
    ''', [billId]);
    if (result.isNotEmpty) {
      return result.first['profit'] as double? ?? 0.0;
    }
    return 0.0;
  }
}