import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:dosifi_flutter/services/notification_service.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _permissionGranted = false;
  bool _serviceInitialized = false;
  Map<String, bool> _permissionStatus = {};
  String _testResults = '';
  bool _showDiagnostics = false;
  
  // Test form controllers
  final _titleController = TextEditingController(text: 'Test Notification');
  final _bodyController = TextEditingController(text: 'This is a test notification from Dosifi');
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');
  final _secondsController = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _initializeAndCheck();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndCheck() async {
    await _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    setState(() {
      _testResults += '[${DateTime.now().toLocal()}] Checking notification status...\n';
    });

    try {
      // Initialize service
      await _notificationService.initialize();
      setState(() {
        _serviceInitialized = true;
        _testResults += '[${DateTime.now().toLocal()}] ✅ NotificationService initialized\n';
      });

      // Check permissions
      final hasPermission = await _notificationService.requestPermissions();
      final permissionStatus = await _notificationService.getPermissionStatus();
      
      setState(() {
        _permissionGranted = hasPermission;
        _permissionStatus = permissionStatus;
        _testResults += '[${DateTime.now().toLocal()}] ${hasPermission ? '✅' : '❌'} Notification permission: $hasPermission\n';
        _testResults += '[${DateTime.now().toLocal()}] 📋 Permission details: $permissionStatus\n';
        _testResults += '[${DateTime.now().toLocal()}] 🌏 Device timezone: ${DateTime.now().timeZoneName}\n';
        _testResults += '[${DateTime.now().toLocal()}] 🌏 TZ Local: ${tz.local.name}\n';
        _testResults += '[${DateTime.now().toLocal()}] 🌏 Current TZ time: ${tz.TZDateTime.now(tz.local)}\n';
      });

      // Get pending notifications
      await _loadPendingNotifications();
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Error: $e\n';
      });
    }
  }

  Future<void> _loadPendingNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      setState(() {
        _pendingNotifications = pending;
        _testResults += '[${DateTime.now().toLocal()}] 📋 Found ${pending.length} pending notifications\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Error loading pending notifications: $e\n';
      });
    }
  }

  Future<void> _testMultipleNotifications() async {
    setState(() {
      _testResults += '[${DateTime.now().toLocal()}] 🧪 Testing 5 simultaneous notifications...\n';
    });

    try {
      final baseTime = DateTime.now().add(const Duration(seconds: 3));
      
      // Schedule 5 notifications with slightly different times
      for (int i = 1; i <= 5; i++) {
        final scheduledTime = baseTime.add(Duration(seconds: i - 1));
        
        await _notificationService.scheduleNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + i,
          title: 'Multi-Test $i/5',
          body: 'This is notification #$i of 5 scheduled simultaneously',
          scheduledDate: scheduledTime,
          payload: 'multi_test_$i',
        );
        
        setState(() {
          _testResults += '[${DateTime.now().toLocal()}] ✅ Scheduled notification $i for $scheduledTime\n';
        });
      }
      
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] 🎯 All 5 notifications scheduled! They should appear starting in 3 seconds\n';
      });
      
      await _loadPendingNotifications();
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Error scheduling multiple notifications: $e\n';
      });
    }
  }

  Future<void> _testMedicationReminder() async {
    setState(() {
      _testResults += '[${DateTime.now().toLocal()}] 🧪 Testing medication reminder...\n';
    });

    try {
      // Create test medication
      final testMedication = Medication.create(
        name: 'Test Medication',
        type: MedicationType.tablet,
        strengthPerUnit: 10.0,
        strengthUnit: StrengthUnit.mg,
        stockQuantity: 30.0,
      );

      // Create test schedule
      final testSchedule = Schedule.create(
        medicationId: 1,
        scheduleType: 'daily',
        timeOfDay: '${DateTime.now().add(const Duration(seconds: 10)).hour.toString().padLeft(2, '0')}:${DateTime.now().add(const Duration(seconds: 10)).minute.toString().padLeft(2, '0')}',
        startDate: DateTime.now(),
        doseAmount: 1.0,
        doseUnit: 'tablet',
        doseForm: 'tablet',
        strengthPerUnit: 10.0,
      );

      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));

      await _notificationService.scheduleNotificationForSchedule(
        schedule: testSchedule,
        medication: testMedication,
        scheduledDate: scheduledTime,
      );

      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ✅ Medication reminder scheduled for $scheduledTime\n';
        _testResults += '[${DateTime.now().toLocal()}] 💊 Medication: ${testMedication.name}\n';
        _testResults += '[${DateTime.now().toLocal()}] 📅 Schedule: ${testSchedule.doseAmount} ${testSchedule.doseUnit}\n';
      });

      await _loadPendingNotifications();
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Error creating medication reminder: $e\n';
      });
    }
  }

  Future<void> _runQuickTest() async {
    setState(() {
      _testResults += '[${DateTime.now().toLocal()}] ⚡ Running quick 10-second test...\n';
    });

    try {
      final success = await _notificationService.scheduleTestNotification();
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ${success ? '✅' : '❌'} Quick test: ${success ? 'Success' : 'Failed'}\n';
        if (success) {
          _testResults += '[${DateTime.now().toLocal()}] ⏰ Notification should appear in 10 seconds\n';
        }
      });
      await _loadPendingNotifications();
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Quick test error: $e\n';
      });
    }
  }

  Future<void> _runSystemDiagnostic() async {
    setState(() {
      _testResults += '[${DateTime.now().toLocal()}] 🔍 Running system diagnostic...\n';
    });

    try {
      final status = await _notificationService.getNotificationSystemStatus();
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] 📊 System Status:\n';
        status.forEach((key, value) {
          _testResults += '   $key: $value\n';
        });
      });
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Error running diagnostic: $e\n';
      });
    }
  }

  Future<void> _cancelAllNotifications() async {
    setState(() {
      _testResults += '[${DateTime.now().toLocal()}] 🗑️ Canceling all notifications...\n';
    });

    try {
      await _notificationService.cancelAllNotifications();
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ✅ All notifications canceled\n';
      });
      await _loadPendingNotifications();
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Error canceling notifications: $e\n';
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification Settings Section
          _buildSettingsSection(
            'Notifications',
            Icons.notifications,
            [
              ListTile(
                leading: Icon(Icons.notifications_active, 
                    color: _permissionGranted ? Colors.green : Colors.orange),
                title: const Text('Notification Permissions'),
                subtitle: Text(_permissionGranted ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: _permissionGranted,
                  onChanged: (value) async {
                    if (value) {
                      await _notificationService.requestPermissions();
                      await _checkNotificationStatus();
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Reminder Frequency'),
                subtitle: const Text('Daily reminders'),
                trailing: const Text('Coming Soon'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Notification Sound'),
                subtitle: const Text('Default'),
                trailing: const Text('Coming Soon'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // App Preferences Section
          _buildSettingsSection(
            'App Preferences',
            Icons.settings,
            [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme'),
                subtitle: const Text('System default'),
                trailing: const Text('Coming Soon'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Text('Coming Soon'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Data & Privacy Section
          _buildSettingsSection(
            'Data & Privacy',
            Icons.security,
            [
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup Data'),
                subtitle: const Text('Export medication data'),
                trailing: const Text('Coming Soon'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore Data'),
                subtitle: const Text('Import medication data'),
                trailing: const Text('Coming Soon'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Diagnostics Section
          _buildSettingsSection(
            'Diagnostics',
            Icons.medical_services,
            [
              ListTile(
                leading: Icon(
                  Icons.bug_report,
                  color: _showDiagnostics ? Colors.blue : Colors.grey,
                ),
                title: const Text('Notification Testing'),
                subtitle: Text(_showDiagnostics ? 'Hide diagnostic tools' : 'Show diagnostic tools'),
                trailing: Icon(_showDiagnostics ? Icons.expand_less : Icons.expand_more),
                onTap: () {
                  setState(() {
                    _showDiagnostics = !_showDiagnostics;
                  });
                },
              ),
              if (_showDiagnostics) ...[
                const Divider(indent: 16),
                _buildNotificationDiagnostics(),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // About Section
          _buildSettingsSection(
            'About',
            Icons.info,
            [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
                onTap: () {
                  _showAboutDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNotificationDiagnostics() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Section
          _buildDiagnosticStatusSection(),
          const SizedBox(height: 20),

          // Quick Test Buttons
          _buildQuickTestSection(),
          const SizedBox(height: 20),

          // Advanced Tests
          _buildAdvancedTestSection(),
          const SizedBox(height: 20),

          // Pending Notifications
          _buildPendingNotificationsSection(),
          const SizedBox(height: 20),

          // Test Results Log
          _buildTestResultsSection(),
        ],
      ),
    );
  }

  Widget _buildDiagnosticStatusSection() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _serviceInitialized ? Icons.check_circle : Icons.error,
                  color: _serviceInitialized ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text('Service: ${_serviceInitialized ? 'Active' : 'Inactive'}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _permissionGranted ? Icons.notifications_active : Icons.notifications_off,
                  color: _permissionGranted ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text('Permissions: ${_permissionGranted ? 'Granted' : 'Denied'}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Text('Pending: ${_pendingNotifications.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Tests',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _runQuickTest,
              icon: const Icon(Icons.speed),
              label: const Text('10s Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 36),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _testMultipleNotifications,
              icon: const Icon(Icons.layers),
              label: const Text('Multi Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 36),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _runSystemDiagnostic,
              icon: const Icon(Icons.medical_services),
              label: const Text('Diagnostic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 36),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Tests',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _testMedicationReminder,
              icon: const Icon(Icons.medication),
              label: const Text('Medication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 36),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _cancelAllNotifications,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 36),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending (${_pendingNotifications.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _loadPendingNotifications,
              icon: const Icon(Icons.refresh),
              iconSize: 18,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_pendingNotifications.isEmpty)
          const Text(
            'No pending notifications',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _pendingNotifications.length,
              itemBuilder: (context, index) {
                final notification = _pendingNotifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: Colors.blue[50],
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 12,
                      child: Text(
                        notification.id.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    title: Text(
                      notification.title ?? 'No title',
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      notification.body ?? 'No body',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        await _notificationService.cancelNotification(notification.id);
                        await _loadPendingNotifications();
                        setState(() {
                          _testResults += '[${DateTime.now().toLocal()}] 🗑️ Canceled notification ${notification.id}\n';
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTestResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Test Log',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _clearResults,
              icon: const Icon(Icons.clear),
              iconSize: 18,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SingleChildScrollView(
            child: Text(
              _testResults.isEmpty ? 'No test results yet...' : _testResults,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.greenAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog() {
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
            Text('• Smart notifications'),
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
