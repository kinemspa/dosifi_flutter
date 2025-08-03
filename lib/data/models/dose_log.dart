import 'package:flutter/foundation.dart';

@immutable
class DoseLog {
  final int? id;
  final int medicationId;
  final int? scheduleId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final DoseStatus status;
  final double? doseAmount;
  final String? notes;
  final DateTime createdAt;

  const DoseLog({
    this.id,
    required this.medicationId,
    this.scheduleId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    this.doseAmount,
    this.notes,
    required this.createdAt,
  });

  factory DoseLog.create({
    required int medicationId,
    int? scheduleId,
    required DateTime scheduledTime,
    DateTime? takenTime,
    required DoseStatus status,
    double? doseAmount,
    String? notes,
  }) {
    return DoseLog(
      medicationId: medicationId,
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      takenTime: takenTime,
      status: status,
      doseAmount: doseAmount,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'schedule_id': scheduleId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime?.toIso8601String(),
      'status': status.name,
      'dose_amount': doseAmount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      scheduleId: map['schedule_id'] as int?,
      scheduledTime: DateTime.parse(map['scheduled_time'] as String),
      takenTime: map['taken_time'] != null
          ? DateTime.parse(map['taken_time'] as String)
          : null,
      status: DoseStatus.fromString(map['status'] as String),
      doseAmount: map['dose_amount'] as double?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DoseLog copyWith({
    int? id,
    int? medicationId,
    int? scheduleId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    DoseStatus? status,
    double? doseAmount,
    String? notes,
    DateTime? createdAt,
  }) {
    return DoseLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      doseAmount: doseAmount ?? this.doseAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isTaken => status == DoseStatus.taken;
  bool get isMissed => status == DoseStatus.missed;
  bool get isSkipped => status == DoseStatus.skipped;
  bool get isPending => status == DoseStatus.pending;
  bool get isOverdue => status == DoseStatus.pending && DateTime.now().isAfter(scheduledTime.add(const Duration(hours: 1)));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoseLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum DoseStatus {
  pending('Pending'),
  taken('Taken'),
  missed('Missed'),
  skipped('Skipped');

  final String displayName;
  const DoseStatus(this.displayName);

  static DoseStatus fromString(String status) {
    return DoseStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => DoseStatus.pending,
    );
  }
}
