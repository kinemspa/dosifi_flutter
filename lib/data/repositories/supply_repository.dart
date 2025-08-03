import '../models/supply.dart';
import '../../core/services/database_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class SupplyRepository {
  
  Future<Database> get _db async => await DatabaseService.database;

  // Create supplies table
  Future<void> createTable() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        brand TEXT,
        size TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        reorder_level INTEGER,
        unit TEXT DEFAULT 'pieces',
        lot_number TEXT,
        expiration_date TEXT,
        location TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // Create
  Future<int> insert(Supply supply) async {
    final db = await _db;
    return await db.insert('supplies', supply.toMap());
  }

  // Read
  Future<Supply?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'supplies',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Supply.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Supply>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'supplies',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Supply.fromMap(map)).toList();
  }

  Future<List<Supply>> getByCategory(SupplyCategory category) async {
    final db = await _db;
    final maps = await db.query(
      'supplies',
      where: 'category = ? AND is_active = ?',
      whereArgs: [category.displayName, 1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Supply.fromMap(map)).toList();
  }

  Future<List<Supply>> getLowStock() async {
    final db = await _db;
    final maps = await db.query(
      'supplies',
      where: 'quantity <= reorder_level AND reorder_level IS NOT NULL AND is_active = ?',
      whereArgs: [1],
      orderBy: 'quantity ASC',
    );

    return maps.map((map) => Supply.fromMap(map)).toList();
  }

  Future<List<Supply>> getExpiring({int daysAhead = 30}) async {
    final db = await _db;
    final futureDate = DateTime.now().add(Duration(days: daysAhead));
    final maps = await db.query(
      'supplies',
      where: 'expiration_date IS NOT NULL AND expiration_date <= ? AND is_active = ?',
      whereArgs: [futureDate.toIso8601String(), 1],
      orderBy: 'expiration_date ASC',
    );

    return maps.map((map) => Supply.fromMap(map)).toList();
  }

  // Update
  Future<int> update(Supply supply) async {
    final db = await _db;
    return await db.update(
      'supplies',
      supply.toMap(),
      where: 'id = ?',
      whereArgs: [supply.id],
    );
  }

  Future<int> updateQuantity(int id, int quantity) async {
    final db = await _db;
    return await db.update(
      'supplies',
      {
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> adjustQuantity(int id, int adjustment) async {
    final supply = await getById(id);
    if (supply == null) return 0;

    final newQuantity = (supply.quantity + adjustment).clamp(0, double.infinity).toInt();
    return await updateQuantity(id, newQuantity);
  }

  // Delete (soft delete)
  Future<int> delete(int id) async {
    final db = await _db;
    return await db.update(
      'supplies',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search
  Future<List<Supply>> search(String query) async {
    final db = await _db;
    final maps = await db.query(
      'supplies',
      where: '(name LIKE ? OR brand LIKE ? OR notes LIKE ?) AND is_active = ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Supply.fromMap(map)).toList();
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _db;
    final totalSupplies = await db.rawQuery(
      'SELECT COUNT(*) as count FROM supplies WHERE is_active = 1'
    );
    
    final lowStockCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM supplies WHERE quantity <= reorder_level AND reorder_level IS NOT NULL AND is_active = 1'
    );
    
    final expiringCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM supplies WHERE expiration_date IS NOT NULL AND expiration_date <= ? AND is_active = 1',
      [DateTime.now().add(const Duration(days: 30)).toIso8601String()]
    );

    final totalValue = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM supplies WHERE is_active = 1'
    );

    return {
      'total_supplies': totalSupplies.first['count'] ?? 0,
      'low_stock_count': lowStockCount.first['count'] ?? 0,
      'expiring_count': expiringCount.first['count'] ?? 0,
      'total_quantity': totalValue.first['total'] ?? 0,
    };
  }
}
