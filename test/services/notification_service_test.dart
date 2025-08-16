import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_flutter/services/notification_service.dart';
import 'package:dosifi_flutter/core/services/notification_action_handler.dart';

void main() {
  group('NotificationService basic behavior', () {
    test('singleton returns same instance', () {
      final a = NotificationService();
      final b = NotificationService();
      expect(identical(a, b), isTrue);
    });
  });

  group('NotificationActionHandler.parseNotificationInput', () {
    test('parses JSON payload', () {
      final payload =
          '{"type":"schedule","scheduleId":5,"timestamp":1700000001000}';
      final parsed = NotificationActionHandler.parseNotificationInput(payload);
      expect(parsed, isNotNull);
      expect(parsed!.action, 'schedule');
      expect(parsed.scheduleId, 5);
      expect(parsed.scheduledDateTime.millisecondsSinceEpoch, 1700000001000);
    });

    test('parses legacy payload', () {
      final payload = 'take_7_1700000002000';
      final parsed = NotificationActionHandler.parseNotificationInput(payload);
      expect(parsed, isNotNull);
      expect(parsed!.action, 'take');
      expect(parsed.scheduleId, 7);
      expect(parsed.scheduledDateTime.millisecondsSinceEpoch, 1700000002000);
    });
  });
}
