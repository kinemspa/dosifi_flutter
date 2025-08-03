import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../data/models/schedule.dart';
import '../../data/models/dose_log.dart';
import '../../data/models/medication.dart';
import '../providers/schedule_provider.dart';
import '../providers/dose_log_provider.dart';
import '../providers/medication_provider.dart';
import '../../data/dose_options.dart';

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
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _markDoseAsTaken(schedule),
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
              onPressed: () => Navigator.pop(context),
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
                  Navigator.pop(context);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dose marked as taken!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking dose as taken: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
