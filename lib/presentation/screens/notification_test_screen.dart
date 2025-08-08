import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:dosifi_flutter/services/notification_service.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/data/models/schedule.dart';

class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends ConsumerState<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _permissionGranted = false;
  bool _serviceInitialized = false;
  Map<String, bool> _permissionStatus = {};
  String _testResults = '';
  
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

  Future<void> _testInstantNotification() async {
    setState(() {
      _testResults += '[${DateTime.now().toLocal()}] 🧪 Testing instant notification...\n';
    });

    try {
      await _notificationService.showInstantNotification(
        title: _titleController.text,
        body: _bodyController.text,
        payload: 'test_instant_${DateTime.now().millisecondsSinceEpoch}',
      );
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ✅ Instant notification sent\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Error sending instant notification: $e\n';
      });
    }
  }

  Future<void> _testScheduledNotification() async {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 5;

    final scheduledTime = DateTime.now().add(
      Duration(hours: hours, minutes: minutes, seconds: seconds),
    );

    setState(() {
      _testResults += '[${DateTime.now().toLocal()}] 🧪 Testing scheduled notification for $scheduledTime...\n';
      _testResults += '[${DateTime.now().toLocal()}] ⏰ Current time: ${DateTime.now().toLocal()}\n';
      _testResults += '[${DateTime.now().toLocal()}] ⌛ Time until notification: ${scheduledTime.difference(DateTime.now())}\n';
    });

    try {
      // Check permissions first
      final permissionStatus = await _notificationService.getPermissionStatus();
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] 🔍 Permission check: $permissionStatus\n';
      });
      
      await _notificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Scheduled: ${_titleController.text}',
        body: 'Scheduled for ${scheduledTime.toLocal()}\n${_bodyController.text}',
        scheduledDate: scheduledTime,
        payload: 'test_scheduled_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ✅ Scheduled notification for $scheduledTime\n';
      });
      
      await _loadPendingNotifications();
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Error scheduling notification: $e\n';
        _testResults += '[${DateTime.now().toLocal()}] 🔧 Stack trace: ${e.runtimeType}\n';
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

  Future<void> _testRepeatingNotification() async {
    setState(() {
      _testResults += '[${DateTime.now().toLocal()}] 🧪 Testing repeating notification...\n';
    });

    try {
      await _notificationService.scheduleRepeatingNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Repeating: ${_titleController.text}',
        body: 'This notification repeats every minute\n${_bodyController.text}',
        firstScheduledDate: DateTime.now().add(const Duration(seconds: 5)),
        repeatInterval: RepeatInterval.everyMinute,
        payload: 'test_repeating_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ✅ Repeating notification scheduled (every minute)\n';
      });

      await _loadPendingNotifications();
    } catch (e) {
      setState(() {
        _testResults += '[${DateTime.now().toLocal()}] ❌ Error scheduling repeating notification: $e\n';
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

  void _clearResults() {
    setState(() {
      _testResults = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkNotificationStatus,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearResults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            _buildStatusSection(),
            const SizedBox(height: 20),

            // Test Configuration Section
            _buildTestConfigSection(),
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
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification System Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _serviceInitialized ? Icons.check_circle : Icons.error,
                  color: _serviceInitialized ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Service Initialized: ${_serviceInitialized ? 'Yes' : 'No'}',
                  style: TextStyle(
                    color: _serviceInitialized ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _permissionGranted ? Icons.notifications_active : Icons.notifications_off,
                  color: _permissionGranted ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Permissions Granted: ${_permissionGranted ? 'Yes' : 'No'}',
                  style: TextStyle(
                    color: _permissionGranted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_permissionStatus.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Details: ${_permissionStatus.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Pending Notifications: ${_pendingNotifications.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Notification Body',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Text(
              'Schedule Time (from now):',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minutesController,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _secondsController,
                    decoration: const InputDecoration(
                      labelText: 'Seconds',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Tests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testInstantNotification,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Instant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testScheduledNotification,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Scheduled'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runQuickTest,
                    icon: const Icon(Icons.speed),
                    label: const Text('10s Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runSystemDiagnostic,
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Diagnostic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Tests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testMedicationReminder,
                icon: const Icon(Icons.medication),
                label: const Text('Test Medication Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testRepeatingNotification,
                icon: const Icon(Icons.repeat),
                label: const Text('Test Repeating Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cancelAllNotifications,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel All Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Notifications (${_pendingNotifications.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadPendingNotifications,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_pendingNotifications.isEmpty)
              const Text(
                'No pending notifications',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...(_pendingNotifications.map((notification) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.blue[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      notification.id.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  title: Text(notification.title ?? 'No title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.body != null)
                        Text(
                          notification.body!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (notification.payload != null)
                        Text(
                          'Payload: ${notification.payload}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () async {
                      await _notificationService.cancelNotification(notification.id);
                      await _loadPendingNotifications();
                      setState(() {
                        _testResults += '[${DateTime.now().toLocal()}] 🗑️ Canceled notification ${notification.id}\n';
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ),
              ))),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Test Results Log',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _clearResults,
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 300,
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
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
