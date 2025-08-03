import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/schedule.dart';
import '../../data/repositories/schedule_repository.dart';

// Repository provider
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

// State notifier for managing schedules
class ScheduleListNotifier extends StateNotifier<AsyncValue<List<Schedule>>> {
  final ScheduleRepository _repository;

  ScheduleListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSchedules();
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
}

// Provider for the schedule list state notifier
final scheduleListProvider = 
    StateNotifierProvider<ScheduleListNotifier, AsyncValue<List<Schedule>>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return ScheduleListNotifier(repository);
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
      // TODO: Implement proper repeat pattern matching based on daysOfWeek
      return true;
    }).toList();
  });
});

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
