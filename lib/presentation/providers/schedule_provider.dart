import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/schedule.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../services/notification_service.dart';
import 'medication_provider.dart';

// Repository provider
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

// State notifier for managing schedules
class ScheduleListNotifier extends StateNotifier<AsyncValue<List<Schedule>>> {
  final ScheduleRepository _repository;
  final Ref _ref;
  final NotificationService _notificationService = NotificationService();

  ScheduleListNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _initializeNotifications();
    loadSchedules();
  }

  Future<void> _initializeNotifications() async {
    // Skip notification initialization in test environment
    if (kDebugMode && (kIsWeb)) {
      debugPrint('Skipping notification initialization in test environment');
      return;
    }
    
    try {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  Future<void> loadSchedules() async {
    state = const AsyncValue.loading();
    try {
      final schedules = await _repository.getActiveSchedules();
      state = AsyncValue.data(schedules);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    try {
      final id = await _repository.insertSchedule(schedule);
      final newSchedule = schedule.copyWith(id: id);
      
      // Schedule notifications for this schedule
      await _scheduleNotifications(newSchedule);
      
      state.whenData((schedules) {
        state = AsyncValue.data([...schedules, newSchedule]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _repository.updateSchedule(schedule);
      
      state.whenData((schedules) {
        final updatedList = schedules.map((s) {
          return s.id == schedule.id ? schedule : s;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSchedule(int id) async {
    try {
      await _repository.deleteSchedule(id);
      
      state.whenData((schedules) {
        final updatedList = schedules.where((s) => s.id != id).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleScheduleActive(int id, bool isActive) async {
    try {
      await _repository.updateScheduleStatus(id, isActive);
      
      if (!isActive) {
        // Cancel notifications for inactive schedule
        await _notificationService.cancelNotificationsForSchedule(id);
      }
      
      state.whenData((schedules) {
        final updatedList = schedules.map((s) {
          if (s.id == id) {
            return s.copyWith(isActive: isActive);
          }
          return s;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _scheduleNotifications(Schedule schedule) async {
    try {
      if (!schedule.isActive) return;
      
      // Get medication details
      final medicationAsync = await _ref.read(medicationByIdProvider(schedule.medicationId).future);
      if (medicationAsync == null) return;
      
      // Schedule notifications for the next 30 days
      await _notificationService.scheduleNotificationsForSchedule(
        schedule: schedule,
        medication: medicationAsync,
        daysAhead: 30,
      );
    } catch (e) {
      // Log error but don't fail the schedule creation
      print('Error scheduling notifications: $e');
    }
  }
}

// Provider for the schedule list state notifier
final scheduleListProvider = 
    StateNotifierProvider<ScheduleListNotifier, AsyncValue<List<Schedule>>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return ScheduleListNotifier(repository, ref);
});

// Provider for getting schedules by medication
final schedulesByMedicationProvider = FutureProvider.family<List<Schedule>, int>((ref, medicationId) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  return await repository.getSchedulesByMedication(medicationId);
});

// Provider for today's schedules
final todaySchedulesProvider = Provider<AsyncValue<List<Schedule>>>((ref) {
  final allSchedules = ref.watch(scheduleListProvider);
  
  return allSchedules.whenData((schedules) {
    final today = DateTime.now();
    return schedules.where((schedule) {
      // Check if the schedule is active
      if (!schedule.isActive) return false;
      
      // Check if today is within the schedule's date range
      if (schedule.startDate.isAfter(today)) return false;
      if (schedule.endDate != null && schedule.endDate!.isBefore(today)) return false;
      
      // Check if it matches the repeat pattern for today
      return _matchesRepeatPattern(schedule, today);
    }).toList();
  });
});

// Helper function to check if a schedule matches the repeat pattern for a given day
bool _matchesRepeatPattern(Schedule schedule, DateTime day) {
  final scheduleType = ScheduleType.fromString(schedule.scheduleType);
  
  switch (scheduleType) {
    case ScheduleType.daily:
      return true; // Daily schedules match every day
    
    case ScheduleType.weekly:
      if (schedule.daysOfWeek == null || schedule.daysOfWeek!.isEmpty) {
        return false;
      }
      // Convert DateTime weekday (1=Monday, 7=Sunday) to our format (1=Sunday, 7=Saturday)
      final dayOfWeek = day.weekday == 7 ? 1 : day.weekday + 1;
      return schedule.daysOfWeek!.contains(dayOfWeek);
    
    case ScheduleType.cycling:
      if (schedule.cycleDaysOn == null || schedule.cycleDaysOff == null) {
        return false;
      }
      final daysSinceStart = day.difference(schedule.startDate).inDays;
      final cycleLength = schedule.cycleDaysOn! + schedule.cycleDaysOff!;
      final dayInCycle = daysSinceStart % cycleLength;
      return dayInCycle < schedule.cycleDaysOn!;
    
    case ScheduleType.asNeeded:
      return false; // As needed schedules don't have automatic patterns
    
    default:
      return true; // Default to true for unknown types
  }
}

// Provider for upcoming schedules (next 7 days)
final upcomingSchedulesProvider = Provider<AsyncValue<List<Schedule>>>((ref) {
  final allSchedules = ref.watch(scheduleListProvider);
  
  return allSchedules.whenData((schedules) {
    final today = DateTime.now();
    final nextWeek = today.add(const Duration(days: 7));
    
    return schedules.where((schedule) {
      if (!schedule.isActive) return false;
      
      // Check if the schedule falls within the next 7 days
      if (schedule.startDate.isAfter(nextWeek)) return false;
      if (schedule.endDate != null && schedule.endDate!.isBefore(today)) return false;
      
      return true;
    }).toList();
  });
});
