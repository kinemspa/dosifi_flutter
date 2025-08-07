import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../data/models/schedule.dart';
import '../../data/models/dose_log.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/dose_log_repository.dart';

/// Service responsible for automated dose log generation from schedules
/// and management of dose scheduling operations
class DoseSchedulingService {
  final ScheduleRepository _scheduleRepository;
  final DoseLogRepository _doseLogRepository;

  DoseSchedulingService({
    required ScheduleRepository scheduleRepository,
    required DoseLogRepository doseLogRepository,
  }) : _scheduleRepository = scheduleRepository,
       _doseLogRepository = doseLogRepository;

  /// Generate dose logs from active schedules for a specific date range
  Future<void> generateDoseLogsForDateRange(DateTime startDate, DateTime endDate) async {
    debugPrint('🕐 Generating dose logs from $startDate to $endDate');
    
    final schedules = await _scheduleRepository.getActiveSchedules();
    final existingLogs = await _doseLogRepository.getDoseLogsInRange(startDate, endDate);
    
    // Create a set of existing log identifiers to avoid duplicates
    final existingLogKeys = existingLogs.map((log) => 
      '${log.medicationId}_${log.scheduledTime.toIso8601String()}'
    ).toSet();
    
    final logsToCreate = <DoseLog>[];
    
    for (final schedule in schedules) {
      final scheduledTimes = _calculateScheduledTimesForDateRange(
        schedule, 
        startDate, 
        endDate
      );
      
      for (final scheduledTime in scheduledTimes) {
        final logKey = '${schedule.medicationId}_${scheduledTime.toIso8601String()}';
        
        // Only create if it doesn't already exist
        if (!existingLogKeys.contains(logKey)) {
          final doseLog = DoseLog.create(
            medicationId: schedule.medicationId,
            scheduleId: schedule.id,
            scheduledTime: scheduledTime,
            status: DoseStatus.pending,
            doseAmount: schedule.doseAmount,
          );
          
          logsToCreate.add(doseLog);
        }
      }
    }
    
    // Batch insert the new dose logs
    for (final log in logsToCreate) {
      await _doseLogRepository.insertDoseLog(log);
    }
    
    debugPrint('🕐 Created ${logsToCreate.length} dose logs');
  }

  /// Generate dose logs for today if they don't exist
  Future<void> generateTodaysDoseLogs() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    await generateDoseLogsForDateRange(startOfDay, endOfDay);
  }

  /// Generate dose logs for the next week to ensure they're always available
  Future<void> generateUpcomingDoseLogs() async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 7));
    
    await generateDoseLogsForDateRange(now, endDate);
  }

  /// Calculate scheduled times for a schedule within a date range
  List<DateTime> _calculateScheduledTimesForDateRange(
    Schedule schedule, 
    DateTime startDate, 
    DateTime endDate
  ) {
    final scheduledTimes = <DateTime>[];
    final timeParts = schedule.timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    
    while (currentDate.isBefore(endDate)) {
      if (schedule.isActiveOnDate(currentDate)) {
        final scheduledTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          hour,
          minute,
        );
        scheduledTimes.add(scheduledTime);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return scheduledTimes;
  }

  /// Snooze a dose for a specified duration
  Future<DoseLog> snoozeDose(int doseLogId, Duration snoozeDuration) async {
    final doseLog = await _doseLogRepository.getDoseLogById(doseLogId);
    if (doseLog == null) {
      throw Exception('Dose log not found');
    }
    
    // Create a new dose log with the snoozed time
    final snoozedTime = DateTime.now().add(snoozeDuration);
    final snoozedLog = DoseLog.create(
      medicationId: doseLog.medicationId,
      scheduleId: doseLog.scheduleId,
      scheduledTime: snoozedTime,
      status: DoseStatus.pending,
      doseAmount: doseLog.doseAmount,
      notes: 'Snoozed from ${DateFormat('HH:mm').format(doseLog.scheduledTime)}',
    );
    
    // Mark the original as skipped
    await _doseLogRepository.markDoseAsSkipped(doseLogId, notes: 'Snoozed');
    
    // Insert the new snoozed dose
    final newId = await _doseLogRepository.insertDoseLog(snoozedLog);
    return snoozedLog.copyWith(id: newId);
  }

  /// Take a dose and handle inventory deduction
  Future<void> takeDose(int doseLogId, {double? actualDoseAmount, String? notes}) async {
    await _doseLogRepository.markDoseAsTaken(
      doseLogId,
      takenTime: DateTime.now(),
      doseAmount: actualDoseAmount,
      notes: notes,
    );
  }

  /// Skip a dose with optional reason
  Future<void> skipDose(int doseLogId, {String? reason}) async {
    await _doseLogRepository.markDoseAsSkipped(doseLogId, notes: reason);
  }

  /// Get overdue doses (more than 1 hour past scheduled time)
  Future<List<DoseLog>> getOverdueDoses() async {
    return await _doseLogRepository.getOverdueDoseLogs();
  }

  /// Mark overdue pending doses as missed
  Future<void> markOverdueDosesAsMissed() async {
    final overdueDoses = await getOverdueDoses();
    
    for (final dose in overdueDoses) {
      if (dose.status == DoseStatus.pending && dose.id != null) {
        await _doseLogRepository.markDoseAsMissed(dose.id!);
      }
    }
    
    debugPrint('🚨 Marked ${overdueDoses.length} doses as missed');
  }

  /// Calculate medication forecasting based on current usage
  Future<Map<int, int>> calculateMedicationForecast(int medicationId, int days) async {
    final endDate = DateTime.now().add(Duration(days: days));
    final schedules = await _scheduleRepository.getSchedulesForMedication(medicationId);
    
    int totalDosesNeeded = 0;
    final now = DateTime.now();
    
    for (final schedule in schedules) {
      final scheduledTimes = _calculateScheduledTimesForDateRange(schedule, now, endDate);
      totalDosesNeeded += scheduledTimes.length;
    }
    
    return {medicationId: totalDosesNeeded};
  }

  /// Get compliance rate for a medication over a date range
  Future<double> getComplianceRate(int medicationId, DateTime startDate, DateTime endDate) async {
    return await _doseLogRepository.getComplianceRate(medicationId, startDate, endDate);
  }

  /// Get dose statistics for analytics
  Future<Map<String, int>> getDoseStatistics(int medicationId, DateTime startDate, DateTime endDate) async {
    return await _doseLogRepository.getDoseComplianceStats(medicationId, startDate, endDate);
  }

  /// Clean up old dose logs (older than specified days)
  Future<void> cleanupOldDoseLogs({int daysToKeep = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    // Get logs to delete first
    final logsToDelete = await _doseLogRepository.getDoseLogsInRange(
      DateTime.fromMillisecondsSinceEpoch(0), 
      cutoffDate
    );
    
    // Delete each log
    for (final log in logsToDelete) {
      if (log.id != null) {
        await _doseLogRepository.deleteDoseLog(log.id!);
      }
    }
    
    debugPrint('🧹 Cleaned up ${logsToDelete.length} dose logs older than $daysToKeep days');
  }

}
