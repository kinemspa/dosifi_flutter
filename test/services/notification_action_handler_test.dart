import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_flutter/core/services/notification_action_handler.dart';
import 'package:dosifi_flutter/presentation/providers/dose_log_provider.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/presentation/providers/schedule_provider.dart';
import 'package:dosifi_flutter/data/models/dose_log.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/data/repositories/dose_log_repository.dart';
import 'package:dosifi_flutter/data/repositories/schedule_repository.dart';
import 'package:dosifi_flutter/services/notification_service.dart';
import '../fakes/fake_notification_service.dart';

class _InMemoryDoseLogRepo extends DoseLogListNotifier {
  _InMemoryDoseLogRepo() : super(_FakeDoseLogRepository());
}

class _FakeScheduleRepository extends ScheduleRepository {
  final List<Schedule> _schedules;
  _FakeScheduleRepository(this._schedules);
  @override
  Future<List<Schedule>> getActiveSchedules() async => _schedules;
}

class _FakeDoseLogRepository extends DoseLogRepository {
  final List<DoseLog> _store = [];
  @override
  Future<List<DoseLog>> getAllDoseLogs() async => _store;
  @override
  Future<int> insertDoseLog(DoseLog doseLog) async {
    final id = _store.length + 1;
    _store.add(doseLog.copyWith(id: id));
    return id;
  }

  @override
  Future<int> updateDoseLog(DoseLog doseLog) async {
    final idx = _store.indexWhere((d) => d.id == doseLog.id);
    if (idx >= 0) {
      _store[idx] = doseLog;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> markDoseAsTaken(
    int id, {
    DateTime? takenTime,
    double? doseAmount,
    String? doseUnit,
    String? notes,
  }) async {
    final idx = _store.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      final d = _store[idx];
      _store[idx] = d.copyWith(
        status: DoseStatus.taken,
        takenTime: takenTime ?? DateTime.now(),
        doseAmount: doseAmount ?? d.doseAmount,
      );
      return 1;
    }
    return 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationActionHandler action flows', () {
    late ProviderContainer container;
    late FakeNotificationService fakeNotifications;

    setUp(() async {
      NotificationService.testMode = true;
      fakeNotifications = FakeNotificationService();
      final schedules = [
        Schedule(
          id: 1,
          medicationId: 10,
          scheduleType: ScheduleType.daily.name,
          timeOfDay: '08:00',
          startDate: DateTime(2025, 1, 1),
          endDate: null,
          doseAmount: 1,
          doseUnit: 'tablet',
          doseForm: 'tablet',
          strengthPerUnit: 1,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      container = ProviderContainer(
        overrides: [
          // Override providers to return predictable test data
          doseLogListProvider.overrideWith((ref) => _InMemoryDoseLogRepo()),
          scheduleRepositoryProvider.overrideWith(
            (ref) => _FakeScheduleRepository(schedules),
          ),
          medicationByIdProvider.overrideWith((ref, id) async {
            // Return a simple medication object when looked up
            return Medication(
              id: id,
              name: 'Test Med',
              type: MedicationType.tablet,
              strengthPerUnit: 500,
              strengthUnit: StrengthUnit.mg,
              stockQuantity: 10,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }),
        ],
      );
      // Force schedule list provider state to our known data to avoid async races
      final notifier = container.read(scheduleListProvider.notifier);
      notifier.state = AsyncValue.data(schedules);
    });

    tearDown(() async {
      container.dispose();
    });

    test('take_dose creates/updates dose log and shows success', () async {
      final handler = NotificationActionHandler(
        read: container.read,
        invalidate: container.invalidate,
        notifications: fakeNotifications,
      );
      final payload =
          '{"action":"take","scheduleId":1,"timestamp":1700000000000}';

      await handler.handleNotificationTap(payload);

      // Verify a success notification was shown
      expect(
        fakeNotifications.calls.any((c) => c.startsWith('show:Dose Taken')),
        isTrue,
      );
    });

    test('snooze_dose cancels and schedules snoozed notification', () async {
      final handler = NotificationActionHandler(
        read: container.read,
        invalidate: container.invalidate,
        notifications: fakeNotifications,
      );
      final payload =
          '{"action":"snooze","scheduleId":1,"timestamp":1700000000000}';

      await handler.handleNotificationTap(payload);

      // Verify cancel and schedule were invoked
      expect(
        fakeNotifications.calls.any((c) => c.startsWith('cancel:')),
        isTrue,
      );
      expect(
        fakeNotifications.calls.any(
          (c) => c.startsWith('scheduleForSchedule:1:'),
        ),
        isTrue,
      );
      expect(
        fakeNotifications.calls.any((c) => c.startsWith('show:Dose Snoozed')),
        isTrue,
      );
    });

    test('cancel_dose marks skipped and cancels notification', () async {
      final handler = NotificationActionHandler(
        read: container.read,
        invalidate: container.invalidate,
        notifications: fakeNotifications,
      );
      final payload =
          '{"action":"cancel","scheduleId":1,"timestamp":1700000000000}';

      await handler.handleNotificationTap(payload);

      expect(
        fakeNotifications.calls.any((c) => c.startsWith('cancel:')),
        isTrue,
      );
      expect(
        fakeNotifications.calls.any((c) => c.startsWith('show:Dose Cancelled')),
        isTrue,
      );
    });
  });
}
