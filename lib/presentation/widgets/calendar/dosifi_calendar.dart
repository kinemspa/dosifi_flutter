import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';
import 'package:dosifi_flutter/data/models/dose_log.dart';
import 'package:dosifi_flutter/presentation/providers/schedule_provider.dart';
import 'package:dosifi_flutter/presentation/providers/dose_log_provider.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/presentation/widgets/dose_action_buttons.dart';
import 'package:dosifi_flutter/data/repositories/schedule_override_repository.dart';
import 'package:dosifi_flutter/data/models/schedule_override.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/label_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dosifi_flutter/core/widgets/info_sheet.dart';

/// Reusable calendar widget for Dosifi. Extracted from the previous CalendarScreen
/// so it can be embedded anywhere (e.g., full screen on navbar, or compact embeds).
class DosifiCalendar extends ConsumerStatefulWidget {
  const DosifiCalendar({super.key});

  @override
  ConsumerState<DosifiCalendar> createState() => _DosifiCalendarState();
}

enum CalendarView { month, week, day }

class _DosifiCalendarState extends ConsumerState<DosifiCalendar> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarView _currentView = CalendarView.month;
  final EventController<_CalendarEvent> _controller =
      EventController<_CalendarEvent>();
  List<CalendarEventData<_CalendarEvent>> _addedEvents = [];

  // Cached for debounced rebuilds
  List<Schedule> _lastSchedules = const [];
  List<DoseLog> _lastDoseLogs = const [];
  Timer? _debounce;

  // Filters
  final Set<int> _selectedMedicationIds = {};
  final Set<_StatusFilter> _selectedStatuses = {
    _StatusFilter.pending,
    _StatusFilter.taken,
    _StatusFilter.missed,
    _StatusFilter.skipped,
  };

  @override
  void initState() {
    super.initState();
    _loadFilterPrefs();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider);
    final doseLogsAsync = ref.watch(doseLogListProvider);

    return Column(
      children: [
        // Filters-only header: minimal legend + Filters button with badge
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              _tinyLegend(context),
              const Spacer(),
              _activeFilterSummaryChip(),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Calendar help',
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  InfoSheet.show(
                    context,
                    title: 'Calendar',
                    message:
                        'View your upcoming doses by month, week, or day. Tap a cell to see and act on doses for that date. Use filters to limit medications or statuses.',
                  );
                },
              ),
              _filtersButtonWithBadge(context),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: PopupMenuButton<CalendarView>(
              icon: const Icon(Icons.view_module),
              onSelected: (view) {
                setState(() {
                  _currentView = view;
                });
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: CalendarView.month,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_view_month),
                      SizedBox(width: 8),
                      Text('Month'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: CalendarView.week,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_view_week),
                      SizedBox(width: 8),
                      Text('Week'),
                    ],
                  ),
                ),
                PopupMenuItem(
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
          ),
        ),
        schedulesAsync.when(
          data: (schedules) {
            final doseLogs = doseLogsAsync.value ?? [];
            _rebuildEvents(schedules, doseLogs);
            return CompactCard(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              child: _buildCalendarView(),
            );
          },
          loading: () => const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SizedBox(
            height: 300,
            child: Center(child: Text('Error: $error')),
          ),
        ),
        Expanded(child: _buildEventsList()),
      ],
    );
  }

  Widget _buildCalendarView() {
    switch (_currentView) {
      case CalendarView.month:
        return SizedBox(
          height: _calendarHeight(context, fallback: 380),
          child: MonthView(
            controller: _controller,
            onCellTap: (events, date) {
              setState(() {
                _selectedDay = date;
                _focusedDay = date;
              });
              if (events.isNotEmpty) {
                _showEventDetailsBottomSheet(events);
              }
            },
            onPageChange: (date, pageIndex) {
              setState(() {
                _focusedDay = date;
              });
            },
          ),
        );
      case CalendarView.week:
        return SizedBox(
          height: _calendarHeight(context, fallback: 320),
          child: WeekView(
            controller: _controller,
            onEventTap: (events, date) {
              setState(() {
                _selectedDay = date;
                _focusedDay = date;
              });
              if (events.isNotEmpty) {
                _showEventDetailsBottomSheet(events);
              }
            },
            onPageChange: (date, pageIndex) {
              setState(() {
                _focusedDay = date;
              });
            },
          ),
        );
      case CalendarView.day:
        return SizedBox(
          height: _calendarHeight(context, fallback: 520),
          child: DayView(
            controller: _controller,
            onEventTap: (events, date) {
              setState(() {
                _selectedDay = date;
                _focusedDay = date;
              });
              if (events.isNotEmpty) {
                _showEventDetailsBottomSheet(events);
              }
            },
            onPageChange: (date, pageIndex) {
              setState(() {
                _focusedDay = date;
              });
            },
          ),
        );
    }
  }

  double _calendarHeight(BuildContext context, {double fallback = 360}) {
    final h = MediaQuery.of(context).size.height;
    // Use up to ~40% of screen height for calendar view, bounded by fallback
    final target = h * 0.4;
    // Clamp between 280 and fallback
    return target.clamp(280.0, fallback);
  }

  void _rebuildEvents(List<Schedule> schedules, List<DoseLog> doseLogs) {
    _lastSchedules = List<Schedule>.from(schedules);
    _lastDoseLogs = List<DoseLog>.from(doseLogs);
    // Clear existing by removing the last added events snapshot
    if (_addedEvents.isNotEmpty) {
      _controller.removeAll(_addedEvents);
      _addedEvents = [];
    }
    final List<CalendarEventData<_CalendarEvent>> data = [];

    // We’ll generate events for a reasonable window around the focused month/week/day
    final start = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      1,
    ).subtract(const Duration(days: 7));
    final end = DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0,
    ).add(const Duration(days: 7));

    for (
      DateTime day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      for (final schedule in schedules) {
        if (schedule.isActiveOnDate(day)) {
          final timeParts = schedule.timeOfDay.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
          final startDt = DateTime(day.year, day.month, day.day, hour, minute);
          final endDt = startDt.add(const Duration(minutes: 30));

          final doseLog = doseLogs.firstWhere(
            (log) =>
                log.medicationId == schedule.medicationId &&
                log.scheduledTime.year == startDt.year &&
                log.scheduledTime.month == startDt.month &&
                log.scheduledTime.day == startDt.day &&
                log.scheduledTime.hour == hour &&
                log.scheduledTime.minute == minute,
            orElse: () => DoseLog(
              id: null,
              medicationId: schedule.medicationId,
              scheduleId: schedule.id,
              scheduledTime: startDt,
              status: DoseStatus.pending,
              createdAt: DateTime.now(),
            ),
          );

          final meta = _CalendarEvent(
            schedule: schedule,
            doseLog: doseLog.id != null ? doseLog : null,
            scheduledTime: startDt,
          );
          if (!_passesFilter(meta)) continue;
          final color = _eventColor(meta);
          final medName =
              _medicationNameMap()[schedule.medicationId] ??
              'Medication ${schedule.medicationId}';
          data.add(
            CalendarEventData<_CalendarEvent>(
              date: DateTime(day.year, day.month, day.day),
              startTime: startDt,
              endTime: endDt,
              title: medName,
              description:
                  '${schedule.doseAmount} ${schedule.doseUnit} • ${schedule.timeOfDay}',
              color: color,
              event: meta,
            ),
          );
        }
      }
    }

    _controller.addAll(data);
    _addedEvents = data;
  }

  Widget _buildEventsList() {
    final schedulesAsync = ref.watch(scheduleListProvider);
    final doseLogsAsync = ref.watch(doseLogListProvider);

    return schedulesAsync.when(
      data: (schedules) {
        final doseLogs = doseLogsAsync.value ?? [];
        final events = _computeEventsForDate(
          _selectedDay,
          schedules,
          doseLogs,
        ).where(_passesFilter).toList();

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No doses scheduled for ${DateFormat('MMMM d, yyyy').format(_selectedDay)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
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
    final medicationAsync = ref.watch(
      medicationByIdProvider(event.schedule.medicationId),
    );
    final isCompleted = event.doseLog?.status == DoseStatus.taken;
    final isMissed = event.doseLog?.status == DoseStatus.missed;
    final isCancelledByLog = event.doseLog?.status == DoseStatus.skipped;
    final isOverdue =
        !isCompleted &&
        !isMissed &&
        !isCancelledByLog &&
        event.scheduledTime.isBefore(DateTime.now());

    final overrideRepo = ScheduleOverrideRepository();

    return FutureBuilder<ScheduleOverride?>(
      future: event.schedule.id == null
          ? Future.value(null)
          : overrideRepo.getOverrideForDate(
              event.schedule.id!,
              event.scheduledTime,
            ),
      builder: (context, snapshot) {
        final override = snapshot.data;
        final isCancelled =
            isCancelledByLog || (override?.isCancelled ?? false);
        final displayTimeStr =
            (override?.timeOfDay != null && (override!.timeOfDay!.isNotEmpty))
            ? override.timeOfDay!
            : DateFormat('HH:mm').format(event.scheduledTime);
        final displayDoseAmount =
            override?.doseAmount ?? event.schedule.doseAmount;
        final displayDoseUnit = override?.doseUnit ?? event.schedule.doseUnit;
        final hasEdits =
            override != null &&
            !override.isCancelled &&
            ((override.timeOfDay != null && override.timeOfDay!.isNotEmpty) ||
                override.doseAmount != null ||
                override.doseUnit != null);

        return CompactCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                          loading: () => const Text('Loading...'),
                          error: (_, __) => Text(
                            'Medication ID: ${event.schedule.medicationId}',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$displayTimeStr - $displayDoseAmount $displayDoseUnit',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.grey[600],
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                        if (event.doseLog?.takenTime != null)
                          Text(
                            'Taken at ${DateFormat('HH:mm').format(event.doseLog!.takenTime!)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isCancelled)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: LabelChip(
                        label: 'Cancelled (override)',
                        icon: Icons.cancel,
                        color: Colors.grey,
                      ),
                    )
                  else if (hasEdits)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: LabelChip(
                        label: 'Edited',
                        icon: Icons.edit,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (!isCompleted &&
                  !isMissed &&
                  !isCancelled &&
                  (_isSameDay(event.scheduledTime, DateTime.now()) ||
                      event.scheduledTime.isAfter(DateTime.now())))
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DoseActionButtons(
                        schedule: event.schedule,
                        scheduledDateTime: event.scheduledTime,
                        existingDoseLog: event.doseLog,
                        isCompact: false,
                        onActionCompleted: () {
                          ref.invalidate(doseLogListProvider);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: const Text('Edit this day'),
                      onPressed: () {
                        _showEditDayDialog(
                          context,
                          event.schedule,
                          event.scheduledTime,
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDayDialog(
    BuildContext context,
    Schedule schedule,
    DateTime day,
  ) {
    final timeController = TextEditingController(
      text: DateFormat('HH:mm').format(day),
    );
    final doseController = TextEditingController(
      text: schedule.doseAmount.toString(),
    );
    String unit = schedule.doseUnit;
    bool cancel = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${DateFormat('MMM d, yyyy').format(day)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Time'),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: timeController,
                    decoration: const InputDecoration(hintText: 'HH:mm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Dose'),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: doseController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(hintText: 'Amount'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: unit,
                  items:
                      <String>[
                            'mg',
                            'mcg',
                            'g',
                            'mL',
                            'units',
                            'tablet',
                            'capsule',
                            'drops',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        unit = v;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setLocal) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cancel this day'),
                  value: cancel,
                  onChanged: (v) {
                    setLocal(() {
                      cancel = v ?? false;
                    });
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: () async {
              final notifier = ref.read(scheduleListProvider.notifier);
              final time = timeController.text.trim();
              final dose = double.tryParse(doseController.text.trim());
              await notifier.setDayOverride(
                scheduleId: schedule.id!,
                date: day,
                timeOfDay: cancel
                    ? null
                    : (time.isNotEmpty ? time : schedule.timeOfDay),
                doseAmount: cancel ? null : dose,
                doseUnit: cancel ? null : unit,
                isCancelled: cancel,
              );
              if (context.mounted) Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  List<_CalendarEvent> _computeEventsForDate(
    DateTime day,
    List<Schedule> schedules,
    List<DoseLog> doseLogs,
  ) {
    final events = <_CalendarEvent>[];
    for (final schedule in schedules) {
      if (schedule.isActiveOnDate(day)) {
        final timeParts = schedule.timeOfDay.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
        final scheduledDateTime = DateTime(
          day.year,
          day.month,
          day.day,
          hour,
          minute,
        );
        final match = doseLogs.firstWhere(
          (log) =>
              log.medicationId == schedule.medicationId &&
              log.scheduledTime.year == scheduledDateTime.year &&
              log.scheduledTime.month == scheduledDateTime.month &&
              log.scheduledTime.day == scheduledDateTime.day &&
              log.scheduledTime.hour == scheduledDateTime.hour &&
              log.scheduledTime.minute == scheduledDateTime.minute,
          orElse: () => DoseLog(
            id: null,
            medicationId: schedule.medicationId,
            scheduleId: schedule.id,
            scheduledTime: scheduledDateTime,
            status: DoseStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
        events.add(
          _CalendarEvent(
            schedule: schedule,
            doseLog: match.id != null ? match : null,
            scheduledTime: scheduledDateTime,
          ),
        );
      }
    }
    return events;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Filters UI

  bool _passesFilter(_CalendarEvent e) {
    final medsOk =
        _selectedMedicationIds.isEmpty ||
        _selectedMedicationIds.contains(e.schedule.medicationId);
    final status = _deriveStatus(e);
    final statusOk = _selectedStatuses.contains(status);
    return medsOk && statusOk;
  }

  _StatusFilter _deriveStatus(_CalendarEvent e) {
    switch (e.doseLog?.status) {
      case DoseStatus.taken:
        return _StatusFilter.taken;
      case DoseStatus.missed:
        return _StatusFilter.missed;
      case DoseStatus.skipped:
        return _StatusFilter.skipped;
      default:
        return _StatusFilter.pending;
    }
  }

  String _statusLabel(_StatusFilter s) {
    switch (s) {
      case _StatusFilter.pending:
        return 'Pending';
      case _StatusFilter.taken:
        return 'Taken';
      case _StatusFilter.missed:
        return 'Missed';
      case _StatusFilter.skipped:
        return 'Skipped';
    }
  }

  // Color helpers
  Color _eventColor(_CalendarEvent e) {
    // Status coloring takes precedence
    if (e.doseLog?.status == DoseStatus.taken) return Colors.green.shade600;
    if (e.doseLog?.status == DoseStatus.missed) return Colors.red.shade600;
    if (e.doseLog?.status == DoseStatus.skipped) return Colors.grey;
    // Overdue pending -> orange, else medication color
    final overdue =
        e.scheduledTime.isBefore(DateTime.now()) &&
        !_isSameDay(e.scheduledTime, DateTime.now());
    return overdue
        ? Colors.orange.shade700
        : _colorForMedication(e.schedule.medicationId);
  }

  Color _colorForMedication(int medicationId) {
    // Simple deterministic hashing to choose a color from a palette
    const palette = [
      Colors.blue,
      Colors.indigo,
      Colors.teal,
      Colors.purple,
      Colors.cyan,
      Colors.deepOrange,
      Colors.amber,
      Colors.lightGreen,
      Colors.pink,
      Colors.brown,
    ];
    final idx = medicationId.abs() % palette.length;
    return palette[idx].shade600;
  }

  void _showEventDetailsBottomSheet(List<CalendarEventData<Object?>> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, controller) {
            final first = events.isNotEmpty
                ? events.first.event as _CalendarEvent?
                : null;
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                if (first != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CompactCard(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick actions',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DoseActionButtons(
                            schedule: first.schedule,
                            scheduledDateTime: first.scheduledTime,
                            existingDoseLog: first.doseLog,
                            isCompact: true,
                            onActionCompleted: () {
                              ref.invalidate(doseLogListProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ...List.generate(events.length, (index) {
                  final ev = events[index].event as _CalendarEvent?;
                  if (ev == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildEventCard(ev),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadFilterPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final medIds = prefs.getStringList('calendar_filter_meds') ?? [];
    final statuses = prefs.getStringList('calendar_filter_status') ?? [];
    setState(() {
      _selectedMedicationIds
        ..clear()
        ..addAll(medIds.map((e) => int.tryParse(e)).whereType<int>());
      _selectedStatuses
        ..clear()
        ..addAll(statuses.map(_statusFromKey));
      if (_selectedStatuses.isEmpty) {
        _selectedStatuses.addAll(_StatusFilter.values);
      }
    });
  }

  Future<void> _saveFilterPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'calendar_filter_meds',
      _selectedMedicationIds.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'calendar_filter_status',
      _selectedStatuses.map(_statusKey).toList(),
    );
  }

  Map<int, String> _medicationNameMap() {
    final meds = ref.read(medicationListProvider).value ?? [];
    return {
      for (final m in meds)
        if (m.id != null) m.id!: m.name,
    };
  }

  void _debouncedRebuild() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted && (_lastSchedules.isNotEmpty || _lastDoseLogs.isNotEmpty)) {
        _rebuildEvents(_lastSchedules, _lastDoseLogs);
      }
    });
  }

  String _statusKey(_StatusFilter s) {
    switch (s) {
      case _StatusFilter.pending:
        return 'pending';
      case _StatusFilter.taken:
        return 'taken';
      case _StatusFilter.missed:
        return 'missed';
      case _StatusFilter.skipped:
        return 'skipped';
    }
  }

  _StatusFilter _statusFromKey(String k) {
    switch (k) {
      case 'taken':
        return _StatusFilter.taken;
      case 'missed':
        return _StatusFilter.missed;
      case 'skipped':
        return _StatusFilter.skipped;
      case 'pending':
      default:
        return _StatusFilter.pending;
    }
  }

  // Minimal legend row used by modes A and B
  Widget _tinyLegend(BuildContext context) {
    Widget dot(Color c, String t) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Row(
      children: [
        dot(Colors.green.shade600, 'Taken'),
        const SizedBox(width: 6),
        dot(Colors.red.shade600, 'Missed'),
        const SizedBox(width: 6),
        dot(Colors.grey, 'Skipped'),
        const SizedBox(width: 6),
        dot(Colors.orange.shade700, 'Overdue'),
        const SizedBox(width: 6),
        dot(Theme.of(context).primaryColor, 'Pending'),
      ],
    );
  }

  // Active filter summary chip shown next to the Filters button
  Widget _activeFilterSummaryChip() {
    final medCount = _selectedMedicationIds.length;
    final deselectedStatuses =
        _StatusFilter.values.length - _selectedStatuses.length;
    if (medCount == 0 && deselectedStatuses == 0)
      return const SizedBox.shrink();
    final parts = <String>[];
    if (medCount > 0) parts.add('$medCount meds');
    if (deselectedStatuses > 0) parts.add('$deselectedStatuses status off');
    final label = parts.join(', ');
    final cs = Theme.of(context).colorScheme;
    return InputChip(
      avatar: Icon(Icons.filter_alt, size: 16, color: cs.onSurface),
      label: Text(label, style: TextStyle(color: cs.onSurface)),
      backgroundColor: cs.surface,
      selectedColor: cs.primary,
      side: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
      onPressed: _showFiltersSheet,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Filters button that opens bottom sheet (with badge)
  Widget _filtersButtonWithBadge(BuildContext context) {
    final deselectedStatuses =
        _StatusFilter.values.length - _selectedStatuses.length;
    final activeCount =
        _selectedMedicationIds.length +
        (deselectedStatuses > 0 ? deselectedStatuses : 0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filters',
          onPressed: _showFiltersSheet,
        ),
        if (activeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$activeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  // Bottom sheet used by modes A and B
  Future<void> _showFiltersSheet() async {
    final medsAsync = ref.read(medicationListProvider);
    final meds = medsAsync.value ?? [];
    final tempMeds = Set<int>.from(_selectedMedicationIds);
    final tempStatuses = Set<_StatusFilter>.from(_selectedStatuses);
    final searchCtl = TextEditingController();
    String query = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              final filteredMeds = meds
                  .where(
                    (m) => m.name.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 8),
                      const Text(
                        'Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          tempMeds.clear();
                          tempStatuses
                            ..clear()
                            ..addAll(_StatusFilter.values);
                          setLocal(() {
                            query = '';
                            searchCtl.clear();
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchCtl,
                    decoration: const InputDecoration(
                      hintText: 'Search medications',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setLocal(() {
                      query = v;
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Medications',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          final allIds = meds
                              .map((m) => m.id)
                              .whereType<int>()
                              .toList();
                          setState(() {
                            tempMeds
                              ..clear()
                              ..addAll(allIds);
                          });
                        },
                        icon: const Icon(Icons.select_all, size: 18),
                        label: const Text('Select all'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            tempMeds.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: filteredMeds.length,
                      itemBuilder: (context, index) {
                        final m = filteredMeds[index];
                        final id = m.id;
                        if (id == null) return const SizedBox.shrink();
                        final selected = tempMeds.contains(id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                tempMeds.add(id);
                              } else {
                                tempMeds.remove(id);
                              }
                            });
                          },
                          title: Text(m.name),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Wrap(
                    spacing: 6,
                    children: _StatusFilter.values.map((s) {
                      final on = tempStatuses.contains(s);
                      final cs = Theme.of(context).colorScheme;
                      return FilterChip(
                        label: Text(
                          _statusLabel(s),
                          style: TextStyle(
                            color: on ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                        selected: on,
                        selectedColor: cs.primary,
                        backgroundColor: cs.surface,
                        side: BorderSide(
                          color: cs.onSurface.withValues(alpha: 0.2),
                        ),
                        showCheckmark: false,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              tempStatuses.add(s);
                            } else {
                              tempStatuses.remove(s);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _selectedMedicationIds
                            ..clear()
                            ..addAll(tempMeds);
                          _selectedStatuses
                            ..clear()
                            ..addAll(tempStatuses);
                        });
                        await _saveFilterPrefs();
                        _debouncedRebuild();
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _StatusFilter { pending, taken, missed, skipped }

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
