import 'package:sqflite/sqflite.dart';
import '../../core/services/database_service.dart';
import '../models/supply.dart';

class SupplyRepository {
  Future<List<Supply>> getAllSupplies() async {
    final db = await DatabaseService.database;
    final maps = await db.query('supplies', 
      where: 'is_active = ?', 
      whereArgs: [1], 
      orderBy: 'name ASC'
    );
    
    return List.generate(maps.length, (i) => Supply.fromMap(maps[i]));
  }

  Future<Supply?> getSupplyById(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'supplies',
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return Supply.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Supply>> getSuppliesByCategory(SupplyCategory category) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'supplies',
      where: 'category = ? AND is_active = ?',
      whereArgs: [category.displayName, 1],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) => Supply.fromMap(maps[i]));
  }

  Future<int> insertSupply(Supply supply) async {
    final db = await DatabaseService.database;
    return await db.insert(
      'supplies',
      supply.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateSupply(Supply supply) async {
    final db = await DatabaseService.database;
    return await db.update(
      'supplies',
      supply.toMap(),
      where: 'id = ?',
      whereArgs: [supply.id],
    );
  }

  Future<int> updateQuantity(int id, int newQuantity) async {
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      'supplies',
      {
        'quantity': newQuantity,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> adjustQuantity(int id, int adjustment) async {
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();
    
    // Get current quantity
    final maps = await db.query(
      'supplies',
      columns: ['quantity'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return 0;
    
    final currentQuantity = maps.first['quantity'] as int;
    final newQuantity = (currentQuantity + adjustment).clamp(0, double.infinity).toInt();
    
    return await db.update(
      'supplies',
      {
        'quantity': newQuantity,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSupply(int id) async {
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();
    
    // Soft delete by setting is_active to false
    return await db.update(
      'supplies',
      {
        'is_active': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Supply>> getLowStockSupplies() async {
    final db = await DatabaseService.database;
    final maps = await db.rawQuery('''
      SELECT * FROM supplies 
      WHERE is_active = 1 
      AND reorder_level IS NOT NULL 
      AND quantity <= reorder_level 
      ORDER BY quantity ASC
    ''');
    
    return List.generate(maps.length, (i) => Supply.fromMap(maps[i]));
  }

  Future<List<Supply>> getExpiringSupplies(int daysAhead) async {
    final db = await DatabaseService.database;
    final futureDate = DateTime.now().add(Duration(days: daysAhead));
    
    final maps = await db.query(
      'supplies',
      where: 'is_active = 1 AND expiration_date IS NOT NULL AND expiration_date <= ? AND expiration_date > ?',
      whereArgs: [futureDate.toIso8601String(), DateTime.now().toIso8601String()],
      orderBy: 'expiration_date ASC',
    );
    
    return List.generate(maps.length, (i) => Supply.fromMap(maps[i]));
  }

  Future<List<Supply>> searchSupplies(String query) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'supplies',
      where: 'is_active = 1 AND (name LIKE ? OR brand LIKE ? OR size LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) => Supply.fromMap(maps[i]));
  }
}
