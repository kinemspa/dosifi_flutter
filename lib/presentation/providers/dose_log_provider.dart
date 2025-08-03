import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dose_log.dart';
import '../../data/repositories/dose_log_repository.dart';

// Repository provider
final doseLogRepositoryProvider = Provider<DoseLogRepository>((ref) {
  return DoseLogRepository();
});

// State notifier for managing dose logs
class DoseLogListNotifier extends StateNotifier<AsyncValue<List<DoseLog>>> {
  final DoseLogRepository _repository;

  DoseLogListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDoseLogs();
  }

  Future<void> loadDoseLogs() async {
    state = const AsyncValue.loading();
    try {
      final doseLogs = await _repository.getAllDoseLogs();
      state = AsyncValue.data(doseLogs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addDoseLog(DoseLog doseLog) async {
    try {
      final id = await _repository.insertDoseLog(doseLog);
      final newDoseLog = doseLog.copyWith(id: id);
      
      state.whenData((doseLogs) {
        state = AsyncValue.data([newDoseLog, ...doseLogs]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateDoseLog(DoseLog doseLog) async {
    try {
      await _repository.updateDoseLog(doseLog);
      
      state.whenData((doseLogs) {
        final updatedList = doseLogs.map((d) {
          return d.id == doseLog.id ? doseLog : d;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markDoseAsTaken(int id, {DateTime? takenTime, double? doseAmount, String? notes}) async {
    try {
      await _repository.markDoseAsTaken(id, takenTime: takenTime, doseAmount: doseAmount, notes: notes);
      
      state.whenData((doseLogs) {
        final updatedList = doseLogs.map((d) {
          if (d.id == id) {
            return d.copyWith(
              status: DoseStatus.taken,
              takenTime: takenTime ?? DateTime.now(),
              doseAmount: doseAmount ?? d.doseAmount,
              notes: notes ?? d.notes,
            );
          }
          return d;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markDoseAsSkipped(int id, {String? notes}) async {
    try {
      await _repository.markDoseAsSkipped(id, notes: notes);
      
      state.whenData((doseLogs) {
        final updatedList = doseLogs.map((d) {
          if (d.id == id) {
            return d.copyWith(
              status: DoseStatus.skipped,
              notes: notes ?? d.notes,
            );
          }
          return d;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markDoseAsMissed(int id) async {
    try {
      await _repository.markDoseAsMissed(id);
      
      state.whenData((doseLogs) {
        final updatedList = doseLogs.map((d) {
          if (d.id == id) {
            return d.copyWith(status: DoseStatus.missed);
          }
          return d;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteDoseLog(int id) async {
    try {
      await _repository.deleteDoseLog(id);
      
      state.whenData((doseLogs) {
        final updatedList = doseLogs.where((d) => d.id != id).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for the dose log list state notifier
final doseLogListProvider = 
    StateNotifierProvider<DoseLogListNotifier, AsyncValue<List<DoseLog>>>((ref) {
  final repository = ref.watch(doseLogRepositoryProvider);
  return DoseLogListNotifier(repository);
});

// Provider for today's dose logs
final todaysDoseLogsProvider = Provider<AsyncValue<List<DoseLog>>>((ref) {
  return ref.watch(doseLogListProvider).whenData((doseLogs) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return doseLogs.where((doseLog) {
      return doseLog.scheduledTime.isAfter(startOfDay) && 
             doseLog.scheduledTime.isBefore(endOfDay);
    }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  });
});

// Provider for pending dose logs
final pendingDoseLogsProvider = Provider<AsyncValue<List<DoseLog>>>((ref) {
  return ref.watch(doseLogListProvider).whenData((doseLogs) {
    return doseLogs.where((doseLog) => doseLog.isPending).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  });
});

// Provider for overdue dose logs
final overdueDoseLogsProvider = Provider<AsyncValue<List<DoseLog>>>((ref) {
  return ref.watch(doseLogListProvider).whenData((doseLogs) {
    return doseLogs.where((doseLog) => doseLog.isOverdue).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  });
});

// Provider for dose logs by medication
final doseLogsByMedicationProvider = FutureProvider.family<List<DoseLog>, int>((ref, medicationId) async {
  final repository = ref.watch(doseLogRepositoryProvider);
  return await repository.getDoseLogsForMedication(medicationId);
});

// Provider for dose logs by date
final doseLogsByDateProvider = FutureProvider.family<List<DoseLog>, DateTime>((ref, date) async {
  final repository = ref.watch(doseLogRepositoryProvider);
  return await repository.getDoseLogsForDate(date);
});

// Provider for compliance stats
final complianceStatsProvider = FutureProvider.family<Map<String, int>, ComplianceRequest>((ref, request) async {
  final repository = ref.watch(doseLogRepositoryProvider);
  return await repository.getDoseComplianceStats(request.medicationId, request.startDate, request.endDate);
});

// Provider for compliance rate
final complianceRateProvider = FutureProvider.family<double, ComplianceRequest>((ref, request) async {
  final repository = ref.watch(doseLogRepositoryProvider);
  return await repository.getComplianceRate(request.medicationId, request.startDate, request.endDate);
});

// Helper class for compliance providers
class ComplianceRequest {
  final int medicationId;
  final DateTime startDate;
  final DateTime endDate;

  ComplianceRequest({
    required this.medicationId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComplianceRequest &&
        other.medicationId == medicationId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(medicationId, startDate, endDate);
}
