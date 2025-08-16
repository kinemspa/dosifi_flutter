import 'package:dosifi_flutter/services/notification_service.dart';

class FakeNotificationService implements INotificationService {
  final List<String> calls = [];

  @override
  Future<void> cancelNotification(int id) async {
    calls.add('cancel:$id');
  }

  @override
  Future<void> cancelNotificationForScheduleDate(
    int scheduleId,
    DateTime date,
  ) async {
    calls.add('cancelForDate:$scheduleId:${date.millisecondsSinceEpoch}');
  }

  @override
  Future<void> cancelNotificationsForSchedule(int scheduleId) async {
    calls.add('cancelForSchedule:$scheduleId');
  }

  @override
  int computeNotificationId(int scheduleId, DateTime when) {
    return int.parse(
          '$scheduleId${when.year}${when.month.toString().padLeft(2, '0')}${when.day.toString().padLeft(2, '0')}',
        ) %
        2147483647;
  }

  @override
  Future<Map<String, bool>> getPermissionStatus() async => {
    'notifications': true,
    'exactAlarms': true,
  };

  @override
  Future<void> initialize() async {
    calls.add('initialize');
  }

  @override
  Future<bool> requestAndInitialize() async {
    calls.add('requestAndInitialize');
    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    calls.add('requestPermissions');
    return true;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    calls.add('schedule:$id');
  }

  @override
  Future<void> scheduleNotificationForSchedule({
    required schedule,
    required medication,
    required DateTime scheduledDate,
  }) async {
    calls.add(
      'scheduleForSchedule:${schedule.id}:${scheduledDate.millisecondsSinceEpoch}',
    );
  }

  @override
  Future<void> scheduleNotificationsForSchedule({
    required schedule,
    required medication,
    int daysAhead = 30,
  }) async {
    calls.add('scheduleMany:${schedule.id}:$daysAhead');
  }

  @override
  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime firstScheduledDate,
    required repeatInterval,
    String? payload,
  }) async {
    calls.add('scheduleRepeating:$id');
  }

  @override
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    calls.add('show:$title');
  }
}
