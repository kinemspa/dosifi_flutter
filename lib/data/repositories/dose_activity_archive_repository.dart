import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:dosifi_flutter/core/services/database_service.dart';
import 'package:dosifi_flutter/data/models/dose_activity_archive_entry.dart';

class DoseActivityArchiveRepository {
  Future<Database> get _db async => await DatabaseService.database;

  Future<int> insert(DoseActivityArchiveEntry entry) async {
    final db = await _db;
    return db.insert('dose_activity_archive', entry.toMap());
  }

  Future<int> insertRaw({
    required String eventType,
    required DateTime occurredAt,
    int? scheduleId,
    int? medicationId,
    Map<String, dynamic>? medicationSnapshot,
    Map<String, dynamic>? scheduleSnapshot,
    Map<String, dynamic>? userContext,
    String? notes,
    String actor = 'system',
  }) async {
    final entry = DoseActivityArchiveEntry(
      eventType: eventType,
      occurredAt: occurredAt,
      scheduleId: scheduleId,
      medicationId: medicationId,
      medicationSnapshot: medicationSnapshot,
      scheduleSnapshot: scheduleSnapshot,
      userContext: userContext,
      notes: notes,
      actor: actor,
    );
    return insert(entry);
  }

  Future<List<DoseActivityArchiveEntry>> getAll({int limit = 500, int offset = 0}) async {
    final db = await _db;
    final rows = await db.query(
      'dose_activity_archive',
      orderBy: 'occurred_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map((r) {
      return DoseActivityArchiveEntry(
        id: r['id'] as int?,
        eventType: r['event_type'] as String,
        occurredAt: DateTime.parse(r['occurred_at'] as String),
        scheduleId: r['schedule_id'] as int?,
        medicationId: r['medication_id'] as int?,
        medicationSnapshot: r['medication_snapshot'] != null
            ? jsonDecode(r['medication_snapshot'] as String) as Map<String, dynamic>
            : null,
        scheduleSnapshot: r['schedule_snapshot'] != null
            ? jsonDecode(r['schedule_snapshot'] as String) as Map<String, dynamic>
            : null,
        userContext:
            r['user_context'] != null ? jsonDecode(r['user_context'] as String) as Map<String, dynamic> : null,
        notes: r['notes'] as String?,
        actor: (r['actor'] as String?) ?? 'system',
      );
    }).toList();
  }
}

