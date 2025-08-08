import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';
import 'package:dosifi_flutter/data/models/dose_log.dart';
import 'package:dosifi_flutter/presentation/providers/dose_log_provider.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/presentation/providers/schedule_provider.dart';
import 'package:dosifi_flutter/core/services/notification_service.dart';

class NotificationActionHandler {
  static const String actionTake = 'take_dose';
  static const String actionSnooze = 'snooze_dose';
  static const String actionCancel = 'cancel_dose';

  final WidgetRef ref;

  NotificationActionHandler(this.ref);

  /// Handle notification tap or action. Accepts either a structured JSON payload
  /// or the legacy "action_scheduleId_timestamp" format.
  Future<void> handleNotificationTap(String? payloadOrActionId) async {
    if (payloadOrActionId == null) return;

    if (kDebugMode) {
      print('NotificationActionHandler: Handling notification input: $payloadOrActionId');
    }

    try {
      // Attempt to parse JSON first
      String action;
      int scheduleId;
      DateTime scheduledDateTime;

      if (payloadOrActionId.trim().startsWith('{')) {
        final map = _safeDecodeJson(payloadOrActionId);
        if (map == null) {
          if (kDebugMode) print('NotificationActionHandler: Invalid JSON payload');
          return;
        }
        action = (map['action'] as String?) ?? (map['type'] as String? ?? 'tap');
        scheduleId = (map['scheduleId'] as num).toInt();
        final ts = (map['timestamp'] as num?)?.toInt();
        scheduledDateTime = ts != null
            ? DateTime.fromMillisecondsSinceEpoch(ts)
            : DateTime.now();
      } else {
        // Legacy: 'take_123_1691234567890' or 'schedule_123_169...'n        final parts = payloadOrActionId.split('_');
        if (parts.length < 3) {
          if (kDebugMode) {
            print('NotificationActionHandler: Invalid legacy payload format: $payloadOrActionId');
          }
          return;
        }
        action = parts[0];
        scheduleId = int.parse(parts[1]);
        final timestamp = int.parse(parts[2]);
        scheduledDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      if (kDebugMode) {
        print('NotificationActionHandler: Parsed -> action=$action, scheduleId=$scheduleId, scheduled=$scheduledDateTime');
      }

      // Get the schedule
      final schedulesAsync = ref.read(scheduleListProvider);
      final schedules = await schedulesAsync.when(
        data: (s) async => s,
        loading: () async => <Schedule>[],
        error: (_, __) async => <Schedule>[],
      );

      final schedule = schedules.firstWhere(
        (s) => s.id == scheduleId,
        orElse: () => throw Exception('Schedule not found'),
      );

      // Get existing dose log if any
      final doseLogsAsync = ref.read(doseLogListProvider);
      final doseLogs = await doseLogsAsync.when(
        data: (logs) async => logs,
        loading: () async => <DoseLog>[],
        error: (_, __) async => <DoseLog>[],
      );

      final existingDoseLog = doseLogs.cast<DoseLog?>().firstWhere(
        (log) => log != null &&
            log.medicationId == schedule.medicationId &&
            log.scheduledTime.isAtSameMomentAs(scheduledDateTime),
        orElse: () => null,
      );

      // Handle different actions
      switch (action) {
        case actionTake:
        case 'take':
          await _handleTakeDose(schedule, scheduledDateTime, existingDoseLog);
          break;
        case actionSnooze:
        case 'snooze':
          await _handleSnoozeDose(schedule, scheduledDateTime, existingDoseLog);
          break;
        case actionCancel:
        case 'cancel':
          await _handleCancelDose(schedule, scheduledDateTime, existingDoseLog);
          break;
        case 'schedule':
        case 'tap':
        default:
          // Default notification tap - could open the app to the schedule screen
          if (kDebugMode) {
            print('NotificationActionHandler: Default notification tap for schedule $scheduleId');
          }
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationActionHandler: Error handling notification: $e');
      }
    }
  }

  Map<String, dynamic>? _safeDecodeJson(String s) {
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Handle taking a dose from notification
  Future<void> _handleTakeDose(
    Schedule schedule,
    DateTime scheduledDateTime,
    DoseLog? existingDoseLog,
  ) async {
    try {
      if (kDebugMode) {
        print('NotificationActionHandler: Taking dose for schedule ${schedule.id}');
      }

      final now = DateTime.now();

      // Create or update dose log as taken
      final doseLog = existingDoseLog?.copyWith(
        status: DoseStatus.taken,
        takenTime: now,
        doseAmount: schedule.doseAmount,
      ) ?? DoseLog.create(
        medicationId: schedule.medicationId,
        scheduleId: schedule.id,
        scheduledTime: scheduledDateTime,
        status: DoseStatus.taken,
        doseAmount: schedule.doseAmount,
      );

      if (existingDoseLog?.id != null) {
        await ref.read(doseLogListProvider.notifier).updateDoseLog(
          doseLog.copyWith(id: existingDoseLog!.id)
        );
      } else {
        // Add new dose log and mark as taken
        await ref.read(doseLogListProvider.notifier).addDoseLog(doseLog);
        
        // Find the created dose log to mark as taken (which handles stock deduction)
        final updatedDoseLogsAsync = ref.read(doseLogListProvider);
        final updatedDoseLogs = await updatedDoseLogsAsync.when(
          data: (logs) async => logs,
          loading: () async => <DoseLog>[],
          error: (_, __) async => <DoseLog>[],
        );
        
        final createdDoseLog = updatedDoseLogs.cast<DoseLog>().firstWhere(
          (log) => log.medicationId == schedule.medicationId &&
                  log.scheduledTime.isAtSameMomentAs(scheduledDateTime) &&
                  log.status == DoseStatus.taken,
          orElse: () => throw Exception('Created dose log not found'),
        );
        
        if (createdDoseLog.id != null) {
          await ref.read(doseLogListProvider.notifier).markDoseAsTaken(
            createdDoseLog.id!,
            takenTime: now,
            doseAmount: schedule.doseAmount,
          );
        }
      }

      // Refresh medication list to show updated stock
      ref.invalidate(medicationListProvider);

      // Show a success notification
      final notificationService = NotificationService();
      await notificationService.showInstantNotification(
        title: 'Dose Taken',
        body: 'Your dose has been recorded and stock updated.',
      );

      if (kDebugMode) {
        print('NotificationActionHandler: Dose taken successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationActionHandler: Error taking dose: $e');
      }
      // Show error notification
      final notificationService = NotificationService();
      await notificationService.showInstantNotification(
        title: 'Error',
        body: 'Failed to record dose. Please try again.',
      );
    }
  }

  /// Handle snoozing a dose from notification
  Future<void> _handleSnoozeDose(
    Schedule schedule,
    DateTime scheduledDateTime,
    DoseLog? existingDoseLog,
  ) async {
    try {
      if (kDebugMode) {
        print('NotificationActionHandler: Snoozing dose for schedule ${schedule.id}');
      }

      // Default snooze duration (could be made configurable)
      const snoozeDurationMinutes = 15;
      final snoozeDateTime = DateTime.now().add(const Duration(minutes: snoozeDurationMinutes));

      // Cancel current notification
      final notificationService = NotificationService();
      final notificationId = _generateNotificationId(schedule.id!, scheduledDateTime);
      await notificationService.cancelNotification(notificationId);

      // Get medication for new notification
      final medicationAsync = ref.read(medicationByIdProvider(schedule.medicationId));
      final medication = await medicationAsync.when(
        data: (med) async => med,
        loading: () async => null,
        error: (_, __) async => null,
      );

      if (medication != null) {
        // Schedule new notification for snoozed time
        await notificationService.scheduleNotificationForSchedule(
          schedule: schedule,
          medication: medication,
          scheduledDate: snoozeDateTime,
        );
      }

      // Show confirmation notification
      await notificationService.showInstantNotification(
        title: 'Dose Snoozed',
        body: 'Reminder snoozed for $snoozeDurationMinutes minutes.',
      );

      if (kDebugMode) {
        print('NotificationActionHandler: Dose snoozed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationActionHandler: Error snoozing dose: $e');
      }
    }
  }

  /// Handle canceling a dose from notification
  Future<void> _handleCancelDose(
    Schedule schedule,
    DateTime scheduledDateTime,
    DoseLog? existingDoseLog,
  ) async {
    try {
      if (kDebugMode) {
        print('NotificationActionHandler: Canceling dose for schedule ${schedule.id}');
      }

      // Create or update dose log as skipped
      final doseLog = existingDoseLog?.copyWith(
        status: DoseStatus.skipped,
      ) ?? DoseLog.create(
        medicationId: schedule.medicationId,
        scheduleId: schedule.id,
        scheduledTime: scheduledDateTime,
        status: DoseStatus.skipped,
      );

      if (existingDoseLog?.id != null) {
        await ref.read(doseLogListProvider.notifier).updateDoseLog(
          doseLog.copyWith(id: existingDoseLog!.id)
        );
      } else {
        await ref.read(doseLogListProvider.notifier).addDoseLog(doseLog);
      }

      // Cancel the notification
      final notificationService = NotificationService();
      final notificationId = _generateNotificationId(schedule.id!, scheduledDateTime);
      await notificationService.cancelNotification(notificationId);

      // Show confirmation notification
      await notificationService.showInstantNotification(
        title: 'Dose Cancelled',
        body: 'The dose has been marked as skipped.',
      );

      if (kDebugMode) {
        print('NotificationActionHandler: Dose cancelled successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationActionHandler: Error canceling dose: $e');
      }
    }
  }

  int _generateNotificationId(int scheduleId, DateTime date) {
    final dateString = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return int.parse('$scheduleId$dateString') % 2147483647;
  }
}
