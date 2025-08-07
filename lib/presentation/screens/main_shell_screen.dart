import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;
  final String? currentPath;

  const MainShellScreen({
    super.key,
    required this.child,
    this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        automaticallyImplyLeading: true, // Show hamburger menu
        actions: [
          // Add notification button for home screen
          if (currentPath == '/')
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                _showNotificationsBottomSheet(context);
              },
            ),
        ],
      ),
      drawer: _buildNavigationDrawer(context),
      body: child,
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
      case '/dose-activity':
        return 'Dose Activity';
      default:
        return 'Dosifi';
    }
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
                  icon: Icons.analytics,
                  title: 'Dose Activity',
                  subtitle: 'Track dose history',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/dose-activity');
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
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
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
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
