import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/dose_scheduling_service.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/dose_log_repository.dart';
import '../../data/models/dose_log.dart';

// Dose Scheduling Service Provider
final doseSchedulingServiceProvider = Provider<DoseSchedulingService>((ref) {
  return DoseSchedulingService(
    scheduleRepository: ScheduleRepository(),
    doseLogRepository: DoseLogRepository(),
  );
});

// State notifier for managing dose scheduling operations
class DoseSchedulingNotifier extends StateNotifier<AsyncValue<void>> {
  final DoseSchedulingService _service;

  DoseSchedulingNotifier(this._service) : super(const AsyncValue.data(null));

  /// Initialize dose logs for today
  Future<void> initializeTodaysDoses() async {
    state = const AsyncValue.loading();
    try {
      await _service.generateTodaysDoseLogs();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Generate upcoming dose logs
  Future<void> generateUpcomingDoses() async {
    try {
      await _service.generateUpcomingDoseLogs();
    } catch (e) {
      // Log error but don't update state for background operations
      print('Error generating upcoming doses: $e');
    }
  }

  /// Take a dose
  Future<void> takeDose(int doseLogId, {double? doseAmount, String? notes}) async {
    try {
      await _service.takeDose(doseLogId, actualDoseAmount: doseAmount, notes: notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Snooze a dose
  Future<DoseLog?> snoozeDose(int doseLogId, Duration snoozeDuration) async {
    try {
      final snoozedLog = await _service.snoozeDose(doseLogId, snoozeDuration);
      return snoozedLog;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Skip a dose
  Future<void> skipDose(int doseLogId, {String? reason}) async {
    try {
      await _service.skipDose(doseLogId, reason: reason);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Mark overdue doses as missed
  Future<void> processOverdueDoses() async {
    try {
      await _service.markOverdueDosesAsMissed();
    } catch (e) {
      print('Error processing overdue doses: $e');
    }
  }

  /// Clean up old dose logs
  Future<void> cleanupOldLogs({int daysToKeep = 90}) async {
    try {
      await _service.cleanupOldDoseLogs(daysToKeep: daysToKeep);
    } catch (e) {
      print('Error cleaning up old logs: $e');
    }
  }
}

// Provider for the dose scheduling state notifier
final doseSchedulingProvider = 
    StateNotifierProvider<DoseSchedulingNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(doseSchedulingServiceProvider);
  return DoseSchedulingNotifier(service);
});

// Provider for medication forecast
final medicationForecastProvider = 
    FutureProvider.family<Map<int, int>, MedicationForecastRequest>((ref, request) async {
  final service = ref.watch(doseSchedulingServiceProvider);
  return await service.calculateMedicationForecast(request.medicationId, request.days);
});

// Provider for compliance rate
final complianceRateProvider = 
    FutureProvider.family<double, ComplianceRateRequest>((ref, request) async {
  final service = ref.watch(doseSchedulingServiceProvider);
  return await service.getComplianceRate(
    request.medicationId, 
    request.startDate, 
    request.endDate
  );
});

// Provider for dose statistics
final doseStatisticsProvider = 
    FutureProvider.family<Map<String, int>, DoseStatisticsRequest>((ref, request) async {
  final service = ref.watch(doseSchedulingServiceProvider);
  return await service.getDoseStatistics(
    request.medicationId, 
    request.startDate, 
    request.endDate
  );
});

// Provider for overdue doses
final overdueDosesProvider = FutureProvider<List<DoseLog>>((ref) async {
  final service = ref.watch(doseSchedulingServiceProvider);
  return await service.getOverdueDoses();
});

// Helper classes for provider requests
class MedicationForecastRequest {
  final int medicationId;
  final int days;

  MedicationForecastRequest({
    required this.medicationId,
    required this.days,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationForecastRequest &&
        other.medicationId == medicationId &&
        other.days == days;
  }

  @override
  int get hashCode => Object.hash(medicationId, days);
}

class ComplianceRateRequest {
  final int medicationId;
  final DateTime startDate;
  final DateTime endDate;

  ComplianceRateRequest({
    required this.medicationId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComplianceRateRequest &&
        other.medicationId == medicationId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(medicationId, startDate, endDate);
}

class DoseStatisticsRequest {
  final int medicationId;
  final DateTime startDate;
  final DateTime endDate;

  DoseStatisticsRequest({
    required this.medicationId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoseStatisticsRequest &&
        other.medicationId == medicationId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(medicationId, startDate, endDate);
}
