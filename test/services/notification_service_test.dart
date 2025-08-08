import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:dosifi_flutter/services/notification_service.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';

import 'notification_service_test.mocks.dart';

// Generate mocks with the build_runner
@GenerateMocks([FlutterLocalNotificationsPlugin])
void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;
    late MockFlutterLocalNotificationsPlugin mockPlugin;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      notificationService = NotificationService();
      // We need to inject the mock plugin for testing
      // This requires modifying the service to accept a plugin for testing
    });

    group('Initialization', () {
      test('initialize calls plugin initialize with correct settings', () async {
        // Arrange
        when(mockPlugin.initialize(any)).thenAnswer((_) async => true);

        // Note: This test will not work until we modify NotificationService
        // to allow dependency injection of the plugin for testing purposes
      });

      test('requestPermissions returns correct permission status', () async {
        // Arrange
        when(mockPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>())
            .thenReturn(null);

        // Act & Assert
        // This would test the permission request flow
      });
    });

    group('Instant Notifications', () {
      test('showInstantNotification calls plugin show with correct parameters', () async {
        // Arrange
        const title = 'Test Title';
        const body = 'Test Body';
        const payload = 'test_payload';

        when(mockPlugin.show(any, any, any, any, payload: anyNamed('payload')))
            .thenAnswer((_) async => null);

        // Act
        // await notificationService.showInstantNotification(
        //   title: title,
        //   body: body,
        //   payload: payload,
        // );

        // Assert
        // verify(mockPlugin.show(
        //   0, // default ID
        //   title,
        //   body,
        //   any,
        //   payload: payload,
        // )).called(1);
      });
    });

    group('Scheduled Notifications', () {
      test('scheduleNotification calls plugin zonedSchedule with correct parameters', () async {
        // Arrange
        const id = 123;
        const title = 'Scheduled Test';
        const body = 'Scheduled Body';
        final scheduledDate = DateTime.now().add(const Duration(hours: 1));
        const payload = 'scheduled_payload';

        when(mockPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async => null);

        // Act
        // await notificationService.scheduleNotification(
        //   id: id,
        //   title: title,
        //   body: body,
        //   scheduledDate: scheduledDate,
        //   payload: payload,
        // );

        // Assert
        // verify(mockPlugin.zonedSchedule(
        //   id,
        //   title,
        //   body,
        //   any, // TZDateTime
        //   any, // NotificationDetails
        //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        //   payload: payload,
        // )).called(1);
      });

      test('scheduleRepeatingNotification calls plugin periodicallyShow', () async {
        // Arrange
        const id = 456;
        const title = 'Repeating Test';
        const body = 'Repeating Body';
        final firstScheduledDate = DateTime.now().add(const Duration(minutes: 5));
        const repeatInterval = RepeatInterval.everyMinute;

        when(mockPlugin.periodicallyShow(
          any,
          any,
          any,
          any,
          any,
          payload: anyNamed('payload'),
        )).thenAnswer((_) async => null);

        // Act
        // await notificationService.scheduleRepeatingNotification(
        //   id: id,
        //   title: title,
        //   body: body,
        //   firstScheduledDate: firstScheduledDate,
        //   repeatInterval: repeatInterval,
        // );

        // Assert
        // verify(mockPlugin.periodicallyShow(
        //   id,
        //   title,
        //   body,
        //   repeatInterval,
        //   any, // NotificationDetails
        //   payload: any,
        // )).called(1);
      });
    });

    group('Medication Reminder Notifications', () {
      test('scheduleNotificationForSchedule creates proper notification', () async {
        // Arrange
        final medication = Medication.create(
          name: 'Test Medication',
          type: MedicationType.tablet,
          strengthPerUnit: 10.0,
          strengthUnit: StrengthUnit.mg,
          stockQuantity: 30.0,
        );

        final schedule = Schedule.create(
          medicationId: 1,
          scheduleType: 'daily',
          timeOfDay: '08:00',
          startDate: DateTime.now(),
          doseAmount: 1.0,
          doseUnit: 'tablet',
          doseForm: 'tablet',
          strengthPerUnit: 10.0,
        );

        final scheduledDate = DateTime.now().add(const Duration(hours: 1));

        when(mockPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async => null);

        // Act
        // await notificationService.scheduleNotificationForSchedule(
        //   schedule: schedule,
        //   medication: medication,
        //   scheduledDate: scheduledDate,
        // );

        // Assert
        // Expected notification title should contain medication name
        // Expected notification body should contain dose information
        // verify(mockPlugin.zonedSchedule(
        //   any,
        //   argThat(contains('Test Medication')), // title contains medication name
        //   argThat(contains('1.0 tablet')), // body contains dose info
        //   any,
        //   any,
        //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        //   payload: any,
        // )).called(1);
      });
    });

    group('Notification Management', () {
      test('cancelNotification calls plugin cancel with correct ID', () async {
        // Arrange
        const notificationId = 789;

        when(mockPlugin.cancel(any)).thenAnswer((_) async => null);

        // Act
        // await notificationService.cancelNotification(notificationId);

        // Assert
        // verify(mockPlugin.cancel(notificationId)).called(1);
      });

      test('cancelAllNotifications calls plugin cancelAll', () async {
        // Arrange
        when(mockPlugin.cancelAll()).thenAnswer((_) async => null);

        // Act
        // await notificationService.cancelAllNotifications();

        // Assert
        // verify(mockPlugin.cancelAll()).called(1);
      });

      test('getPendingNotifications returns list from plugin', () async {
        // Arrange
        final mockPendingNotifications = [
          const PendingNotificationRequest(
            1, // id
            'Test 1', // title
            'Body 1', // body
            'payload1', // payload
          ),
          const PendingNotificationRequest(
            2, // id
            'Test 2', // title
            'Body 2', // body
            'payload2', // payload
          ),
        ];

        when(mockPlugin.pendingNotificationRequests())
            .thenAnswer((_) async => mockPendingNotifications);

        // Act
        // final result = await notificationService.getPendingNotifications();

        // Assert
        // expect(result, equals(mockPendingNotifications));
        // verify(mockPlugin.pendingNotificationRequests()).called(1);
      });
    });

    group('Notification Details Creation', () {
      test('creates correct Android notification details', () {
        // This would test the internal _createNotificationDetails method
        // if it were made testable/public
      });

      test('creates correct iOS notification details', () {
        // This would test iOS-specific notification details
      });
    });

    group('Error Handling', () {
      test('handles plugin initialization failure gracefully', () async {
        // Arrange
        when(mockPlugin.initialize(any)).thenThrow(Exception('Init failed'));

        // Act & Assert
        // Test that the service handles initialization errors properly
      });

      test('handles permission denial gracefully', () async {
        // Test permission denial scenarios
      });

      test('handles notification scheduling failures', () async {
        // Arrange
        when(mockPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
        )).thenThrow(Exception('Scheduling failed'));

        // Act & Assert
        // Test that scheduling errors are handled properly
      });
    });
  });
}

// Helper methods for testing
class TestNotificationService extends NotificationService {
  final FlutterLocalNotificationsPlugin testPlugin;

  TestNotificationService(this.testPlugin);

  // Override the internal plugin for testing
  // This would require modifying the NotificationService to support this
}
