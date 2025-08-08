import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_flutter/data/repositories/dose_log_repository.dart';
import 'package:dosifi_flutter/data/models/dose_log.dart';
import 'package:dosifi_flutter/data/models/medication.dart';

// Provider for dose log repository
final doseLogRepositoryProvider = Provider<DoseLogRepository>((ref) {
  return DoseLogRepository();
});

// Provider for all dose logs
final doseLogListProvider = FutureProvider<List<DoseLog>>((ref) async {
  final repository = ref.read(doseLogRepositoryProvider);
  return repository.getAllDoseLogs();
});

// Provider for dose logs in a date range
final doseLogsInRangeProvider = FutureProvider.family<List<DoseLog>, DateRange>((ref, dateRange) async {
  final repository = ref.read(doseLogRepositoryProvider);
  return repository.getDoseLogsInRange(dateRange.start, dateRange.end);
});

// Provider for adherence statistics
final adherenceStatsProvider = FutureProvider.family<AdherenceStats, DateRange>((ref, dateRange) async {
  final repository = ref.read(doseLogRepositoryProvider);
  final doseLogs = await repository.getDoseLogsInRange(dateRange.start, dateRange.end);
  
  int taken = 0;
  int missed = 0;
  int skipped = 0;
  int pending = 0;
  
  for (final log in doseLogs) {
    switch (log.status) {
      case DoseStatus.taken:
        taken++;
        break;
      case DoseStatus.missed:
        missed++;
        break;
      case DoseStatus.skipped:
        skipped++;
        break;
      case DoseStatus.pending:
        pending++;
        break;
    }
  }
  
  final total = taken + missed + skipped + pending;
  final adherenceRate = total > 0 ? (taken / total * 100) : 0.0;
  
  return AdherenceStats(
    taken: taken,
    missed: missed,
    skipped: skipped,
    pending: pending,
    total: total,
    adherenceRate: adherenceRate,
  );
});

// Provider for medication-specific adherence
// Note: This should use a medication repository instead of dose log list
// For now, returning empty list to prevent compilation error
final medicationAdherenceProvider = FutureProvider.family<List<MedicationAdherence>, DateRange>((ref, dateRange) async {
  // TODO: Replace with actual medication repository when available
  return <MedicationAdherence>[];
  
  // final repository = ref.read(doseLogRepositoryProvider);
  // final medications = await ref.read(medicationListProvider.future); // Need medication provider
  // 
  // final adherenceList = <MedicationAdherence>[];
  // 
  // for (final medication in medications) {
  //   if (medication.id != null) {
  //     final stats = await repository.getDoseComplianceStats(
  //       medication.id!,
  //       dateRange.start,
  //       dateRange.end,
  //     );
  //     
  //     final taken = stats['taken'] ?? 0;
  //     final missed = stats['missed'] ?? 0;
  //     final skipped = stats['skipped'] ?? 0;
  //     final pending = stats['pending'] ?? 0;
  //     final total = taken + missed + skipped + pending;
  //     final adherenceRate = total > 0 ? (taken / total * 100) : 0.0;
  //     
  //     adherenceList.add(MedicationAdherence(
  //       medication: medication,
  //       taken: taken,
  //       missed: missed,
  //       skipped: skipped,
  //       pending: pending,
  //       total: total,
  //       adherenceRate: adherenceRate,
  //     ));
  //   }
  // }
  // 
  // return adherenceList;
});

// Provider for weekly adherence trend
final weeklyAdherenceTrendProvider = FutureProvider<List<WeeklyAdherence>>((ref) async {
  final repository = ref.read(doseLogRepositoryProvider);
  final weeks = <WeeklyAdherence>[];
  
  final now = DateTime.now();
  for (int i = 7; i >= 0; i--) {
    final weekStart = now.subtract(Duration(days: i * 7 + now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    final doseLogs = await repository.getDoseLogsInRange(weekStart, weekEnd);
    
    int taken = 0;
    final int total = doseLogs.length;
    
    for (final log in doseLogs) {
      if (log.status == DoseStatus.taken) {
        taken++;
      }
    }
    
    final adherenceRate = total > 0 ? (taken / total * 100) : 0.0;
    
    weeks.add(WeeklyAdherence(
      weekStart: weekStart,
      weekEnd: weekEnd,
      taken: taken,
      total: total,
      adherenceRate: adherenceRate,
    ));
  }
  
  return weeks;
});

// Data classes
class DateRange {
  final DateTime start;
  final DateTime end;
  
  const DateRange(this.start, this.end);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange &&
        other.start == start &&
        other.end == end;
  }
  
  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class AdherenceStats {
  final int taken;
  final int missed;
  final int skipped;
  final int pending;
  final int total;
  final double adherenceRate;
  
  const AdherenceStats({
    required this.taken,
    required this.missed,
    required this.skipped,
    required this.pending,
    required this.total,
    required this.adherenceRate,
  });
}

class MedicationAdherence {
  final Medication medication;
  final int taken;
  final int missed;
  final int skipped;
  final int pending;
  final int total;
  final double adherenceRate;
  
  const MedicationAdherence({
    required this.medication,
    required this.taken,
    required this.missed,
    required this.skipped,
    required this.pending,
    required this.total,
    required this.adherenceRate,
  });
}

class WeeklyAdherence {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int taken;
  final int total;
  final double adherenceRate;
  
  const WeeklyAdherence({
    required this.weekStart,
    required this.weekEnd,
    required this.taken,
    required this.total,
    required this.adherenceRate,
  });
}
