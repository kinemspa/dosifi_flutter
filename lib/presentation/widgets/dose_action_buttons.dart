import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';
import 'package:dosifi_flutter/data/models/dose_log.dart';
import 'package:dosifi_flutter/presentation/providers/dose_log_provider.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/services/notification_service.dart';

enum DoseActionType { take, snooze, cancel }

class DoseActionButtons extends ConsumerWidget {
  final Schedule schedule;
  final DateTime? scheduledDateTime;
  final DoseLog? existingDoseLog;
  final bool isCompact;
  final VoidCallback? onActionCompleted;

  const DoseActionButtons({
    super.key,
    required this.schedule,
    this.scheduledDateTime,
    this.existingDoseLog,
    this.isCompact = false,
    this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveDateTime = scheduledDateTime ?? _getScheduledDateTimeForToday();
    final isAlreadyTaken = existingDoseLog?.status == DoseStatus.taken;
    final isCancelled = existingDoseLog?.status == DoseStatus.skipped;

    if (isAlreadyTaken) {
      return _buildTakenIndicator(context);
    }

    if (isCancelled) {
      return _buildCancelledIndicator(context);
    }

    return isCompact
        ? _buildCompactButtons(context, ref, effectiveDateTime)
        : _buildFullButtons(context, ref, effectiveDateTime);
  }

  Widget _buildTakenIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 4),
          Text(
            'Taken',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.cancel, color: Colors.grey, size: 16),
          SizedBox(width: 4),
          Text(
            'Cancelled',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButtons(BuildContext context, WidgetRef ref, DateTime scheduledDateTime) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          ref,
          scheduledDateTime,
          DoseActionType.take,
          Icons.check,
          Colors.green,
          'Take',
          isCompact: true,
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          context,
          ref,
          scheduledDateTime,
          DoseActionType.snooze,
          Icons.snooze,
          Colors.orange,
          'Snooze',
          isCompact: true,
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          context,
          ref,
          scheduledDateTime,
          DoseActionType.cancel,
          Icons.cancel,
          Colors.red,
          'Cancel',
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildFullButtons(BuildContext context, WidgetRef ref, DateTime scheduledDateTime) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                ref,
                scheduledDateTime,
                DoseActionType.take,
                Icons.check,
                Colors.green,
                'Take Dose',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                context,
                ref,
                scheduledDateTime,
                DoseActionType.snooze,
                Icons.snooze,
                Colors.orange,
                'Snooze',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            context,
            ref,
            scheduledDateTime,
            DoseActionType.cancel,
            Icons.cancel,
            Colors.red,
            'Cancel Dose',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    DateTime scheduledDateTime,
    DoseActionType actionType,
    IconData icon,
    Color color,
    String label, {
    bool isCompact = false,
  }) {
    return isCompact
        ? IconButton(
            onPressed: () => _handleDoseAction(context, ref, scheduledDateTime, actionType),
            icon: Icon(icon, color: color),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          )
        : ElevatedButton.icon(
            onPressed: () => _handleDoseAction(context, ref, scheduledDateTime, actionType),
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionType == DoseActionType.cancel ? null : color,
              foregroundColor: actionType == DoseActionType.cancel ? color : Colors.white,
              side: actionType == DoseActionType.cancel ? BorderSide(color: color) : null,
            ),
          );
  }

  Future<void> _handleDoseAction(
    BuildContext context,
    WidgetRef ref,
    DateTime scheduledDateTime,
    DoseActionType actionType,
  ) async {
    try {
      switch (actionType) {
        case DoseActionType.take:
          await _takeDose(context, ref, scheduledDateTime);
          break;
        case DoseActionType.snooze:
          await _snoozeDose(context, ref, scheduledDateTime);
          break;
        case DoseActionType.cancel:
          await _cancelDose(context, ref, scheduledDateTime);
          break;
      }
      onActionCompleted?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takeDose(BuildContext context, WidgetRef ref, DateTime scheduledDateTime) async {
    final now = DateTime.now();
    
    // Create or update dose log
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
      await ref.read(doseLogListProvider.notifier).updateDoseLog(doseLog.copyWith(id: existingDoseLog!.id));
    } else {
      await ref.read(doseLogListProvider.notifier).addDoseLog(doseLog);
      
      // Get the created dose log to mark as taken (which handles stock deduction)
      final doseLogsAsync = ref.read(doseLogListProvider);
      final doseLogs = await doseLogsAsync.when(
        data: (logs) async => logs,
        loading: () async => <DoseLog>[],
        error: (_, __) async => <DoseLog>[],
      );
      
      final createdDoseLog = doseLogs.cast<DoseLog>().firstWhere(
        (log) => log.medicationId == schedule.medicationId &&
                log.scheduledTime == scheduledDateTime &&
                log.status == DoseStatus.taken,
        orElse: () => throw Exception('Created dose log not found'),
      );
      
      // Stock deduction is handled in the provider when marking as taken
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

    // Cancel the notification for this specific dose
    final notificationService = NotificationService();
    final notificationId = _generateNotificationId(schedule.id!, scheduledDateTime);
    await notificationService.cancelNotification(notificationId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Dose taken! Stock has been updated.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _snoozeDose(BuildContext context, WidgetRef ref, DateTime scheduledDateTime) async {
    if (!context.mounted) return;

    // Show snooze options dialog
    final snoozeMinutes = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Reminder'),
        content: const Text('How long would you like to snooze this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(5),
            child: const Text('5 min'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(15),
            child: const Text('15 min'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(30),
            child: const Text('30 min'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(60),
            child: const Text('1 hour'),
          ),
        ],
      ),
    );

    if (snoozeMinutes == null) return;

    // Cancel current notification
    final notificationService = NotificationService();
    final notificationId = _generateNotificationId(schedule.id!, scheduledDateTime);
    await notificationService.cancelNotification(notificationId);

    // Schedule new notification for snoozed time
    final medicationAsync = ref.read(medicationByIdProvider(schedule.medicationId));
    final medication = await medicationAsync.when(
      data: (med) async => med,
      loading: () async => null,
      error: (_, __) async => null,
    );

    if (medication != null) {
      final snoozeDateTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
      await notificationService.scheduleNotificationForSchedule(
        schedule: schedule,
        medication: medication,
        scheduledDate: snoozeDateTime,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ Reminder snoozed for $snoozeMinutes minutes'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _cancelDose(BuildContext context, WidgetRef ref, DateTime scheduledDateTime) async {
    if (!context.mounted) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Dose'),
        content: const Text('Are you sure you want to cancel this dose? This will mark it as skipped.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
      await ref.read(doseLogListProvider.notifier).updateDoseLog(doseLog.copyWith(id: existingDoseLog!.id));
    } else {
      await ref.read(doseLogListProvider.notifier).addDoseLog(doseLog);
    }

    // Cancel the notification for this specific dose
    final notificationService = NotificationService();
    final notificationId = _generateNotificationId(schedule.id!, scheduledDateTime);
    await notificationService.cancelNotification(notificationId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Dose cancelled (marked as skipped)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime _getScheduledDateTimeForToday() {
    final now = DateTime.now();
    final timeParts = schedule.timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    
    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
  }

  int _generateNotificationId(int scheduleId, DateTime date) {
    final dateString = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return int.parse('$scheduleId$dateString') % 2147483647;
  }
}
