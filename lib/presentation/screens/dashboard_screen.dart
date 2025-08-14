import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/core/theme/app_theme.dart';
import 'package:dosifi_flutter/presentation/providers/medication_provider.dart';
import 'package:dosifi_flutter/presentation/providers/schedule_provider.dart';
import 'package:dosifi_flutter/presentation/providers/dose_log_provider.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';
import 'package:dosifi_flutter/presentation/providers/dose_scheduling_provider.dart';
import 'package:dosifi_flutter/services/notification_service.dart';
import 'package:dosifi_flutter/presentation/widgets/dose_action_buttons.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';
import 'package:dosifi_flutter/core/widgets/label_chip.dart';
import 'package:dosifi_flutter/core/services/stock_management_service.dart';
import 'package:dosifi_flutter/core/widgets/info_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize dose scheduling when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDoseScheduling();
    });
  }

  Future<void> _initializeDoseScheduling() async {
    try {
      // Initialize notifications first
      final notificationService = NotificationService();
      await notificationService.requestAndInitialize();

      // Initialize today's doses and upcoming doses
      final doseScheduling = ref.read(doseSchedulingProvider.notifier);
      await doseScheduling.initializeTodaysDoses();
      await doseScheduling.generateUpcomingDoses();
      await doseScheduling.processOverdueDoses();
    } catch (e) {
      debugPrint('🚨 Error initializing dose scheduling: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  List<Schedule> _getTodaysSchedules(List<Schedule> schedules) {
    final today = DateTime.now();
    return schedules.where((schedule) => schedule.isActiveOnDate(today)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Ask for confirmation before exiting the app
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Exit')),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeAndTodayCard(context),
              const SizedBox(height: 12),
              _buildNextDoseBanner(context),
              const SizedBox(height: 16),
              _buildAlertsSummary(context),
              const SizedBox(height: 16),
              _buildQuickStats(context),
              const SizedBox(height: 16),
              _buildRecentActivities(context),
              const SizedBox(height: 16),
              _buildAlerts(context),
              const SizedBox(height: 16),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextDoseBanner(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider);
    return schedulesAsync.when(
      data: (schedules) {
        final now = DateTime.now();
        Schedule? next;
        DateTime? nextDateTime;

        // Consider today's active schedules after now
        for (final s in schedules.where((s) => s.isActiveOnDate(now))) {
          final parts = s.timeOfDay.split(':');
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
          final dt = DateTime(now.year, now.month, now.day, hour, minute);
          if (dt.isAfter(now)) {
            if (nextDateTime == null || dt.isBefore(nextDateTime!)) {
              next = s;
              nextDateTime = dt;
            }
          }
        }

        if (next == null || nextDateTime == null) {
          return const SizedBox.shrink();
        }

        final remaining = nextDateTime!.difference(now);
        final remainingText = _formatRemaining(remaining);

        return CompactCard(
          accentColor: Theme.of(context).colorScheme.primary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.alarm, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next dose in $remainingText',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${nextDateTime!.hour.toString().padLeft(2, '0')}:${nextDateTime!.minute.toString().padLeft(2, '0')} • ${next!.doseAmount} ${next!.doseUnit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              DoseActionButtons(
                schedule: next!,
                scheduledDateTime: nextDateTime,
                isCompact: true,
                onActionCompleted: () {
                  ref.invalidate(doseLogListProvider);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inMinutes < 1) return 'moments';
    if (d.inHours < 1) return '${d.inMinutes} min';
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
  }

  Widget _buildRecentActivities(BuildContext context) {
    return CompactCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.timeline, color: Theme.of(context).colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Log of recent medication activities',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const LabelChip(icon: Icons.open_in_new, label: 'View'),
        ],
      ),
    );
  }

  Widget _buildAlerts(BuildContext context) {
    return CompactCard(
      accentColor: Theme.of(context).colorScheme.error,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning, color: Theme.of(context).colorScheme.error, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alerts',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('No missed doses today!', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              tooltip: 'About alerts',
              onPressed: () {
                InfoSheet.show(
                  context,
                  title: 'Alerts',
                  message: 'Summary of important items like missed doses. Detailed stock/expiry alerts are available in Supplies.',
                );
              },
            ),
          ],
        ),
    );
  }

  String _getMedicationName(int medicationId) {
    final medicationAsync = ref.watch(medicationByIdProvider(medicationId));
    return medicationAsync.when(
      data: (medication) => medication?.name ?? 'Unknown Medication',
      loading: () => 'Loading...',
      error: (_, __) => 'Error',
    );
  }

  Widget _buildWelcomeAndTodayCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: AppTheme.primaryGradient),
      padding: const EdgeInsets.all(16.0),
      child: const _WelcomeAndTodayContent(),
    );
  }

}

