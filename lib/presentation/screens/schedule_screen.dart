import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/schedule.dart';
import '../providers/schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Schedule'),
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const Divider(height: 1),
          Expanded(
            child: schedulesAsync.when(
              data: (schedules) {
                final schedulesForDay = _getSchedulesForDay(schedules, _selectedDay!);
                
                if (schedulesForDay.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No schedules for this day',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedulesForDay.length,
                  itemBuilder: (context, index) {
                    final schedule = schedulesForDay[index];
                    return _buildScheduleCard(schedule);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<Schedule>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        }
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    // Parse time from timeOfDay string (format: "HH:mm")
    final timeParts = schedule.timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    
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
        title: Text(
          'Medication ID: ${schedule.medicationId}', // This would be populated with actual medication name
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(schedule.scheduleType),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_active, size: 20),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () {
                // TODO: Mark as taken
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as taken')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Schedule> _getSchedulesForDay(List<Schedule> schedules, DateTime day) {
    return schedules.where((schedule) {
      // Check if the schedule is active on this day
      if (!schedule.isActive) return false;
      
      // Check if the day is within the schedule's date range
      if (schedule.startDate.isAfter(day)) return false;
      if (schedule.endDate != null && schedule.endDate!.isBefore(day)) return false;
      
      // Check if it matches the repeat pattern
      // TODO: Implement proper repeat pattern matching
      return true;
    }).toList();
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Schedule'),
        content: const Text('Schedule creation feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
