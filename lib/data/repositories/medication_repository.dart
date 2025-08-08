import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:dosifi_flutter/core/services/database_service.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';

class MedicationRepository {
  Future<Database> get _db async => await DatabaseService.database;

  // Create
  Future<int> insertMedication(Medication medication) async {
    final db = await _db;
    return await db.insert('medications', medication.toMap());
  }

  // Read
  Future<List<Medication>> getAllMedications() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<List<Medication>> getActiveMedications() async {
    print('💾 [REPO DEBUG] getActiveMedications() called');
    final db = await _db;
    print('💾 [REPO DEBUG] Database connection established');
    
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    print('💾 [REPO DEBUG] Query returned ${maps.length} raw records');
    if (maps.isNotEmpty) {
      print('💾 [REPO DEBUG] First record: ${maps.first}');
    }
    
    final medications = List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
    print('💾 [REPO DEBUG] Converted to ${medications.length} Medication objects');
    return medications;
  }

  Future<Medication?> getMedicationById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Medication.fromMap(maps.first);
  }

  Future<List<Medication>> searchMedications(String query) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'name LIKE ? OR notes LIKE ? OR barcode = ?',
      whereArgs: ['%$query%', '%$query%', query],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<List<Medication>> getMedicationsByType(String type) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'type = ? AND is_active = ?',
      whereArgs: [type, 1],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<List<Medication>> getExpiringMedications(int daysAhead) async {
    final db = await _db;
    final expiryDate = DateTime.now().add(Duration(days: daysAhead));
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'expiry_date <= ? AND expiry_date IS NOT NULL AND is_active = ?',
      whereArgs: [expiryDate.toIso8601String(), 1],
      orderBy: 'expiry_date ASC',
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  // Update
  Future<int> updateMedication(Medication medication) async {
    final db = await _db;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deactivateMedication(int id) async {
    final db = await _db;
    return await db.update(
      'medications',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete
  Future<int> deleteMedication(int id) async {
    final db = await _db;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get medication with related data
  Future<Map<String, dynamic>?> getMedicationWithDetails(int id) async {
    final medication = await getMedicationById(id);
    if (medication == null) return null;

    final db = await _db;
    
    // Get schedules
    final scheduleMaps = await db.query(
      'schedules',
      where: 'medication_id = ? AND is_active = ?',
      whereArgs: [id, 1],
      orderBy: 'time_of_day ASC',
    );
    final schedules = scheduleMaps.map((map) => Schedule.fromMap(map)).toList();

    return {
      'medication': medication,
      'schedules': schedules,
    };
  }

  // Stock management methods
  Future<int> updateMedicationStock(int medicationId, double newStockQuantity) async {
    final db = await _db;
    return await db.update(
      'medications',
      {
        'stock_quantity': newStockQuantity.clamp(0.0, double.infinity),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [medicationId],
    );
  }

  Future<int> adjustMedicationStock(int medicationId, double adjustment) async {
    final db = await _db;
    
    return await db.transaction((txn) async {
      // Get current stock
      final medicationMaps = await txn.query(
        'medications',
        columns: ['stock_quantity'],
        where: 'id = ?',
        whereArgs: [medicationId],
      );
      
      if (medicationMaps.isEmpty) {
        throw Exception('Medication not found');
      }
      
      final currentStock = (medicationMaps.first['stock_quantity'] as num?)?.toDouble() ?? 0.0;
      final newStock = (currentStock + adjustment).clamp(0.0, double.infinity);
      
      // Update stock
      return await txn.update(
        'medications',
        {
          'stock_quantity': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [medicationId],
      );
    });
  }

  Future<double?> getMedicationStock(int medicationId) async {
    final db = await _db;
    final result = await db.query(
      'medications',
      columns: ['stock_quantity'],
      where: 'id = ?',
      whereArgs: [medicationId],
    );
    
    if (result.isEmpty) return null;
    return (result.first['stock_quantity'] as num?)?.toDouble();
  }

  Future<List<Medication>> getLowStockMedications({double threshold = 5.0}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'stock_quantity <= ? AND is_active = ? AND alert_on_low_stock = ?',
      whereArgs: [threshold, 1, 1],
      orderBy: 'stock_quantity ASC',
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  // Batch operations
  Future<void> insertMedicationBatch(List<Medication> medications) async {
    final db = await _db;
    final batch = db.batch();
    
    for (final medication in medications) {
      batch.insert('medications', medication.toMap());
    }
    
    await batch.commit(noResult: true);
  }
}
