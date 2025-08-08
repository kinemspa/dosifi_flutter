import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_flutter/core/services/notification_action_handler.dart';

void main() {
  group('NotificationActionHandler.parseNotificationInput', () {
    test('parses JSON payload with action field', () {
      final payload = '{"action":"take","scheduleId":42,"timestamp":1700000000000}';
      final parsed = NotificationActionHandler.parseNotificationInput(payload);
      expect(parsed, isNotNull);
      expect(parsed!.action, 'take');
      expect(parsed.scheduleId, 42);
      expect(parsed.scheduledDateTime.millisecondsSinceEpoch, 1700000000000);
    });

    test('parses JSON payload with type field (tap)', () {
      final payload = '{"type":"schedule","scheduleId":7,"timestamp":1700000001000}';
      final parsed = NotificationActionHandler.parseNotificationInput(payload);
      expect(parsed, isNotNull);
      expect(parsed!.action, 'schedule');
      expect(parsed.scheduleId, 7);
      expect(parsed.scheduledDateTime.millisecondsSinceEpoch, 1700000001000);
    });

    test('parses legacy payload take_ scheduleId_timestamp', () {
      final payload = 'take_99_1700000002000';
      final parsed = NotificationActionHandler.parseNotificationInput(payload);
      expect(parsed, isNotNull);
      expect(parsed!.action, 'take');
      expect(parsed.scheduleId, 99);
      expect(parsed.scheduledDateTime.millisecondsSinceEpoch, 1700000002000);
    });

    test('returns null for invalid legacy payload', () {
      final payload = 'invalid_payload';
      final parsed = NotificationActionHandler.parseNotificationInput(payload);
      expect(parsed, isNull);
    });

    test('returns null for invalid JSON', () {
      final payload = '{invalid_json}';
      final parsed = NotificationActionHandler.parseNotificationInput(payload);
      expect(parsed, isNull);
    });
  });
}

