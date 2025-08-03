import 'package:sqflite/sqflite.dart';
import '../../core/services/database_service.dart';
import '../models/inventory.dart';

class InventoryRepository {
  Future<List<Inventory>> getAllInventory() async {
    final db = await DatabaseService.database;
    final maps = await db.query('inventory', orderBy: 'id DESC');
    
    return List.generate(maps.length, (i) {
      return Inventory(
        id: maps[i]['id'] as int?,
        medicationId: maps[i]['medication_id'] as int,
        quantity: maps[i]['quantity'] as double,
        unit: maps[i]['unit'] as String,
        reorderLevel: maps[i]['reorder_level'] as double?,
        batchNumber: maps[i]['batch_number'] as String?,
        expiryDate: maps[i]['expiry_date'] != null 
            ? DateTime.parse(maps[i]['expiry_date'] as String)
            : null,
        location: maps[i]['location'] as String?,
        notes: maps[i]['notes'] as String?,
        createdAt: maps[i]['created_at'] != null
            ? DateTime.parse(maps[i]['created_at'] as String)
            : null,
        updatedAt: maps[i]['updated_at'] != null
            ? DateTime.parse(maps[i]['updated_at'] as String)
            : null,
      );
    });
  }

  Future<List<Inventory>> getInventoryByMedication(int medicationId) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'inventory',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'id DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Inventory(
        id: maps[i]['id'] as int?,
        medicationId: maps[i]['medication_id'] as int,
        quantity: maps[i]['quantity'] as double,
        unit: maps[i]['unit'] as String,
        reorderLevel: maps[i]['reorder_level'] as double?,
        batchNumber: maps[i]['batch_number'] as String?,
        expiryDate: maps[i]['expiry_date'] != null 
            ? DateTime.parse(maps[i]['expiry_date'] as String)
            : null,
        location: maps[i]['location'] as String?,
        notes: maps[i]['notes'] as String?,
        createdAt: maps[i]['created_at'] != null
            ? DateTime.parse(maps[i]['created_at'] as String)
            : null,
        updatedAt: maps[i]['updated_at'] != null
            ? DateTime.parse(maps[i]['updated_at'] as String)
            : null,
      );
    });
  }

  Future<Inventory?> getInventoryById(int id) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'inventory',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return Inventory(
        id: maps[0]['id'] as int?,
        medicationId: maps[0]['medication_id'] as int,
        quantity: maps[0]['quantity'] as double,
        unit: maps[0]['unit'] as String,
        reorderLevel: maps[0]['reorder_level'] as double?,
        batchNumber: maps[0]['batch_number'] as String?,
        expiryDate: maps[0]['expiry_date'] != null 
            ? DateTime.parse(maps[0]['expiry_date'] as String)
            : null,
        location: maps[0]['location'] as String?,
        notes: maps[0]['notes'] as String?,
        createdAt: maps[0]['created_at'] != null
            ? DateTime.parse(maps[0]['created_at'] as String)
            : null,
        updatedAt: maps[0]['updated_at'] != null
            ? DateTime.parse(maps[0]['updated_at'] as String)
            : null,
      );
    }
    return null;
  }

  Future<int> insertInventory(Inventory inventory) async {
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();
    
    final Map<String, dynamic> inventoryMap = {
      'medication_id': inventory.medicationId,
      'quantity': inventory.quantity,
      'unit': inventory.unit,
      'reorder_level': inventory.reorderLevel,
      'batch_number': inventory.batchNumber,
      'expiry_date': inventory.expiryDate?.toIso8601String(),
      'location': inventory.location,
      'notes': inventory.notes,
      'created_at': now,
      'updated_at': now,
    };
    
    return await db.insert(
      'inventory',
      inventoryMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateInventory(Inventory inventory) async {
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();
    
    final Map<String, dynamic> inventoryMap = {
      'medication_id': inventory.medicationId,
      'quantity': inventory.quantity,
      'unit': inventory.unit,
      'reorder_level': inventory.reorderLevel,
      'batch_number': inventory.batchNumber,
      'expiry_date': inventory.expiryDate?.toIso8601String(),
      'location': inventory.location,
      'notes': inventory.notes,
      'updated_at': now,
    };
    
    return await db.update(
      'inventory',
      inventoryMap,
      where: 'id = ?',
      whereArgs: [inventory.id],
    );
  }

  Future<int> updateQuantity(int id, double newQuantity) async {
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      'inventory',
      {
        'quantity': newQuantity,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInventory(int id) async {
    final db = await DatabaseService.database;
    return await db.delete(
      'inventory',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInventoryByMedication(int medicationId) async {
    final db = await DatabaseService.database;
    return await db.delete(
      'inventory',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
    );
  }

  Future<List<Inventory>> getLowStockInventory() async {
    final db = await DatabaseService.database;
    final maps = await db.rawQuery('''
      SELECT * FROM inventory 
      WHERE reorder_level IS NOT NULL 
      AND quantity <= reorder_level 
      ORDER BY quantity ASC
    ''');
    
    return List.generate(maps.length, (i) {
      return Inventory(
        id: maps[i]['id'] as int?,
        medicationId: maps[i]['medication_id'] as int,
        quantity: maps[i]['quantity'] as double,
        unit: maps[i]['unit'] as String,
        reorderLevel: maps[i]['reorder_level'] as double?,
        batchNumber: maps[i]['batch_number'] as String?,
        expiryDate: maps[i]['expiry_date'] != null 
            ? DateTime.parse(maps[i]['expiry_date'] as String)
            : null,
        location: maps[i]['location'] as String?,
        notes: maps[i]['notes'] as String?,
        createdAt: maps[i]['created_at'] != null
            ? DateTime.parse(maps[i]['created_at'] as String)
            : null,
        updatedAt: maps[i]['updated_at'] != null
            ? DateTime.parse(maps[i]['updated_at'] as String)
            : null,
      );
    });
  }

  Future<List<Inventory>> getExpiringInventory(int daysAhead) async {
    final db = await DatabaseService.database;
    final futureDate = DateTime.now().add(Duration(days: daysAhead));
    
    final maps = await db.query(
      'inventory',
      where: 'expiry_date IS NOT NULL AND expiry_date <= ? AND expiry_date > ?',
      whereArgs: [futureDate.toIso8601String(), DateTime.now().toIso8601String()],
      orderBy: 'expiry_date ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Inventory(
        id: maps[i]['id'] as int?,
        medicationId: maps[i]['medication_id'] as int,
        quantity: maps[i]['quantity'] as double,
        unit: maps[i]['unit'] as String,
        reorderLevel: maps[i]['reorder_level'] as double?,
        batchNumber: maps[i]['batch_number'] as String?,
        expiryDate: maps[i]['expiry_date'] != null 
            ? DateTime.parse(maps[i]['expiry_date'] as String)
            : null,
        location: maps[i]['location'] as String?,
        notes: maps[i]['notes'] as String?,
        createdAt: maps[i]['created_at'] != null
            ? DateTime.parse(maps[i]['created_at'] as String)
            : null,
        updatedAt: maps[i]['updated_at'] != null
            ? DateTime.parse(maps[i]['updated_at'] as String)
            : null,
      );
    });
  }
}
