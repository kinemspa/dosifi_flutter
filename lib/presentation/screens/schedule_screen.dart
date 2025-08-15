import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';
import 'package:dosifi_flutter/data/models/dose_log.dart';
import 'package:dosifi_flutter/presentation/providers/schedule_provider.dart';
import 'package:dosifi_flutter/presentation/providers/dose_log_provider.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/services/notification_service.dart';
import 'package:dosifi_flutter/presentation/widgets/dose_action_buttons.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/label_chip.dart';
import 'package:dosifi_flutter/core/utils/compact_form_sheet.dart';
import 'package:dosifi_flutter/presentation/screens/add_schedule_screen.dart';
import 'package:dosifi_flutter/presentation/providers/schedule_layout_provider.dart';
import 'package:dosifi_flutter/core/widgets/info_sheet.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Today'),
                      icon: Icon(Icons.today, size: 18),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Calendar'),
                      icon: Icon(Icons.calendar_month, size: 18),
                    ),
                    ButtonSegment<int>(
                      value: 2,
                      label: Text('Schedules'),
                      icon: Icon(Icons.schedule, size: 18),
                    ),
                  ],
                  selected: {_tabController.index},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _tabController.animateTo(newSelection.first);
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(WidgetState.selected)) {
                          return theme.colorScheme.primaryContainer;
                        }
                        return theme.colorScheme.surface;
                      },
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'About Schedule',
                  icon: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  onPressed: () {
                    InfoSheet.show(
                      context,
                      title: 'Schedule',
                      message: 'View your medication schedules in three ways:\n\n• Today: See and manage today\'s doses\n• Calendar: View doses on a calendar\n• Schedules: Manage all medication schedules',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(schedulesAsync),
                _buildCalendarTab(schedulesAsync),
                _buildSchedulesTab(schedulesAsync),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'test_notification',
            mini: true,
            onPressed: _testNotification,
            child: const Icon(Icons.notifications),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_schedule',
            onPressed: _showAddScheduleDialog,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab(AsyncValue<List<Schedule>> schedulesAsync) {
    return schedulesAsync.when(
      data: (schedules) {
        final todaySchedules = _getSchedulesForDay(schedules, DateTime.now());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Doses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (todaySchedules.isEmpty)
                _buildEmptyState('No doses scheduled for today')
              else
                ...todaySchedules.map((schedule) => _buildTodayDoseCard(schedule)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildTodayDoseCard(Schedule schedule) {
    final layout = ref.watch(scheduleLayoutProvider);
    switch (layout) {
      case ScheduleCardLayout.outlinedClassic:
        return _todayOutlinedClassic(schedule);
      case ScheduleCardLayout.outlinedSoft:
        return _todayOutlinedSoft(schedule);
      case ScheduleCardLayout.outlinedShadow:
        return _todayOutlinedShadow(schedule);
      case ScheduleCardLayout.outlinedAccentBar:
        return _todayOutlinedAccentBar(schedule);
      case ScheduleCardLayout.outlinedPill:
        return _todayOutlinedPill(schedule);
      case ScheduleCardLayout.outlinedDense:
        return _todayOutlinedDense(schedule);
      case ScheduleCardLayout.outlinedDivider:
        return _todayOutlinedDivider(schedule);
      case ScheduleCardLayout.outlinedMonochrome:
        return _todayOutlinedMonochrome(schedule);
      case ScheduleCardLayout.outlinedCompactChips:
        return _todayOutlinedCompactChips(schedule);
      case ScheduleCardLayout.outlinedLargeTitle:
        return _todayOutlinedLargeTitle(schedule);
    }
  }
  Widget _todayOutlinedClassic(Schedule schedule) {
    final timeParts = schedule.timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    final medicationAsync = ref.watch(medicationByIdProvider(schedule.medicationId));

    // Check if dose has been taken today
    final today = DateTime.now();
    final scheduledDateTime = DateTime(today.year, today.month, today.day, hour, minute);

    final doseLogsAsync = ref.watch(doseLogListProvider);
    final existingDoseLog = doseLogsAsync.when(
      data: (doseLogs) {
        try {
          return doseLogs.firstWhere(
            (log) =>
                log.medicationId == schedule.medicationId &&
                log.scheduledTime.year == scheduledDateTime.year &&
                log.scheduledTime.month == scheduledDateTime.month &&
                log.scheduledTime.day == scheduledDateTime.day &&
                log.scheduledTime.hour == scheduledDateTime.hour &&
                log.scheduledTime.minute == scheduledDateTime.minute,
          );
        } catch (e) {
          return null;
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface.withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    medicationAsync.when(
                      data: (medication) => Text(
                        medication?.name ?? 'Unknown Medication',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      loading: () => const Text('Loading...'),
                      error: (_, __) => Text('Medication ID: ${schedule.medicationId}'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${scheduledDateTime.day}/${scheduledDateTime.month}/${scheduledDateTime.year}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    Text('${schedule.doseAmount} ${schedule.doseUnit}', style: TextStyle(color: Colors.grey[600])),
                    medicationAsync.when(
                      data: (medication) => medication != null
                          ? Text(medication.displayStrength, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              DoseActionButtons(
                schedule: schedule,
                scheduledDateTime: scheduledDateTime,
                existingDoseLog: existingDoseLog,
                isCompact: true,
                onActionCompleted: () {
                  // Refresh the state after action is completed
                  ref.invalidate(doseLogListProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Delegate other variants to the classic implementation for now
  Widget _todayOutlinedSoft(Schedule schedule) => _todayOutlinedClassic(schedule);
  Widget _todayOutlinedShadow(Schedule schedule) => _todayOutlinedClassic(schedule);
  Widget _todayOutlinedAccentBar(Schedule schedule) => _todayOutlinedClassic(schedule);
  Widget _todayOutlinedPill(Schedule schedule) => _todayOutlinedClassic(schedule);
  Widget _todayOutlinedDense(Schedule schedule) => _todayOutlinedClassic(schedule);
  Widget _todayOutlinedDivider(Schedule schedule) => _todayOutlinedClassic(schedule);
  Widget _todayOutlinedMonochrome(Schedule schedule) => _todayOutlinedClassic(schedule);
  Widget _todayOutlinedCompactChips(Schedule schedule) => _todayOutlinedClassic(schedule);
  Widget _todayOutlinedLargeTitle(Schedule schedule) => _todayOutlinedClassic(schedule);

  Widget _buildCalendarTab(AsyncValue<List<Schedule>> schedulesAsync) {
    return schedulesAsync.when(
      data: (schedules) {
        // TODO: Implement calendar view using DosifiCalendar widget
        return const Center(child: Text('Calendar view coming soon'));
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildSchedulesTab(AsyncValue<List<Schedule>> schedulesAsync) {
    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return _buildEmptyState('No schedules created yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return _buildFullScheduleCard(schedule);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildFullScheduleCard(Schedule schedule) {
    final layout = ref.watch(scheduleLayoutProvider);
    switch (layout) {
      case ScheduleCardLayout.outlinedClassic:
        return _fullOutlinedClassic(schedule);
      case ScheduleCardLayout.outlinedSoft:
        return _fullOutlinedSoft(schedule);
      case ScheduleCardLayout.outlinedShadow:
        return _fullOutlinedShadow(schedule);
      case ScheduleCardLayout.outlinedAccentBar:
        return _fullOutlinedAccentBar(schedule);
      case ScheduleCardLayout.outlinedPill:
        return _fullOutlinedPill(schedule);
      case ScheduleCardLayout.outlinedDense:
        return _fullOutlinedDense(schedule);
      case ScheduleCardLayout.outlinedDivider:
        return _fullOutlinedDivider(schedule);
      case ScheduleCardLayout.outlinedMonochrome:
        return _fullOutlinedMonochrome(schedule);
      case ScheduleCardLayout.outlinedCompactChips:
        return _fullOutlinedCompactChips(schedule);
      case ScheduleCardLayout.outlinedLargeTitle:
        return _fullOutlinedLargeTitle(schedule);
    }
  }
  Widget _fullOutlinedClassic(Schedule schedule) {
    final medicationAsync = ref.watch(medicationByIdProvider(schedule.medicationId));

    return CompactCard(
      accentColor: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showEditScheduleDialog(schedule),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 0.8),
            ),
            alignment: Alignment.center,
            child: Text(
              schedule.timeOfDay,
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: medicationAsync.when(
                        data: (medication) => Text(
                          medication?.name ?? 'Unknown Medication',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        loading: () => const Text('Loading...'),
                        error: (_, __) => Text('Medication ID: ${schedule.medicationId}'),
                      ),
                    ),
                    LabelChip(
                      icon: Icons.event_repeat,
                      label: ScheduleType.fromString(schedule.scheduleType).displayName,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    LabelChip(icon: Icons.schedule, label: schedule.timeOfDay, color: Colors.blueGrey),
                    LabelChip(
                      icon: Icons.local_fire_department,
                      label: '${schedule.doseAmount} ${schedule.doseUnit}',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    LabelChip(
                      icon: Icons.calendar_today,
                      label:
                          'From ${DateFormat('MMM dd, yyyy').format(schedule.startDate)}'
                          '${schedule.endDate != null ? ' • To ${DateFormat('MMM dd, yyyy').format(schedule.endDate!)}' : ''}',
                      color: Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  // Delegate other variants to the classic implementation for now
  Widget _fullOutlinedSoft(Schedule schedule) => _fullOutlinedClassic(schedule);
  Widget _fullOutlinedShadow(Schedule schedule) => _fullOutlinedClassic(schedule);
  Widget _fullOutlinedAccentBar(Schedule schedule) => _fullOutlinedClassic(schedule);
  Widget _fullOutlinedPill(Schedule schedule) => _fullOutlinedClassic(schedule);
  Widget _fullOutlinedDense(Schedule schedule) => _fullOutlinedClassic(schedule);
  Widget _fullOutlinedDivider(Schedule schedule) => _fullOutlinedClassic(schedule);
  Widget _fullOutlinedMonochrome(Schedule schedule) => _fullOutlinedClassic(schedule);
  Widget _fullOutlinedCompactChips(Schedule schedule) => _fullOutlinedClassic(schedule);
  Widget _fullOutlinedLargeTitle(Schedule schedule) => _fullOutlinedClassic(schedule);

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddScheduleDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Schedule'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    final timeParts = schedule.timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    final medicationAsync = ref.watch(medicationByIdProvider(schedule.medicationId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          title: medicationAsync.when(
            data: (medication) => Text(
              medication?.name ?? 'Unknown Medication',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            loading: () => const Text('Loading...'),
            error: (_, __) => Text(
              'Medication ID: ${schedule.medicationId}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Chip(
                  label: Text(
                    ScheduleType.fromString(schedule.scheduleType).displayName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                ),
                const SizedBox(width: 8),
                medicationAsync.when(
                  data: (medication) => medication != null
                      ? Text(medication.displayStrength, style: TextStyle(color: Colors.grey[600], fontSize: 12))
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditScheduleDialog(schedule),
                tooltip: 'Edit schedule',
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                onPressed: () => _markDoseAsTaken(schedule),
                tooltip: 'Mark today taken',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteSchedule(schedule.id!),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayUpcomingTab(AsyncValue<List<Schedule>> schedulesAsync) {
    return schedulesAsync.when(
      data: (schedules) {
        final todaySchedules = _getSchedulesForDay(schedules, DateTime.now());
        final upcomingSchedules = _getUpcomingSchedules(schedules);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (todaySchedules.isEmpty)
                const Text('No schedules for today')
              else
                ...todaySchedules.map((schedule) => _buildScheduleCard(schedule)),

              const SizedBox(height: 24),
              Text('Upcoming', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (upcomingSchedules.isEmpty)
                const Text('No upcoming schedules')
              else
                ...upcomingSchedules.map((schedule) => _buildScheduleCard(schedule)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  List<Schedule> _getSchedulesForDay(List<Schedule> schedules, DateTime day) {
    return schedules.where((schedule) {
      // Use the schedule's built-in method to check if it's active on this date
      return schedule.isActiveOnDate(day);
    }).toList();
  }

  List<Schedule> _getUpcomingSchedules(List<Schedule> schedules) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final nextWeek = now.add(const Duration(days: 7));

    return schedules.where((schedule) {
      if (!schedule.isActive) return false;

      // Get schedules from tomorrow up to next week
      for (var day = tomorrow; day.isBefore(nextWeek); day = day.add(const Duration(days: 1))) {
        if (_getSchedulesForDay([schedule], day).isNotEmpty) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  void _testNotification() async {
    final notificationService = NotificationService();
    await notificationService.showInstantNotification(title: 'Test Notification', body: 'This is a test notification.');
  }

  void _showAddScheduleDialog() {
    showCompactFormSheet(context, title: 'Add Schedule', child: const AddScheduleScreen(compactSheetMode: true));
  }

  void _showEditScheduleDialog(Schedule schedule) {
    showCompactFormSheet(
      context,
      title: 'Edit Schedule',
      child: AddScheduleScreen(scheduleId: schedule.id.toString(), compactSheetMode: true),
    );
  }

  void _deleteSchedule(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text(
          'Are you sure you want to delete this schedule? This will also remove all future planned doses.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // First, clean up future dose logs for this schedule
        await _cleanupFutureDoses(id);

        // Then delete the schedule
        await ref.read(scheduleListProvider.notifier).deleteSchedule(id);

        // Cancel any notifications for this schedule
        final notificationService = NotificationService();
        await notificationService.cancelNotificationsForSchedule(id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule and future doses deleted!'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting schedule: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _cleanupFutureDoses(int scheduleId) async {
    try {
      final doseLogsAsync = ref.read(doseLogListProvider);
      final doseLogs = await doseLogsAsync.when(
        data: (logs) async => logs,
        loading: () async => <DoseLog>[],
        error: (_, __) async => <DoseLog>[],
      );

      final now = DateTime.now();
      final futureDoses = doseLogs
          .where(
            (log) => log.scheduleId == scheduleId && log.scheduledTime.isAfter(now) && log.status == DoseStatus.pending,
          )
          .toList();

      for (final dose in futureDoses) {
        if (dose.id != null) {
          await ref.read(doseLogListProvider.notifier).deleteDoseLog(dose.id!);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up future doses: $e');
    }
  }

  void _snoozeDose(Schedule schedule) {
    // Implementation for snoozing a dose
    DateTime.now(); // Placeholder
  }

  void _markDoseAsTaken(Schedule schedule) async {
    // Create a dose log entry for today at the scheduled time
    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(schedule.timeOfDay.split(':')[0]),
      int.parse(schedule.timeOfDay.split(':')[1]),
    );

    // First create a pending dose log
    final doseLog = DoseLog.create(
      medicationId: schedule.medicationId,
      scheduleId: schedule.id,
      scheduledTime: scheduledDateTime,
      status: DoseStatus.pending,
      doseAmount: schedule.doseAmount, // Include the dose amount
    );

    try {
      // Add the dose log first
      await ref.read(doseLogListProvider.notifier).addDoseLog(doseLog);

      // Get the created dose log ID to mark it as taken (which will deduct stock)
      final doseLogsAsync = ref.read(doseLogListProvider);
      final doseLogs = await doseLogsAsync.when(
        data: (logs) async => logs,
        loading: () async => <DoseLog>[],
        error: (_, __) async => <DoseLog>[],
      );

      final createdDoseLog = doseLogs.cast<DoseLog>().firstWhere(
        (log) =>
            log.medicationId == schedule.medicationId &&
            log.scheduledTime == scheduledDateTime &&
            log.status == DoseStatus.pending,
        orElse: () => throw Exception('Created dose log not found'),
      );

      // Mark as taken with stock deduction
      await ref
          .read(doseLogListProvider.notifier)
          .markDoseAsTaken(createdDoseLog.id!, takenTime: now, doseAmount: schedule.doseAmount);

      // Refresh medication list to show updated stock
      ref.invalidate(medicationListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dose taken! Stock has been updated.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error marking dose as taken: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
