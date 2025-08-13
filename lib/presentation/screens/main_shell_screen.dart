import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;
  final String? currentPath;

  const MainShellScreen({super.key, required this.child, this.currentPath});

  int _currentIndexFromPath(String? path) {
    switch (path) {
      case '/':
        return 0;
      case '/medications':
        return 1;
      case '/schedule':
        return 2;
      case '/calendar':
        return 3;
      case '/supplies':
        return 4;
      case '/settings':
        return 5;
      default:
        return 0;
    }
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/medications');
        break;
      case 2:
        context.go('/schedule');
        break;
      case 3:
        context.go('/calendar');
        break;
      case 4:
        context.go('/supplies');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndexFromPath(currentPath);
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        automaticallyImplyLeading: true,
        actions: [
          if (currentPath == '/')
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                _showNotificationsBottomSheet(context);
              },
              tooltip: 'Notifications',
            ),
          if (currentPath != '/medications')
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'About this screen',
              onPressed: () {
                final title = _getScreenTitle();
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [const Icon(Icons.info_outline), const SizedBox(width: 8), Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 12),
                        Text(_infoForPath(currentPath ?? '/'), style: Theme.of(ctx).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      drawer: _buildNavigationDrawer(context),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onNavTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Meds',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Supplies',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  String _getScreenTitle() {
    switch (currentPath) {
      case '/':
        return 'Home';
      case '/medications':
        return 'Medications';
      case '/supplies':
        return 'Supplies';
      case '/schedule':
        return 'Schedule';
      case '/calendar':
        return 'Calendar';
      case '/test/notifications':
        return 'Notification Testing';
      case '/settings':
        return 'Settings';
      default:
        return 'Dosifi';
    }
  }

  String _infoForPath(String path) {
    switch (path) {
      case '/':
        return 'Home shows your dashboard with upcoming doses, alerts, and quick actions.';
      case '/medications':
        return 'Browse and manage medications. Tap a card for details or actions.';
      case '/supplies':
        return 'Manage medical supplies inventory and details.';
      case '/schedule':
        return 'View and manage medication schedules and add new ones.';
      case '/calendar':
        return 'See scheduled doses on a calendar and take quick actions.';
      case '/settings':
        return 'App preferences, diagnostics, and about information.';
      default:
        return 'Navigate the app using the bottom bar or the drawer.';
    }
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

  Widget _buildNotificationItem(
    BuildContext context,
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

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Navigation Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Main Navigation
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  subtitle: 'Dashboard overview',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.medication,
                  title: 'Medications',
                  subtitle: 'Manage medications',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/medications');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Supplies',
                  subtitle: 'Manage supplies',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/supplies');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.schedule,
                  title: 'Schedule',
                  subtitle: 'Medication schedules',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/schedule');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.calendar_month,
                  title: 'Calendar',
                  subtitle: 'Calendar view',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/calendar');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'App preferences & diagnostics',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/settings');
                  },
                ),
                const Divider(),
                _buildDrawerSectionHeader(context, 'Development'),
                _buildDrawerItem(
                  context,
                  icon: Icons.bug_report,
                  title: 'Notification Test',
                  subtitle: 'Test notification system',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/test/notifications');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.view_agenda,
                  title: 'Medication Cards Preview',
                  subtitle: 'See all card styles/examples',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/dev/medication-cards');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Dosifi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosifi - Medication Management App'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A comprehensive medication tracking and management solution.'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Medication inventory management'),
            Text('• Dosing schedules and reminders'),
            Text('• Reconstitution calculator'),
            Text('• Usage analytics and reports'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }
}
