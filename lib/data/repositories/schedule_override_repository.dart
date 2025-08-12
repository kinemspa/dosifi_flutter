import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:dosifi_flutter/core/services/database_service.dart';
import 'package:dosifi_flutter/data/models/schedule_override.dart';

class ScheduleOverrideRepository {
  Future<Database> get _db async => await DatabaseService.database;

  Future<int> upsertOverride(ScheduleOverride override) async {
    final db = await _db;
    // Try update first
    final count = await db.update(
      'schedule_overrides',
      override.toMap(),
      where: 'schedule_id = ? AND date = ?',
      whereArgs: [override.scheduleId, _isoDate(override.date)],
    );
    if (count > 0) return count;

    return await db.insert('schedule_overrides', override.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteOverride(int id) async {
    final db = await _db;
    return await db.delete('schedule_overrides', where: 'id = ?', whereArgs: [id]);
  }

  Future<ScheduleOverride?> getOverrideForDate(int scheduleId, DateTime date) async {
    final db = await _db;
    final maps = await db.query(
      'schedule_overrides',
      where: 'schedule_id = ? AND date = ?',
      whereArgs: [scheduleId, _isoDate(date)],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ScheduleOverride.fromMap(maps.first);
  }

  Future<List<ScheduleOverride>> getOverridesInRange(int scheduleId, DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'schedule_overrides',
      where: 'schedule_id = ? AND date >= ? AND date < ?',
      whereArgs: [scheduleId, _isoDate(start), _isoDate(end)],
      orderBy: 'date ASC',
    );
    return maps.map(ScheduleOverride.fromMap).toList();
  }
}

String _isoDate(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();
