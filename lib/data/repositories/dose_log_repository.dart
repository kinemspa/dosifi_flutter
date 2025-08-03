import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../core/services/database_service.dart';
import '../models/dose_log.dart';

class DoseLogRepository {
  Future<Database> get _db async => await DatabaseService.database;

  // Create
  Future<int> insertDoseLog(DoseLog doseLog) async {
    final db = await _db;
    return await db.insert('dose_logs', doseLog.toMap());
  }

  // Read
  Future<List<DoseLog>> getAllDoseLogs() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      orderBy: 'scheduled_time DESC',
    );
    return List.generate(maps.length, (i) => DoseLog.fromMap(maps[i]));
  }

  Future<DoseLog?> getDoseLogById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DoseLog.fromMap(maps.first);
  }

  Future<List<DoseLog>> getDoseLogsForMedication(int medicationId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'scheduled_time DESC',
    );
    return List.generate(maps.length, (i) => DoseLog.fromMap(maps[i]));
  }

  Future<List<DoseLog>> getDoseLogsForSchedule(int scheduleId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
      orderBy: 'scheduled_time DESC',
    );
    return List.generate(maps.length, (i) => DoseLog.fromMap(maps[i]));
  }

  Future<List<DoseLog>> getDoseLogsForDate(DateTime date) async {
    final db = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      where: 'scheduled_time >= ? AND scheduled_time < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return List.generate(maps.length, (i) => DoseLog.fromMap(maps[i]));
  }

  Future<List<DoseLog>> getTodaysDoseLogs() async {
    return getDoseLogsForDate(DateTime.now());
  }

  Future<List<DoseLog>> getPendingDoseLogs() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      where: 'status = ?',
      whereArgs: [DoseStatus.pending.name],
      orderBy: 'scheduled_time ASC',
    );
    return List.generate(maps.length, (i) => DoseLog.fromMap(maps[i]));
  }

  Future<List<DoseLog>> getOverdueDoseLogs() async {
    final db = await _db;
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      where: 'status = ? AND scheduled_time < ?',
      whereArgs: [DoseStatus.pending.name, oneHourAgo.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return List.generate(maps.length, (i) => DoseLog.fromMap(maps[i]));
  }

  Future<List<DoseLog>> getDoseLogsInRange(DateTime startDate, DateTime endDate) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'dose_logs',
      where: 'scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return List.generate(maps.length, (i) => DoseLog.fromMap(maps[i]));
  }

  // Update
  Future<int> updateDoseLog(DoseLog doseLog) async {
    final db = await _db;
    return await db.update(
      'dose_logs',
      doseLog.toMap(),
      where: 'id = ?',
      whereArgs: [doseLog.id],
    );
  }

  Future<int> markDoseAsTaken(int id, {DateTime? takenTime, double? doseAmount, String? notes}) async {
    final db = await _db;
    return await db.update(
      'dose_logs',
      {
        'status': DoseStatus.taken.name,
        'taken_time': (takenTime ?? DateTime.now()).toIso8601String(),
        if (doseAmount != null) 'dose_amount': doseAmount,
        if (notes != null) 'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markDoseAsSkipped(int id, {String? notes}) async {
    final db = await _db;
    return await db.update(
      'dose_logs',
      {
        'status': DoseStatus.skipped.name,
        if (notes != null) 'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markDoseAsMissed(int id) async {
    final db = await _db;
    return await db.update(
      'dose_logs',
      {'status': DoseStatus.missed.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete
  Future<int> deleteDoseLog(int id) async {
    final db = await _db;
    return await db.delete(
      'dose_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDoseLogsForSchedule(int scheduleId) async {
    final db = await _db;
    return await db.delete(
      'dose_logs',
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
    );
  }

  // Analytics methods
  Future<Map<String, int>> getDoseComplianceStats(int medicationId, DateTime startDate, DateTime endDate) async {
    final db = await _db;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM dose_logs
      WHERE medication_id = ? AND scheduled_time >= ? AND scheduled_time <= ?
      GROUP BY status
    ''', [medicationId, startDate.toIso8601String(), endDate.toIso8601String()]);

    final stats = <String, int>{
      'taken': 0,
      'missed': 0,
      'skipped': 0,
      'pending': 0,
    };

    for (final result in results) {
      final status = result['status'] ?? '';
      final count = int.tryParse(result['count'] ?? '0') ?? 0;
      stats[status] = count;
    }

    return stats;
  }

  Future<double> getComplianceRate(int medicationId, DateTime startDate, DateTime endDate) async {
    final stats = await getDoseComplianceStats(medicationId, startDate, endDate);
    final total = stats.values.reduce((a, b) => a + b);
    if (total == 0) return 0.0;
    
    final taken = stats['taken'] ?? 0;
    return (taken / total) * 100;
  }
}
