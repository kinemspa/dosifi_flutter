import 'package:flutter/foundation.dart';

@immutable
class Schedule {
  final int? id;
  final int medicationId;
  final String scheduleType;
  final String timeOfDay;
  final List<int>? daysOfWeek;
  final DateTime startDate;
  final DateTime? endDate;
  final int? cycleDaysOn;
  final int? cycleDaysOff;
  final double doseAmount;
  final String doseUnit;
  final String doseForm;
  final double strengthPerUnit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Schedule({
    this.id,
    required this.medicationId,
    required this.scheduleType,
    required this.timeOfDay,
    this.daysOfWeek,
    required this.startDate,
    this.endDate,
    this.cycleDaysOn,
    this.cycleDaysOff,
    required this.doseAmount,
    required this.doseUnit,
    required this.doseForm,
    required this.strengthPerUnit,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.create({
    required int medicationId,
    required String scheduleType,
    required String timeOfDay,
    List<int>? daysOfWeek,
    required DateTime startDate,
    DateTime? endDate,
    int? cycleDaysOn,
    int? cycleDaysOff,
    required double doseAmount,
    required String doseUnit,
    required String doseForm,
    required double strengthPerUnit,
  }) {
    final now = DateTime.now();
    return Schedule(
      medicationId: medicationId,
      scheduleType: scheduleType,
      timeOfDay: timeOfDay,
      daysOfWeek: daysOfWeek,
      startDate: startDate,
      endDate: endDate,
      cycleDaysOn: cycleDaysOn,
      cycleDaysOff: cycleDaysOff,
      doseAmount: doseAmount,
      doseUnit: doseUnit,
      doseForm: doseForm,
      strengthPerUnit: strengthPerUnit,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'schedule_type': scheduleType,
      'time_of_day': timeOfDay,
      'days_of_week': daysOfWeek?.join(','),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'cycle_days_on': cycleDaysOn,
      'cycle_days_off': cycleDaysOff,
      'dose_amount': doseAmount,
      'dose_unit': doseUnit,
      'dose_form': doseForm,
      'strength_per_unit': strengthPerUnit,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      scheduleType: map['schedule_type'] as String,
      timeOfDay: map['time_of_day'] as String,
      daysOfWeek: map['days_of_week'] != null
          ? (map['days_of_week'] as String)
              .split(',')
              .map((e) => int.parse(e))
              .toList()
          : null,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null 
          ? DateTime.parse(map['end_date'] as String)
          : null,
      cycleDaysOn: map['cycle_days_on'] as int?,
      cycleDaysOff: map['cycle_days_off'] as int?,
      doseAmount: (map['dose_amount'] as num).toDouble(),
      doseUnit: map['dose_unit'] as String,
      doseForm: map['dose_form'] as String,
      strengthPerUnit: (map['strength_per_unit'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Schedule copyWith({
    int? id,
    int? medicationId,
    String? scheduleType,
    String? timeOfDay,
    List<int>? daysOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    int? cycleDaysOn,
    int? cycleDaysOff,
    double? doseAmount,
    String? doseUnit,
    String? doseForm,
    double? strengthPerUnit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduleType: scheduleType ?? this.scheduleType,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleDaysOn: cycleDaysOn ?? this.cycleDaysOn,
      cycleDaysOff: cycleDaysOff ?? this.cycleDaysOff,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      doseForm: doseForm ?? this.doseForm,
      strengthPerUnit: strengthPerUnit ?? this.strengthPerUnit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper method to check if schedule is active on a specific date
  bool isActiveOnDate(DateTime date) {
    if (!isActive) return false;
    
    // Check if date is within schedule range
    if (date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    
    // Check for cycling schedules
    if (scheduleType == ScheduleType.cycling.name && 
        cycleDaysOn != null && 
        cycleDaysOff != null) {
      final daysSinceStart = date.difference(startDate).inDays;
      final cycleLength = cycleDaysOn! + cycleDaysOff!;
      final dayInCycle = daysSinceStart % cycleLength;
      return dayInCycle < cycleDaysOn!;
    }
    
    // Check for weekly schedules
    if (scheduleType == ScheduleType.weekly.name && daysOfWeek != null) {
      return daysOfWeek!.contains(date.weekday);
    }
    
    // Daily and other types are active every day
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Schedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Schedule types enum
enum ScheduleType {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  cycling('Cycling'),
  asNeeded('As Needed'),
  custom('Custom');

  final String displayName;
  const ScheduleType(this.displayName);

  static ScheduleType fromString(String type) {
    return ScheduleType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ScheduleType.daily,
    );
  }
}
