import 'package:flutter/foundation.dart';
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

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC')); // Set a default timezone

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
        onDidReceiveNotificationResponse: _onNotificationTapped,
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

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    // TODO: Navigate to specific screen based on payload
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
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
    final title = 'Time for ${medication.name}';
    final body = '${schedule.doseAmount} ${schedule.doseUnit} - ${medication.displayStrength}';
    
    // Generate unique notification ID based on schedule ID and date
    final notificationId = _generateNotificationId(schedule.id!, scheduledDate);
    
    await scheduleNotification(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: 'schedule_${schedule.id}_${scheduledDate.millisecondsSinceEpoch}',
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
}
