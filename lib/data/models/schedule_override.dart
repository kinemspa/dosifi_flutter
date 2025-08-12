import 'package:flutter/foundation.dart';

@immutable
class ScheduleOverride {
  final int? id;
  final int scheduleId;
  final DateTime date; // date-only component
  final String? timeOfDay; // HH:mm
  final double? doseAmount;
  final String? doseUnit;
  final bool isCancelled;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleOverride({
    this.id,
    required this.scheduleId,
    required this.date,
    this.timeOfDay,
    this.doseAmount,
    this.doseUnit,
    this.isCancelled = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleOverride.create({
    required int scheduleId,
    required DateTime date,
    String? timeOfDay,
    double? doseAmount,
    String? doseUnit,
    bool isCancelled = false,
    String? notes,
  }) {
    final now = DateTime.now();
    final onlyDate = DateTime(date.year, date.month, date.day);
    return ScheduleOverride(
      scheduleId: scheduleId,
      date: onlyDate,
      timeOfDay: timeOfDay,
      doseAmount: doseAmount,
      doseUnit: doseUnit,
      isCancelled: isCancelled,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'date': _isoDate(date),
      'time_of_day': timeOfDay,
      'dose_amount': doseAmount,
      'dose_unit': doseUnit,
      'is_cancelled': isCancelled ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ScheduleOverride.fromMap(Map<String, dynamic> map) {
    return ScheduleOverride(
      id: map['id'] as int?,
      scheduleId: map['schedule_id'] as int,
      date: DateTime.parse(map['date'] as String),
      timeOfDay: map['time_of_day'] as String?,
      doseAmount: (map['dose_amount'] as num?)?.toDouble(),
      doseUnit: map['dose_unit'] as String?,
      isCancelled: (map['is_cancelled'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ScheduleOverride copyWith({
    int? id,
    int? scheduleId,
    DateTime? date,
    String? timeOfDay,
    double? doseAmount,
    String? doseUnit,
    bool? isCancelled,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleOverride(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      date: date ?? this.date,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      isCancelled: isCancelled ?? this.isCancelled,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

String _isoDate(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();
