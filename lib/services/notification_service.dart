import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../data/models/schedule.dart';
import '../data/models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Optional action handler that UI can register to process notification taps/actions.
  void Function(String? actionId, String? payload)? onAction;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone data (use device local timezone by default)
      tz.initializeTimeZones();
      if (kDebugMode) {
        // Log current tz.local without forcing a specific region
        print('NotificationService: Timezone initialized. tz.local=${tz.local.name}, now=${tz.TZDateTime.now(tz.local)}');
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (kDebugMode) {
            print('Notification tapped. actionId=${response.actionId}, payload=${response.payload}');
          }
          // Prefer actionId for action buttons; otherwise fall back to payload.
          final actionId = (response.actionId != null && response.actionId!.isNotEmpty)
              ? response.actionId
              : null;
          onAction?.call(actionId, response.payload);
        },
      );

      if (initialized == true) {
        _initialized = true;
        if (kDebugMode) {
          print('NotificationService: Initialized successfully');
        }
      } else {
        if (kDebugMode) {
          print('NotificationService: Failed to initialize');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Initialization error: $e');
      }
    }
  }


  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Request basic notification permission
      final granted = await androidPlugin.requestNotificationsPermission();
      if (kDebugMode) {
        print('NotificationService: Basic notification permission granted: $granted');
      }
      
      // Request exact alarm permission (Android 12+)
      try {
        final exactAlarmPermission = await androidPlugin.requestExactAlarmsPermission();
        if (kDebugMode) {
          print('NotificationService: Exact alarm permission granted: $exactAlarmPermission');
        }
      } catch (e) {
        if (kDebugMode) {
          print('NotificationService: Exact alarm permission request failed: $e');
        }
      }
      
      return granted ?? false;
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    try {
      // Check if the scheduled date is in the future
      if (scheduledDate.isBefore(DateTime.now())) {
        if (kDebugMode) {
          print('NotificationService: Cannot schedule notification for past time: $scheduledDate');
        }
        throw Exception('Cannot schedule notification for past time');
      }

      if (kDebugMode) {
        print('NotificationService: Scheduling notification $id for $scheduledDate');
        print('NotificationService: Current time: ${DateTime.now()}');
        print('NotificationService: Time until notification: ${scheduledDate.difference(DateTime.now())}');
      }

      final notificationDetails = _createStyledNotificationDetails(
        title: title,
        body: body,
        notificationType: 'medication',
      );

      // Convert to timezone-aware datetime using proper constructor
      final tzDateTime = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
        scheduledDate.second,
        scheduledDate.millisecond,
      );
      
      if (kDebugMode) {
        print('NotificationService: TZDateTime: $tzDateTime');
        print('NotificationService: Local timezone: ${tz.local.name}');
        print('NotificationService: Timezone offset: ${tzDateTime.timeZoneOffset}');
        print('NotificationService: Is in future: ${tzDateTime.isAfter(tz.TZDateTime.now(tz.local))}');
      }

      // Check if we can schedule exact alarms
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      
      if (androidPlugin != null) {
        try {
          final canScheduleExactAlarms = await androidPlugin.canScheduleExactNotifications();
          if (kDebugMode) {
            print('NotificationService: Can schedule exact alarms: $canScheduleExactAlarms');
          }
          if (canScheduleExactAlarms != true) {
            scheduleMode = AndroidScheduleMode.inexact;
            if (kDebugMode) {
              print('NotificationService: Using inexact scheduling mode');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('NotificationService: Error checking exact alarm capability: $e');
          }
          scheduleMode = AndroidScheduleMode.inexact;
        }
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      if (kDebugMode) {
        print('NotificationService: Successfully scheduled notification $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error scheduling notification: $e');
      }
      rethrow;
    }
  }

  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime firstScheduledDate,
    required RepeatInterval repeatInterval,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Notifications for medication schedules',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.periodicallyShow(
      id,
      title,
      body,
      repeatInterval,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleNotificationForSchedule({
    required Schedule schedule,
    required Medication medication,
    required DateTime scheduledDate,
  }) async {
    final title = '💊 Time for ${medication.name}';
    final timeStr = '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
    final dateStr = '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
    final body = '$timeStr • $dateStr\n${schedule.doseAmount} ${schedule.doseUnit} • ${medication.displayStrength}';
    
    // Generate unique notification ID based on schedule ID and date
    final notificationId = _generateNotificationId(schedule.id!, scheduledDate);
    
    await scheduleNotificationWithActions(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      schedule: schedule,
      medication: medication,
    );
  }

  Future<void> scheduleNotificationsForSchedule({
    required Schedule schedule,
    required Medication medication,
    int daysAhead = 30,
  }) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));
    
    for (var date = now; date.isBefore(endDate); date = date.add(const Duration(days: 1))) {
      if (schedule.isActiveOnDate(date)) {
        // Parse schedule time
        final timeParts = schedule.timeOfDay.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
        
        final scheduledDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        
        // Only schedule if it's in the future
        if (scheduledDateTime.isAfter(now)) {
          await scheduleNotificationForSchedule(
            schedule: schedule,
            medication: medication,
            scheduledDate: scheduledDateTime,
          );
        }
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotificationsForSchedule(int scheduleId) async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    
    for (final notification in pendingNotifications) {
      if (notification.payload?.contains('schedule_$scheduleId') == true) {
        await _notifications.cancel(notification.id);
      }
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  int _generateNotificationId(int scheduleId, DateTime date) {
    // Combine schedule ID with date to create unique notification ID
    final dateString = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return int.parse('$scheduleId$dateString') % 2147483647; // Ensure it fits in int32
  }

  /// Schedule notification with action buttons
  Future<void> scheduleNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required Schedule schedule,
    required Medication medication,
  }) async {
    if (!_initialized) await initialize();

    try {
      // Check if the scheduled date is in the future
      if (scheduledDate.isBefore(DateTime.now())) {
        if (kDebugMode) {
          print('NotificationService: Cannot schedule notification for past time: $scheduledDate');
        }
        throw Exception('Cannot schedule notification for past time');
      }

      if (kDebugMode) {
        print('NotificationService: Scheduling notification with actions $id for $scheduledDate');
      }

      // Create notification details with action buttons
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication schedules and dosing reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          color: const Color(0xFF2196F3),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            body,
            htmlFormatBigText: false,
            contentTitle: title,
            htmlFormatContentTitle: false,
            summaryText: '💊 Dosifi',
            htmlFormatSummaryText: false,
          ),
          category: AndroidNotificationCategory.reminder,
          actions: [
            AndroidNotificationAction(
              'take_${schedule.id}_${scheduledDate.millisecondsSinceEpoch}',
              '✅ Take',
              titleColor: const Color(0xFF4CAF50),
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              'snooze_${schedule.id}_${scheduledDate.millisecondsSinceEpoch}',
              '⏰ Snooze',
              titleColor: const Color(0xFFFF9800),
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              'cancel_${schedule.id}_${scheduledDate.millisecondsSinceEpoch}',
              '❌ Cancel',
              titleColor: const Color(0xFFF44336),
              showsUserInterface: false,
            ),
          ],
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
          categoryIdentifier: 'medication_reminder',
        ),
      );

      // Convert to timezone-aware datetime
      final tzDateTime = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
        scheduledDate.second,
        scheduledDate.millisecond,
      );

      // Check scheduling capability
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      
      if (androidPlugin != null) {
        try {
          final canScheduleExactAlarms = await androidPlugin.canScheduleExactNotifications();
          if (canScheduleExactAlarms != true) {
            scheduleMode = AndroidScheduleMode.inexact;
          }
        } catch (e) {
          scheduleMode = AndroidScheduleMode.inexact;
        }
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'schedule_${schedule.id}_${scheduledDate.millisecondsSinceEpoch}',
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      if (kDebugMode) {
        print('NotificationService: Successfully scheduled notification with actions $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error scheduling notification with actions: $e');
      }
      rethrow;
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_notifications',
        'Instant Notifications',
        channelDescription: 'Instant notifications for app events',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Check if exact alarm permissions are granted (Android 12+)
  Future<bool> areExactAlarmsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      } catch (e) {
        if (kDebugMode) {
          print('NotificationService: Error checking exact alarm permissions: $e');
        }
        return false;
      }
    }
    return true; // iOS doesn't have this concept
  }

  /// Get detailed permission status
  Future<Map<String, bool>> getPermissionStatus() async {
    final result = <String, bool>{};
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        result['notifications'] = await androidPlugin.areNotificationsEnabled() ?? false;
      } catch (e) {
        result['notifications'] = false;
        if (kDebugMode) {
          print('NotificationService: Error checking notification permissions: $e');
        }
      }
      
      try {
        // Note: There's no direct method to check exact alarm permission status
        // So we'll assume it's granted if notifications are enabled
        result['exactAlarms'] = result['notifications'] ?? false;
      } catch (e) {
        result['exactAlarms'] = false;
        if (kDebugMode) {
          print('NotificationService: Error checking exact alarm permissions: $e');
        }
      }
    } else {
      // iOS
      result['notifications'] = true;
      result['exactAlarms'] = true;
    }
    
    return result;
  }

  /// Request notification permissions on app start
  Future<bool> requestAndInitialize() async {
    if (!_initialized) {
      await initialize();
    }
    
    // Request permissions
    final permissionGranted = await requestPermissions();
    if (kDebugMode) {
      print('NotificationService: Permission granted: $permissionGranted');
    }
    
    return permissionGranted;
  }

  /// Static method for showing notifications - convenience wrapper
  /// 
  /// This method provides a static interface for showing notifications,
  /// which is useful for calling from UI components.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final service = NotificationService();
    if (!service._initialized) await service.initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_notifications',
        'Test Notifications',
        channelDescription: 'Test notifications for app functionality',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await service._notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Debug utility to verify notification system health
  Future<Map<String, dynamic>> getNotificationSystemStatus() async {
    if (!_initialized) await initialize();
    
    final status = <String, dynamic>{};
    
    // Check initialization
    status['initialized'] = _initialized;
    
    // Check timezone
    status['timezone'] = {
      'name': tz.local.name,
      'current_time': tz.TZDateTime.now(tz.local).toString(),
      'utc_offset': tz.TZDateTime.now(tz.local).timeZoneOffset.toString(),
    };
    
    // Check permissions
    final permissions = await getPermissionStatus();
    status['permissions'] = permissions;
    
    // Check pending notifications
    final pending = await getPendingNotifications();
    status['pending_count'] = pending.length;
    status['pending_notifications'] = pending.map((n) => {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'payload': n.payload,
    }).toList();
    
    // Check exact alarm capability
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        status['can_schedule_exact'] = await androidPlugin.canScheduleExactNotifications();
      } catch (e) {
        status['can_schedule_exact'] = false;
        status['exact_alarm_error'] = e.toString();
      }
    }
    
    return status;
  }

  /// Create styled notification details based on notification type
  NotificationDetails _createStyledNotificationDetails({
    required String title,
    required String body,
    required String notificationType,
  }) {
    String channelId;
    String channelName;
    String channelDescription;
    AndroidNotificationDetails androidDetails;
    
    switch (notificationType) {
      case 'medication':
        channelId = 'medication_reminders';
        channelName = 'Medication Reminders';
        channelDescription = 'Notifications for medication schedules and dosing reminders';
        androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          color: const Color(0xFF2196F3), // Blue color
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: const BigTextStyleInformation(
            '',
            htmlFormatBigText: true,
            contentTitle: '',
            htmlFormatContentTitle: true,
            summaryText: '💊 Dosifi',
            htmlFormatSummaryText: true,
          ),
          category: AndroidNotificationCategory.reminder,
        );
        break;
      case 'alert':
        channelId = 'medication_alerts';
        channelName = 'Medication Alerts';
        channelDescription = 'Important alerts for low stock, expiry warnings, etc.';
        androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          color: const Color(0xFFFF9800), // Orange color
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: const BigTextStyleInformation(
            '',
            htmlFormatBigText: true,
            contentTitle: '',
            htmlFormatContentTitle: true,
            summaryText: '⚠️ Dosifi Alert',
            htmlFormatSummaryText: true,
          ),
          category: AndroidNotificationCategory.alarm,
        );
        break;
      case 'test':
        channelId = 'test_notifications';
        channelName = 'Test Notifications';
        channelDescription = 'Test notifications for app functionality and debugging';
        androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          color: const Color(0xFF9C27B0), // Purple color
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: const BigTextStyleInformation(
            '',
            htmlFormatBigText: true,
            contentTitle: '',
            htmlFormatContentTitle: true,
            summaryText: '🧪 Dosifi Test',
            htmlFormatSummaryText: true,
          ),
          category: AndroidNotificationCategory.status,
        );
        break;
      default:
        channelId = 'general_notifications';
        channelName = 'General Notifications';
        channelDescription = 'General notifications from Dosifi app';
        androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          enableVibration: false,
          playSound: true,
          color: const Color(0xFF4CAF50), // Green color
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: const BigTextStyleInformation(
            '',
            htmlFormatBigText: true,
            contentTitle: '',
            htmlFormatContentTitle: true,
            summaryText: '📱 Dosifi',
            htmlFormatSummaryText: true,
          ),
          category: AndroidNotificationCategory.status,
        );
    }

    return NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }
  
  /// Test method to schedule a simple notification in 10 seconds
  Future<bool> scheduleTestNotification() async {
    try {
      final testTime = DateTime.now().add(const Duration(seconds: 10));
      await scheduleNotification(
        id: 999999, // Use a distinctive ID for testing
        title: 'Test Notification',
        body: 'This is a test scheduled for ${testTime.hour}:${testTime.minute.toString().padLeft(2, '0')}',
        scheduledDate: testTime,
        payload: 'test_notification_${testTime.millisecondsSinceEpoch}',
      );
      
      if (kDebugMode) {
        print('NotificationService: Test notification scheduled for $testTime');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Failed to schedule test notification: $e');
      }
      return false;
    }
  }
}
