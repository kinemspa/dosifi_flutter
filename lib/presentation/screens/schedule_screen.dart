import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_router.dart';
import '../../data/models/schedule.dart';
import '../../data/models/dose_log.dart';
import '../providers/schedule_provider.dart';
import '../providers/dose_log_provider.dart';
import '../providers/medication_provider.dart';
import '../../data/dose_options.dart';
import '../../services/notification_service.dart';
import 'calendar_screen.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
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

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Today', icon: Icon(Icons.today)),
                Tab(text: 'Calendar', icon: Icon(Icons.calendar_month)),
                Tab(text: 'All Schedules', icon: Icon(Icons.schedule)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(schedulesAsync),
                _buildCalendarTab(schedulesAsync),
                _buildAllSchedulesTab(schedulesAsync),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "test_notification",
            mini: true,
            onPressed: _testNotification,
            child: const Icon(Icons.notifications),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "add_schedule",
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildTodayDoseCard(Schedule schedule) {
    final timeParts = schedule.timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    final medicationAsync = ref.watch(medicationByIdProvider(schedule.medicationId));
    
    // Check if dose has been taken today
    final today = DateTime.now();
    final scheduledDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      hour,
      minute,
    );
    
    final doseLogsAsync = ref.watch(doseLogListProvider);
    final isDoseTaken = doseLogsAsync.when(
      data: (doseLogs) {
        return doseLogs.any((log) => 
          log.medicationId == schedule.medicationId &&
          log.scheduledTime.year == scheduledDateTime.year &&
          log.scheduledTime.month == scheduledDateTime.month &&
          log.scheduledTime.day == scheduledDateTime.day &&
          log.scheduledTime.hour == scheduledDateTime.hour &&
          log.scheduledTime.minute == scheduledDateTime.minute &&
          log.status == DoseStatus.taken
        );
      },
      loading: () => false,
      error: (_, __) => false,
    );
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
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
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                    '${schedule.doseAmount} ${schedule.doseUnit}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  medicationAsync.when(
                    data: (medication) => medication != null 
                        ? Text(
                            medication.displayStrength,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDoseTaken)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  )
                else ...[
                  ElevatedButton(
                    onPressed: () => _markDoseAsTaken(schedule),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Take'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _snoozeDose(schedule),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: const Text('Snooze'),
                  ),
                ],
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }


  Widget _buildAllSchedulesTab(AsyncValue<List<Schedule>> schedulesAsync) {
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
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildFullScheduleCard(Schedule schedule) {
    final medicationAsync = ref.watch(medicationByIdProvider(schedule.medicationId));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: medicationAsync.when(
                    data: (medication) => Text(
                      medication?.name ?? 'Unknown Medication',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    loading: () => const Text('Loading...'),
                    error: (_, __) => Text('Medication ID: ${schedule.medicationId}'),
                  ),
                ),
                Chip(
                  label: Text(
                    ScheduleType.fromString(schedule.scheduleType).displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Time: ${schedule.timeOfDay}'),
                const Spacer(),
                Icon(Icons.medication, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('${schedule.doseAmount} ${schedule.doseUnit}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('From: ${DateFormat('MMM dd, yyyy').format(schedule.startDate)}'),
                if (schedule.endDate != null) ...[
                  const SizedBox(width: 16),
                  Text('To: ${DateFormat('MMM dd, yyyy').format(schedule.endDate!)}'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditScheduleDialog(schedule),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteSchedule(schedule.id!),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
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
    // Parse time from timeOfDay string (format: "HH:mm")
    final timeParts = schedule.timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    
    // Get medication details
    final medicationAsync = ref.watch(medicationByIdProvider(schedule.medicationId));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: medicationAsync.when(
          data: (medication) => Text(
            medication?.name ?? 'Unknown Medication',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => Text(
            'Medication ID: ${schedule.medicationId}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ScheduleType.fromString(schedule.scheduleType).displayName),
            medicationAsync.when(
              data: (medication) => medication != null 
                  ? Text(
                      medication.displayStrength,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditScheduleDialog(schedule),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () => _markDoseAsTaken(schedule),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSchedule(schedule.id!),
            ),
          ],
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
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (todaySchedules.isEmpty)
                const Text('No schedules for today')
              else
                ...todaySchedules.map((schedule) => _buildScheduleCard(schedule)),
              
              const SizedBox(height: 24),
              Text(
                'Upcoming',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildCalendarTab(AsyncValue<List<Schedule>> schedulesAsync) {
    return const CalendarScreen();
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
    await notificationService.showInstantNotification(
      title: 'Test Notification',
      body: 'This is a test notification.',
    );
  }

  void _showAddScheduleDialog() {
    context.navigateToAddSchedule();
  }

  void _showEditScheduleDialog(Schedule schedule) {
    context.navigateToEditSchedule(schedule.id.toString());
  }

  void _deleteSchedule(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule? This will also remove all future planned doses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
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
            const SnackBar(
              content: Text('Schedule and future doses deleted!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting schedule: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
      final futureDoses = doseLogs.where((log) => 
        log.scheduleId == scheduleId && 
        log.scheduledTime.isAfter(now) && 
        log.status == DoseStatus.pending
      ).toList();
      
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
        (log) => log.medicationId == schedule.medicationId &&
                log.scheduledTime == scheduledDateTime &&
                log.status == DoseStatus.pending,
        orElse: () => throw Exception('Created dose log not found'),
      );
      
      // Mark as taken with stock deduction
      await ref.read(doseLogListProvider.notifier).markDoseAsTaken(
        createdDoseLog.id!,
        takenTime: now,
        doseAmount: schedule.doseAmount,
      );
      
      // Refresh medication list to show updated stock
      ref.invalidate(medicationListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dose taken! Stock has been updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking dose as taken: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
