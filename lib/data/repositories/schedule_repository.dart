import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../core/services/database_service.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  Future<Database> get _db async => await DatabaseService.database;

  // Create
  Future<int> insertSchedule(Schedule schedule) async {
    final db = await _db;
    return await db.insert('schedules', schedule.toMap());
  }

  // Read
  Future<List<Schedule>> getAllSchedules() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      orderBy: 'time_of_day ASC',
    );
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  Future<Schedule?> getScheduleById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Schedule.fromMap(maps.first);
  }

  Future<List<Schedule>> getActiveSchedules() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'time_of_day ASC',
    );
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  Future<List<Schedule>> getSchedulesForMedication(int medicationId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'medication_id = ? AND is_active = ?',
      whereArgs: [medicationId, 1],
      orderBy: 'time_of_day ASC',
    );
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  // Update
  Future<int> updateSchedule(Schedule schedule) async {
    final db = await _db;
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deactivateSchedule(int id) async {
    final db = await _db;
    return await db.update(
      'schedules',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete
  Future<int> deleteSchedule(int id) async {
    final db = await _db;
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Additional methods for schedule provider
  Future<List<Schedule>> getSchedulesByMedication(int medicationId) async {
    return getSchedulesForMedication(medicationId);
  }

  Future<void> updateScheduleStatus(int id, bool isActive) async {
    final db = await _db;
    await db.update(
      'schedules',
      {'is_active': isActive ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

