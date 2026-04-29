import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'i_db_import_export_service.dart';
import '../../data/database_helper.dart';

class DbImportExportServiceImpl implements IDbImportExportService {
  final DatabaseHelper _databaseHelper;

  DbImportExportServiceImpl(this._databaseHelper);

  // ─── Export ─────────────────────────────────────────────────────────────────

  @override
  Future<String> exportDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'billing.db');
    final exportDir = await _getExportDirectory();
    final timestamp = _timestamp();
    final exportPath = join(exportDir.path, 'qr_billing_backup_$timestamp.db');

    // Close connection so file is flushed, then copy
    final db = await _databaseHelper.database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');

    final sourceFile = File(dbPath);
    await sourceFile.copy(exportPath);

    return exportPath;
  }

  @override
  Future<String> exportAsJson() async {
    final db = await _databaseHelper.database;
    final exportDir = await _getExportDirectory();
    final timestamp = _timestamp();
    final exportPath = join(exportDir.path, 'qr_billing_backup_$timestamp.json');

    // Read all tables
    final products = await db.query('products');
    final bills = await db.query('bills');
    final billItems = await db.query('bill_items');

    final data = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': {
        'products': products,
        'bills': bills,
        'bill_items': billItems,
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await File(exportPath).writeAsString(jsonString);

    return exportPath;
  }

  @override
  Future<String> exportAsJsonByDateRange(DateTime start, DateTime end) async {
    final db = await _databaseHelper.database;
    final exportDir = await _getExportDirectory();
    final startStr = '${_pad(start.day)}${_pad(start.month)}${start.year}';
    final endStr = '${_pad(end.day)}${_pad(end.month)}${end.year}';
    final exportPath = join(exportDir.path, 'qr_billing_backup_${startStr}_to_$endStr.json');

    final startIso = start.toIso8601String().split('T')[0];
    final endIso = end.toIso8601String().split('T')[0];

    final products = await db.query('products');
    final bills = await db.query('bills', where: 'date >= ? AND date <= ?', whereArgs: [startIso, endIso]);
    
    final billIds = bills.map((b) => b['id']).toList();
    List<Map<String, Object?>> billItems = [];
    if (billIds.isNotEmpty) {
      final placeholders = List.filled(billIds.length, '?').join(',');
      billItems = await db.query('bill_items', where: 'bill_id IN ($placeholders)', whereArgs: billIds);
    }

    final data = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': {
        'products': products,
        'bills': bills,
        'bill_items': billItems,
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await File(exportPath).writeAsString(jsonString);

    return exportPath;
  }

  @override
  Future<String> exportDatabaseByDateRange(DateTime start, DateTime end) async {
    final sourceDb = await _databaseHelper.database;
    final exportDir = await _getExportDirectory();
    final startStr = '${_pad(start.day)}${_pad(start.month)}${start.year}';
    final endStr = '${_pad(end.day)}${_pad(end.month)}${end.year}';
    final exportPath = join(exportDir.path, 'qr_billing_backup_${startStr}_to_$endStr.db');

    // Create a new temp db
    final tempDb = await openDatabase(
      exportPath,
      version: 1,
      onCreate: (db, version) async {
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
      },
    );

    // Fetch data
    final startIso = start.toIso8601String().split('T')[0];
    final endIso = end.toIso8601String().split('T')[0];

    final products = await sourceDb.query('products');
    final bills = await sourceDb.query('bills', where: 'date >= ? AND date <= ?', whereArgs: [startIso, endIso]);
    final billIds = bills.map((b) => b['id']).toList();

    List<Map<String, Object?>> billItems = [];
    if (billIds.isNotEmpty) {
      final placeholders = List.filled(billIds.length, '?').join(',');
      billItems = await sourceDb.query('bill_items', where: 'bill_id IN ($placeholders)', whereArgs: billIds);
    }

    // Insert into tempDb
    Batch batch = tempDb.batch();
    for (var p in products) {
      batch.insert('products', p);
    }
    for (var b in bills) {
      batch.insert('bills', b);
    }
    for (var bi in billItems) {
      batch.insert('bill_items', bi);
    }
    await batch.commit(noResult: true);

    await tempDb.close();

    return exportPath;
  }


  @override
  Future<String> createAutoBackup() async {
    final dbPath = join(await getDatabasesPath(), 'billing.db');
    final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final exportDir = Directory(join(dir.path, 'QRBillingBackups'));
    if (!await exportDir.exists()) await exportDir.create(recursive: true);

    // Use exact timestamp for auto backup so it doesn't overwrite anything
    final now = DateTime.now();
    final exactTime = '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final exportPath = join(exportDir.path, 'qr_billing_autobackup_$exactTime.db');

    final db = await _databaseHelper.database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');

    final sourceFile = File(dbPath);
    await sourceFile.copy(exportPath);

    return exportPath;
  }

  // ─── Import ─────────────────────────────────────────────────────────────────

  @override
  Future<void> importDatabase(String filePath) async {
    final sourceFile = File(filePath);
    if (!await sourceFile.exists()) {
      throw Exception('File not found: $filePath');
    }

    // Validate it's a valid SQLite file (first 16 bytes = SQLite magic header)
    final bytes = await sourceFile.openRead(0, 16).first;
    const sqliteMagic = 'SQLite format 3\x00';
    final magic = String.fromCharCodes(bytes);
    if (!magic.startsWith('SQLite format 3')) {
      throw Exception('Invalid SQLite database file');
    }

    final dbPath = join(await getDatabasesPath(), 'billing.db');

    // Close existing DB connection before replacing file
    await _closeAndReplaceDb(dbPath, sourceFile);
  }

  @override
  Future<void> importFromJson(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final jsonString = await file.readAsString();
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid JSON file');
    }

    // Version check
    final version = data['version'] as int? ?? 1;
    if (version != 1) {
      throw Exception('Unsupported backup version: $version');
    }

    final tables = data['tables'] as Map<String, dynamic>?;
    if (tables == null) {
      throw Exception('Invalid backup format: missing tables');
    }

    final products = (tables['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final bills = (tables['bills'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final billItems = (tables['bill_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final db = await _databaseHelper.database;

    // Use transaction for atomic restore
    await db.transaction((txn) async {
      // Clear existing data (order matters due to FK constraints)
      await txn.delete('bill_items');
      await txn.delete('bills');
      await txn.delete('products');

      // Re-insert products
      for (final product in products) {
        await txn.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Re-insert bills
      for (final bill in bills) {
        await txn.insert('bills', bill, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Re-insert bill_items
      for (final item in billItems) {
        await txn.insert('bill_items', item, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ─── Merge ──────────────────────────────────────────────────────────────────

  @override
  Future<void> mergeDatabase(String filePath) async {
    final sourceFile = File(filePath);
    if (!await sourceFile.exists()) throw Exception('File not found: $filePath');

    final bytes = await sourceFile.openRead(0, 16).first;
    if (!String.fromCharCodes(bytes).startsWith('SQLite format 3')) {
      throw Exception('Invalid SQLite database file');
    }

    // Open backup DB as read-only to extract data
    final backupDb = await openDatabase(filePath, readOnly: true);
    final products = await backupDb.query('products');
    final bills = await backupDb.query('bills');
    final billItems = await backupDb.query('bill_items');
    await backupDb.close();

    // Reuse JSON merge logic with extracted data
    await _mergeData(products, bills, billItems);
  }

  @override
  Future<void> mergeFromJson(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found: $filePath');

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid JSON file');
    }

    final tables = data['tables'] as Map<String, dynamic>?;
    if (tables == null) throw Exception('Invalid backup format: missing tables');

    final products = (tables['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final bills = (tables['bills'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final billItems = (tables['bill_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    await _mergeData(products, bills, billItems);
  }

  /// Core merge logic shared by both mergeDatabase() and mergeFromJson()
  ///
  /// Duplicate detection:
  /// - Products  → by `qr_data` (unique per product)
  /// - Bills     → by date + customer_mobile + final_total
  /// - BillItems → remapped to new bill IDs; skipped if parent bill was duplicate
  Future<void> _mergeData(
    List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> bills,
    List<Map<String, dynamic>> billItems,
  ) async {
    final db = await _databaseHelper.database;

    // ── Step 1: Load existing product QR data → id map ──────────────────────
    final existingProducts = await db.query('products', columns: ['id', 'qr_data']);
    final existingQrMap = <String, int>{
      for (final p in existingProducts)
        if (p['qr_data'] != null) p['qr_data'] as String: p['id'] as int,
    };

    // ── Step 2: Load existing bill composite keys ────────────────────────────
    final existingBills = await db.query(
      'bills',
      columns: ['id', 'date', 'customer_mobile', 'final_total'],
    );
    final existingBillKeys = <String>{
      for (final b in existingBills)
        '${b['date']}_${b['customer_mobile']}_${b['final_total']}',
    };

    await db.transaction((txn) async {
      // ── Merge Products ─────────────────────────────────────────────────────
      final productIdMap = <int, int>{}; // old id → new id

      for (final product in products) {
        final oldId = product['id'] as int;
        final qrData = product['qr_data'] as String?;

        if (qrData != null && existingQrMap.containsKey(qrData)) {
          // Already exists — map old ID to existing ID
          productIdMap[oldId] = existingQrMap[qrData]!;
        } else {
          // New product — insert without ID (auto-generate)
          final newMap = Map<String, dynamic>.from(product)..remove('id');
          final newId = await txn.insert('products', newMap);
          productIdMap[oldId] = newId;
        }
      }

      // ── Merge Bills ────────────────────────────────────────────────────────
      final billIdMap = <int, int?>{}; // old id → new id (null = duplicate, skip)

      for (final bill in bills) {
        final oldBillId = bill['id'] as int;
        final compositeKey = '${bill['date']}_${bill['customer_mobile']}_${bill['final_total']}';

        if (existingBillKeys.contains(compositeKey)) {
          // Duplicate bill — skip it and its items
          billIdMap[oldBillId] = null;
        } else {
          final newMap = Map<String, dynamic>.from(bill)..remove('id');
          final newBillId = await txn.insert('bills', newMap);
          billIdMap[oldBillId] = newBillId;
          existingBillKeys.add(compositeKey); // Prevent duplicates within backup itself
        }
      }

      // ── Merge Bill Items ───────────────────────────────────────────────────
      for (final item in billItems) {
        final oldBillId = item['bill_id'] as int;
        final newBillId = billIdMap[oldBillId];

        // Skip items whose parent bill was a duplicate
        if (newBillId == null) continue;

        final newMap = Map<String, dynamic>.from(item)
          ..remove('id')
          ..['bill_id'] = newBillId;

        // Remap product_id if product was merged
        final oldProductId = item['product_id'] as int?;
        if (oldProductId != null && productIdMap.containsKey(oldProductId)) {
          newMap['product_id'] = productIdMap[oldProductId];
        }

        await txn.insert('bill_items', newMap);
      }
    });
  }

  // ─── Private Backups Management ─────────────────────────────────────────────

  @override
  Future<List<File>> getSavedBackups() async {
    final exportDir = await _getExportDirectory();
    final files = exportDir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.db') || f.path.endsWith('.json')
    ).toList();
    
    // Sort by last modified time (newest first)
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  @override
  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ─── Private Helpers ────────────────────────────────────────────────────────

  Future<void> _closeAndReplaceDb(String dbPath, File sourceFile) async {
    final dbFile = File(dbPath);
    final walFile = File('$dbPath-wal');
    final shmFile = File('$dbPath-shm');

    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();
    if (await dbFile.exists()) await dbFile.delete();

    await sourceFile.copy(dbPath);
    await DatabaseHelper.resetInstance();
  }

  Future<Directory> _getExportDirectory() async {
    final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final exportDir = Directory(join(dir.path, 'QRBillingBackups'));
    if (!await exportDir.exists()) await exportDir.create(recursive: true);
    return exportDir;
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}';
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
}
