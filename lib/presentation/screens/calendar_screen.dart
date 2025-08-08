import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';
import 'package:dosifi_flutter/data/models/dose_log.dart';
import 'package:dosifi_flutter/presentation/providers/schedule_provider.dart';
import 'package:dosifi_flutter/presentation/providers/dose_log_provider.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/presentation/widgets/dose_action_buttons.dart';

enum CalendarView { month, week, day }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarView _currentView = CalendarView.month;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider);
    final doseLogsAsync = ref.watch(doseLogListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_module),
            onSelected: (view) {
              setState(() {
                _currentView = view;
                switch (view) {
                  case CalendarView.month:
                    _calendarFormat = CalendarFormat.month;
                    break;
                  case CalendarView.week:
                    _calendarFormat = CalendarFormat.twoWeeks;
                    break;
                  case CalendarView.day:
                    _calendarFormat = CalendarFormat.week;
                    break;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarView.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month),
                    SizedBox(width: 8),
                    Text('Month'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.week,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week),
                    SizedBox(width: 8),
                    Text('Week'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.day,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Day'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          schedulesAsync.when(
            data: (schedules) => _buildCalendar(schedules, doseLogsAsync.value ?? []),
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SizedBox(
              height: 300,
              child: Center(child: Text('Error: $error')),
            ),
          ),
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentView) {
      case CalendarView.month:
        return DateFormat('MMMM yyyy').format(_focusedDay);
      case CalendarView.week:
        final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}';
      case CalendarView.day:
        return DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay);
    }
  }

  Widget _buildCalendar(List<Schedule> schedules, List<DoseLog> doseLogs) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: TableCalendar<_CalendarEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: (day) => _getEventsForDate(day, schedules, doseLogs),
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.red[600]),
          holidayTextStyle: TextStyle(color: Colors.red[600]),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.green[600],
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

  List<_CalendarEvent> _getEventsForDate(DateTime day, List<Schedule> schedules, List<DoseLog> doseLogs) {
    final events = <_CalendarEvent>[];
    
    // Add scheduled doses for this date
    for (final schedule in schedules) {
      if (schedule.isActiveOnDate(day)) {
        final timeParts = schedule.timeOfDay.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
        final scheduledDateTime = DateTime(day.year, day.month, day.day, hour, minute);
        
        // Check if there's a corresponding dose log
        final doseLog = doseLogs.firstWhere(
          (log) => log.medicationId == schedule.medicationId &&
                   isSameDay(log.scheduledTime, scheduledDateTime) &&
                   log.scheduledTime.hour == hour &&
                   log.scheduledTime.minute == minute,
          orElse: () => DoseLog(
            id: null,
            medicationId: schedule.medicationId,
            scheduleId: schedule.id,
            scheduledTime: scheduledDateTime,
            status: DoseStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
        
        events.add(_CalendarEvent(
          schedule: schedule,
          doseLog: doseLog.id != null ? doseLog : null,
          scheduledTime: scheduledDateTime,
        ));
      }
    }
    
    return events;
  }

  Widget _buildEventsList() {
    final schedulesAsync = ref.watch(scheduleListProvider);
    final doseLogsAsync = ref.watch(doseLogListProvider);

    return schedulesAsync.when(
      data: (schedules) {
        final doseLogs = doseLogsAsync.value ?? [];
        final events = _getEventsForDate(_selectedDay, schedules, doseLogs);
        
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No doses scheduled for ${DateFormat('MMMM d, yyyy').format(_selectedDay)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(event);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildEventCard(_CalendarEvent event) {
    final medicationAsync = ref.watch(medicationByIdProvider(event.schedule.medicationId));
    final isCompleted = event.doseLog?.status == DoseStatus.taken;
    final isMissed = event.doseLog?.status == DoseStatus.missed;
    final isCancelled = event.doseLog?.status == DoseStatus.skipped;
    final isOverdue = !isCompleted && !isMissed && !isCancelled && event.scheduledTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isCompleted 
                      ? Colors.green 
                      : isMissed 
                          ? Colors.red 
                          : isCancelled
                              ? Colors.grey
                              : isOverdue 
                                  ? Colors.orange 
                                  : Theme.of(context).primaryColor,
                  child: Icon(
                    isCompleted 
                        ? Icons.check 
                        : isMissed 
                            ? Icons.close 
                            : isCancelled
                                ? Icons.cancel
                                : isOverdue 
                                    ? Icons.warning 
                                    : Icons.medication,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      medicationAsync.when(
                        data: (medication) => Text(
                          medication?.name ?? 'Unknown Medication',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        loading: () => const Text('Loading...'),
                        error: (_, __) => Text('Medication ID: ${event.schedule.medicationId}'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('HH:mm').format(event.scheduledTime)} - ${event.schedule.doseAmount} ${event.schedule.doseUnit}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (event.doseLog?.takenTime != null)
                        Text(
                          'Taken at ${DateFormat('HH:mm').format(event.doseLog!.takenTime!)}',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show dose action buttons for today's or future doses that aren't completed
            if (!isCompleted && !isMissed && (isSameDay(event.scheduledTime, DateTime.now()) || event.scheduledTime.isAfter(DateTime.now())))
              DoseActionButtons(
                schedule: event.schedule,
                scheduledDateTime: event.scheduledTime,
                existingDoseLog: event.doseLog,
                isCompact: false,
                onActionCompleted: () {
                  // Refresh the state after action is completed
                  ref.invalidate(doseLogListProvider);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarEvent {
  final Schedule schedule;
  final DoseLog? doseLog;
  final DateTime scheduledTime;

  _CalendarEvent({
    required this.schedule,
    required this.doseLog,
    required this.scheduledTime,
  });
}

