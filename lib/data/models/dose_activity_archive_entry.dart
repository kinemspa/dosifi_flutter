import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class DoseActivityArchiveEntry {
  final int? id;
  final String eventType; // taken | skipped | missed | edited | deleted
  final DateTime occurredAt;
  final int? scheduleId;
  final int? medicationId;
  final Map<String, dynamic>? medicationSnapshot;
  final Map<String, dynamic>? scheduleSnapshot;
  final Map<String, dynamic>? userContext;
  final String? notes;
  final String actor; // system | user

  const DoseActivityArchiveEntry({
    this.id,
    required this.eventType,
    required this.occurredAt,
    this.scheduleId,
    this.medicationId,
    this.medicationSnapshot,
    this.scheduleSnapshot,
    this.userContext,
    this.notes,
    this.actor = 'system',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_type': eventType,
      'occurred_at': occurredAt.toIso8601String(),
      'schedule_id': scheduleId,
      'medication_id': medicationId,
      'medication_snapshot': medicationSnapshot != null ? jsonEncode(medicationSnapshot) : null,
      'schedule_snapshot': scheduleSnapshot != null ? jsonEncode(scheduleSnapshot) : null,
      'user_context': userContext != null ? jsonEncode(userContext) : null,
      'notes': notes,
      'actor': actor,
    };
  }
}