class _WelcomeAndTodayContent extends ConsumerWidget {
  const _WelcomeAndTodayContent();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  List<Schedule> _getTodaysSchedules(List<Schedule> schedules) {
    final today = DateTime.now();
    return schedules.where((s) => s.isActiveOnDate(today)).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(scheduleListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.waving_hand, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'About Dashboard',
              icon: const Icon(Icons.info_outline, size: 18, color: Colors.white),
              onPressed: () {
                InfoSheet.show(
                  context,
                  title: 'Dashboard',
                  message: 'Overview of your medication activity and today\'s doses. Tap Take/Snooze to update your log.',
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        schedulesAsync.when(
          data: (schedules) {
            final todays = _getTodaysSchedules(schedules);
            return Text(
              'You have ${todays.length} ${todays.length == 1 ? 'medication' : 'medications'} scheduled for today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            );
          },
          loading: () => Text('Loading your schedule...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
          error: (_, __) => Text('Unable to load today\'s schedule', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
        ),
        const SizedBox(height: 12),
        Text("Today's Medications", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        // List section on a light surface for readability
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(12),
          child: schedulesAsync.when(
            data: (schedules) {
              final todays = _getTodaysSchedules(schedules);
              if (todays.isEmpty) {
                return Text(
                  'No medications scheduled for today',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
                );
              }
              return Column(children: [
                for (final schedule in todays) _MedicationRow(schedule: schedule),
              ]);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
          ),
        ),
      ],
    );
  }
}

class _MedicationRow extends ConsumerWidget {
  final Schedule schedule;
  const _MedicationRow({required this.schedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationAsync = ref.watch(medicationByIdProvider(schedule.medicationId));
    final today = DateTime.now();
    final timeParts = schedule.timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    final scheduledDateTime = DateTime(today.year, today.month, today.day, hour, minute);

    final doseLogsAsync = ref.watch(doseLogListProvider);
    final existingDoseLog = doseLogsAsync.when(
      data: (doseLogs) {
        try {
          return doseLogs.firstWhere((log) =>
              log.medicationId == schedule.medicationId &&
              log.scheduledTime.year == scheduledDateTime.year &&
              log.scheduledTime.month == scheduledDateTime.month &&
              log.scheduledTime.day == scheduledDateTime.day &&
              log.scheduledTime.hour == scheduledDateTime.hour &&
              log.scheduledTime.minute == scheduledDateTime.minute);
        } catch (_) {
          return null;
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            existingDoseLog?.status.name == 'taken' ? Icons.check_circle : Icons.schedule,
            color: existingDoseLog?.status.name == 'taken' ? AppTheme.successColor : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                medicationAsync.when(
                  data: (medication) => Text(medication?.name ?? 'Unknown Medication', style: Theme.of(context).textTheme.bodyLarge),
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('Error loading medication'),
                ),
                Row(children: [
                  Text(schedule.timeOfDay, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Text('• ${scheduledDateTime.day}/${scheduledDateTime.month}/${scheduledDateTime.year}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                ]),
                Row(children: [
                  Text('${schedule.doseAmount} ${schedule.doseUnit}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                ]),
              ],
            ),
          ),
          DoseActionButtons(
            schedule: schedule,
            scheduledDateTime: scheduledDateTime,
            existingDoseLog: existingDoseLog,
            isCompact: true,
            onActionCompleted: () {
              ref.invalidate(doseLogListProvider);
            },
          ),
        ],
      ),
    );
  }
}


  Widget _buildAlertsSummary(BuildContext context) {
    return FutureBuilder<StockStatus>(
      future: StockManagementService.getStockStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CompactCard(
            child: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Loading alerts...'),
              ],
            ),
          );
        }
        final status = snapshot.data!;
        return CompactCard(
          accentColor: Theme.of(context).colorScheme.error,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.health_and_safety, color: Colors.red, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    LabelChip(icon: Icons.inventory_2, label: 'Low: ${status.lowStockCount}', color: Colors.orange),
                    LabelChip(icon: Icons.error, label: 'Expired: ${status.expiredCount}', color: Colors.red),
                    LabelChip(icon: Icons.schedule, label: 'Soon: ${status.expiringSoonCount}', color: Colors.amber),
                  ],
                ),
              ),
              const LabelChip(icon: Icons.open_in_new, label: 'View'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, '12', 'Total Medications', Icons.medication)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(context, '95%', 'Adherence Rate', Icons.trending_up)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(context, Icons.medication, 'Medications', () {
                  context.go('/medications');
                }),
                _buildActionButton(context, Icons.inventory_2, 'Supplies', () {
                  context.go('/supplies');
                }),
                _buildActionButton(context, Icons.schedule, 'Schedule', () {
                  context.go('/schedule');
                }),
                _buildActionButton(context, Icons.calendar_month, 'Calendar', () {
                  context.go('/calendar');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildNotificationItem(
                    context,
                    'Medication Reminder',
                    'Time to take your Vitamin D - 1000 IU',
                    '2 minutes ago',
                    Icons.medication,
                    Colors.blue,
                  ),
                  _buildNotificationItem(
                    context,
                    'Low Stock Alert',
                    'Omega-3 capsules running low (3 remaining)',
                    '1 hour ago',
                    Icons.warning,
                    Colors.orange,
                  ),
                  _buildNotificationItem(
                    context,
                    'Expiration Warning',
                    'Multivitamin expires in 5 days',
                    '1 day ago',
                    Icons.schedule,
                    Colors.red,
                  ),
                  _buildNotificationItem(
                    context,
                    'Dose Taken',
                    'Morning dose of Vitamin D marked as taken',
                    '2 days ago',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, String title, String message, String time, IconData icon, Color iconColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
