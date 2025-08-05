import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/schedule.dart';
import '../../data/models/dose_log.dart';
import '../providers/schedule_provider.dart';
import '../providers/dose_log_provider.dart';
import '../providers/medication_provider.dart';
import '../../data/dose_options.dart';
import '../../services/notification_service.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  late TabController _tabController;
  late EventController _eventController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _eventController = EventController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        bottom: TabBar(
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(schedulesAsync),
          _buildCalendarTab(schedulesAsync),
          _buildAllSchedulesTab(schedulesAsync),
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarWithEvents(AsyncValue<List<Schedule>> schedulesAsync) {
    return schedulesAsync.when(
      data: (schedules) {
        // Convert schedules to calendar events
        final events = <CalendarEventData>[];
        for (final schedule in schedules) {
          // Generate events for the next 90 days
          final now = DateTime.now();
          final endDate = now.add(const Duration(days: 90));
          
          for (var date = now; date.isBefore(endDate); date = date.add(const Duration(days: 1))) {
            if (schedule.isActiveOnDate(date)) {
              final timeParts = schedule.timeOfDay.split(':');
              final hour = int.parse(timeParts[0]);
              final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
              
              final eventDateTime = DateTime(date.year, date.month, date.day, hour, minute);
              
              events.add(CalendarEventData(
                title: 'Dose: Schedule ${schedule.id}',
                date: eventDateTime,
                startTime: eventDateTime,
                endTime: eventDateTime.add(const Duration(minutes: 30)),
                color: Theme.of(context).primaryColor,
              ));
            }
          }
        }
        
        _eventController.addAll(events);
        
        return MonthView(
          controller: _eventController,
          onDateLongPress: (date) => setState(() => _selectedDay = date),
          onEventTap: (event, date) {
            // Handle event tap
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Dose scheduled at ${DateFormat('HH:mm').format(date)}')),
            );
          },
          cellAspectRatio: 0.6,
          headerBuilder: (date) => Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateFormat('MMMM yyyy').format(date),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading calendar')),
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
    return _buildCalendarWithEvents(schedulesAsync);
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
    final medicationsAsync = ref.watch(medicationListProvider);
    int? selectedMedicationId;
    TimeOfDay? selectedTime;
    final daysOfWeek = <int>{};
    DateTime? startDate;
    DateTime? endDate;
    var scheduleType = ScheduleType.daily;
    
    // Dose fields
    var doseAmount = 1.0;
    var doseUnit = 'tablet';
    var doseForm = 'tablet';
    var strengthPerUnit = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Schedule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medication Dropdown
                medicationsAsync.when(
                  data: (medications) => DropdownButtonFormField<int>(
                    value: selectedMedicationId,
                    decoration: const InputDecoration(
                      labelText: 'Select Medication *',
                      border: OutlineInputBorder(),
                    ),
                    items: medications.map((medication) => DropdownMenuItem<int>(
                      value: medication.id,
                      child: Text(
                        '${medication.name} (${medication.displayStrength})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMedicationId = value;
                        // Reset dose unit when medication changes and populate strength
                        if (value != null) {
                          final medication = medications.firstWhere((med) => med.id == value);
                          final availableOptions = getDoseOptions(medication.type);
                          if (availableOptions.isNotEmpty) {
                            doseUnit = availableOptions.first.unit;
                          }
                          // Set strength per unit from medication
                          strengthPerUnit = medication.strengthPerUnit;
                          doseForm = medication.type.name;
                        }
                      });
                    },
                    validator: (value) => value == null ? 'Please select a medication' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error loading medications: $error'),
                ),
                const SizedBox(height: 12),

                // Time Picker
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time of Day *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : 'Select time',
                      style: selectedTime != null
                          ? null
                          : TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Start Date
                ElevatedButton(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (selectedDate != null) {
                      setState(() => startDate = selectedDate);
                    }
                  },
                  child: Text(
                    startDate == null
                        ? 'Select Start Date'
                        : 'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}',
                  ),
                ),
                const SizedBox(height: 12),

                // End Date (optional)
                ElevatedButton(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (selectedDate != null) {
                      setState(() => endDate = selectedDate);
                    }
                  },
                  child: Text(
                    endDate == null
                        ? 'Select End Date (optional)'
                        : 'End Date: ${DateFormat('yyyy-MM-dd').format(endDate!)}',
                  ),
                ),
                const SizedBox(height: 12),

                // Schedule Type
                DropdownButtonFormField<ScheduleType>(
                  value: scheduleType,
                  onChanged: (value) => setState(() => scheduleType = value!),
                  decoration: const InputDecoration(
                    labelText: 'Schedule Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ScheduleType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  )).toList(),
                ),
                const SizedBox(height: 12),

                // Days of the Week (only for weekly schedules)
                if (scheduleType == ScheduleType.weekly)
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) => index + 1).map((day) => FilterChip(
                      label: Text(DateFormat.E().format(DateTime(2021, 1, day))),
                      selected: daysOfWeek.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            daysOfWeek.add(day);
                          } else {
                            daysOfWeek.remove(day);
                          }
                        });
                      },
                    )).toList(),
                  ),
                const SizedBox(height: 16),
                
                // Dose Information Section
                Text(
                  'Dose Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Dose Amount
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Dose Amount *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 1',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: doseAmount.toString(),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      setState(() => doseAmount = parsed);
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Dose Unit
                DropdownButtonFormField<String>(
                  value: selectedMedicationId != null ? doseUnit : null,
                  decoration: const InputDecoration(
                    labelText: 'Dose Unit *',
                    border: OutlineInputBorder(),
                  ),
                  items: selectedMedicationId != null
                      ? medicationsAsync.when(
                          data: (medications) {
                            final medication = medications.firstWhere((med) => med.id == selectedMedicationId);
                            final availableOptions = getDoseOptions(medication.type);
                            return availableOptions.map((option) =>
                              DropdownMenuItem(value: option.unit, child: Text(option.displayName))
                            ).toList();
                          },
                          loading: () => <DropdownMenuItem<String>>[],
                          error: (_, __) => <DropdownMenuItem<String>>[],
                        )
                      : <DropdownMenuItem<String>>[],
                    onChanged: (value) {
                      setState(() {
                        final previousUnit = doseUnit;
                        doseUnit = value!;
                        
                        // Convert dose amount based on unit change
                        if (strengthPerUnit > 0) {
                          if (previousUnit == 'tablet' || previousUnit == 'capsule') {
                            // Converting from tablet/capsule to mg
                            if (doseUnit == 'mg') {
                              doseAmount = doseAmount * strengthPerUnit;
                            }
                          } else if (previousUnit == 'mg') {
                            // Converting from mg to tablet/capsule
                            if (doseUnit == 'tablet' || doseUnit == 'capsule') {
                              doseAmount = doseAmount / strengthPerUnit;
                            }
                          }
                        }
                      });
                    },
                ),
                const SizedBox(height: 12),
                
                // Dose Form
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Dose Form *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., tablet, capsule, liquid',
                  ),
                  initialValue: doseForm,
                  onChanged: (value) => setState(() => doseForm = value),
                ),
                const SizedBox(height: 12),
                
                // Strength Per Unit
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Strength Per Unit (mg) *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 2.0 (for 2mg per tablet)',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: strengthPerUnit.toString(),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      setState(() => strengthPerUnit = parsed);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedMedicationId != null && selectedTime != null && startDate != null) {
                  // Format time as HH:mm string
                  final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                  
                  final schedule = Schedule.create(
                    medicationId: selectedMedicationId!,
                    scheduleType: scheduleType.name,
                    timeOfDay: timeString,
                    daysOfWeek: daysOfWeek.isNotEmpty ? daysOfWeek.toList() : null,
                    startDate: startDate!,
                    endDate: endDate,
                    doseAmount: doseAmount,
                    doseUnit: doseUnit,
                    doseForm: doseForm,
                    strengthPerUnit: strengthPerUnit,
                  );
                  await ref.read(scheduleListProvider.notifier).addSchedule(schedule);
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                  // Show validation error
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditScheduleDialog(Schedule schedule) {
    // TODO: Implement edit schedule functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit schedule functionality coming soon!')),
    );
  }

  void _deleteSchedule(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
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
      await ref.read(scheduleListProvider.notifier).deleteSchedule(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted!'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    final doseLog = DoseLog.create(
      medicationId: schedule.medicationId,
      scheduleId: schedule.id,
      scheduledTime: scheduledDateTime,
      takenTime: now,
      status: DoseStatus.taken,
    );

    try {
      await ref.read(doseLogListProvider.notifier).addDoseLog(doseLog);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dose marked as taken!'),
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
