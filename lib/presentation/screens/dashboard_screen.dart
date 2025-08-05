import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../providers/medication_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/dose_log_provider.dart';
import '../../data/models/schedule.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
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
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false, // Don't show back button on root screen
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _showNotificationsBottomSheet(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 16),
              _buildTodaysMedications(context),
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
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.timeline, color: Theme.of(context).colorScheme.primary),
        title: Text('Recent Activities', style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text('Log of recent medication activities'),
      ),
    );
  }

  Widget _buildAlerts(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text('Alerts', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.error)),
              ],
            ),
            const SizedBox(height: 8),
            Text('No missed doses today!', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
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

  Widget _buildWelcomeCard(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.primaryGradient,
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.waving_hand, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            schedulesAsync.when(
              data: (schedules) {
                final todaysSchedules = _getTodaysSchedules(schedules);
                return Text(
                  'You have ${todaysSchedules.length} ${todaysSchedules.length == 1 ? 'medication' : 'medications'} scheduled for today',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                );
              },
              loading: () => Text(
                'Loading your schedule...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              error: (_, __) => Text(
                'Unable to load today\'s schedule',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysMedications(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Today\'s Medications', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            schedulesAsync.when(
              data: (schedules) {
                final todaysSchedules = _getTodaysSchedules(schedules);
                if (todaysSchedules.isEmpty) {
                  return const Text('No medications scheduled for today', style: TextStyle(color: Colors.grey));
                }

                return Column(
                  children: todaysSchedules.map((schedule) {
                    return _buildMedicationItemWithId(
                      context,
                      schedule.medicationId,
                      schedule.timeOfDay,
                      '${schedule.doseAmount} ${schedule.doseUnit}',
                      false, // Assume not taken initially
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItemWithId(BuildContext context, int medicationId, String time, String dose, bool taken) {
    final medicationAsync = ref.watch(medicationByIdProvider(medicationId));
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            taken ? Icons.check_circle : Icons.schedule,
            color: taken ? AppTheme.successColor : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                medicationAsync.when(
                  data: (medication) => Text(
                    medication?.name ?? 'Unknown Medication',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('Error loading medication'),
                ),
                Row(
                  children: [
                    Text(time, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Text('• $dose', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          if (!taken) ...[  
            TextButton(
              onPressed: () {
                // TODO: Mark as taken
              },
              child: const Text('Take'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                // TODO: Snooze dose
              },
              child: const Text('Snooze'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationItem(BuildContext context, String name, String time, bool taken) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            taken ? Icons.check_circle : Icons.schedule,
            color: taken ? AppTheme.successColor : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyLarge),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (!taken)
            TextButton(
              onPressed: () {
                // TODO: Mark as taken
              },
              child: const Text('Take'),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context, '12', 'Total Medications', Icons.medication),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(context, '95%', 'Adherence Rate', Icons.trending_up),
        ),
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
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(context, Icons.add, 'Add Medication', () {
                  context.go('/inventory');
                }),
                _buildActionButton(context, Icons.schedule, 'View Schedule', () {
                  context.go('/schedule');
                }),
                _buildActionButton(context, Icons.analytics, 'Analytics', () {
                  context.go('/analytics');
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    'Medication Reminder',
                    'Time to take your Vitamin D - 1000 IU',
                    '2 minutes ago',
                    Icons.medication,
                    Colors.blue,
                  ),
                  _buildNotificationItem(
                    'Low Stock Alert',
                    'Omega-3 capsules running low (3 remaining)',
                    '1 hour ago',
                    Icons.warning,
                    Colors.orange,
                  ),
                  _buildNotificationItem(
                    'Expiration Warning',
                    'Multivitamin expires in 5 days',
                    '1 day ago',
                    Icons.schedule,
                    Colors.red,
                  ),
                  _buildNotificationItem(
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

  Widget _buildNotificationItem(
    String title,
    String message,
    String time,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

