import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notification_service.dart';

// Providers for notification settings
final notificationEnabledProvider = StateNotifierProvider<NotificationEnabledNotifier, bool>((ref) {
  return NotificationEnabledNotifier();
});

final medicationRemindersProvider = StateNotifierProvider<MedicationRemindersNotifier, bool>((ref) {
  return MedicationRemindersNotifier();
});

final lowStockAlertsProvider = StateNotifierProvider<LowStockAlertsNotifier, bool>((ref) {
  return LowStockAlertsNotifier();
});

final reminderSoundProvider = StateNotifierProvider<ReminderSoundNotifier, String>((ref) {
  return ReminderSoundNotifier();
});

final snoozeTimeProvider = StateNotifierProvider<SnoozeTimeNotifier, int>((ref) {
  return SnoozeTimeNotifier();
});

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings when screen initializes
    ref.read(notificationEnabledProvider.notifier).loadSetting();
    ref.read(medicationRemindersProvider.notifier).loadSetting();
    ref.read(lowStockAlertsProvider.notifier).loadSetting();
    ref.read(reminderSoundProvider.notifier).loadSetting();
    ref.read(snoozeTimeProvider.notifier).loadSetting();
  }

  @override
  Widget build(BuildContext context) {
    final notificationEnabled = ref.watch(notificationEnabledProvider);
    final medicationReminders = ref.watch(medicationRemindersProvider);
    final lowStockAlerts = ref.watch(lowStockAlertsProvider);
    final reminderSound = ref.watch(reminderSoundProvider);
    final snoozeTime = ref.watch(snoozeTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('General'),
            _buildSwitchTile(
              'Enable Notifications',
              'Allow the app to send notifications',
              Icons.notifications,
              notificationEnabled,
              (value) => ref.read(notificationEnabledProvider.notifier).updateSetting(value),
            ),
            const SizedBox(height: 16),
            
            _buildSectionHeader('Medication Reminders'),
            _buildSwitchTile(
              'Dose Reminders',
              'Get notified when it\'s time to take medication',
              Icons.medication,
              medicationReminders,
              (value) => ref.read(medicationRemindersProvider.notifier).updateSetting(value),
              enabled: notificationEnabled,
            ),
            _buildSoundSelector(
              'Reminder Sound',
              'Choose sound for medication reminders',
              Icons.volume_up,
              reminderSound,
              (value) => value != null ? ref.read(reminderSoundProvider.notifier).updateSetting(value) : null,
              enabled: notificationEnabled && medicationReminders,
            ),
            _buildSnoozeSelector(
              'Snooze Time',
              'How long to snooze reminders',
              Icons.snooze,
              snoozeTime,
              (value) => value != null ? ref.read(snoozeTimeProvider.notifier).updateSetting(value) : null,
              enabled: notificationEnabled && medicationReminders,
            ),
            const SizedBox(height: 16),
            
            _buildSectionHeader('Inventory Alerts'),
            _buildSwitchTile(
              'Low Stock Alerts',
              'Get notified when medication stock is low',
              Icons.inventory,
              lowStockAlerts,
              (value) => ref.read(lowStockAlertsProvider.notifier).updateSetting(value),
              enabled: notificationEnabled,
            ),
            const SizedBox(height: 32),
            
            _buildTestNotificationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    bool enabled = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: enabled 
              ? Theme.of(context).colorScheme.onSurface 
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled 
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        secondary: Icon(
          icon, 
          color: enabled 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSoundSelector(
    String title,
    String subtitle,
    IconData icon,
    String currentValue,
    void Function(String?) onChanged, {
    bool enabled = true,
  }) {
    final sounds = ['Default', 'Bell', 'Chime', 'Alert', 'Gentle'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          icon, 
          color: enabled 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled 
              ? Theme.of(context).colorScheme.onSurface 
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled 
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        trailing: DropdownButton<String>(
          value: currentValue,
          onChanged: enabled ? onChanged : null,
          items: sounds.map((String sound) {
            return DropdownMenuItem<String>(
              value: sound,
              child: Text(sound),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSnoozeSelector(
    String title,
    String subtitle,
    IconData icon,
    int currentValue,
    void Function(int?) onChanged, {
    bool enabled = true,
  }) {
    final snoozeTimes = [5, 10, 15, 30, 60]; // minutes
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          icon, 
          color: enabled 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled 
              ? Theme.of(context).colorScheme.onSurface 
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled 
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        trailing: DropdownButton<int>(
          value: currentValue,
          onChanged: enabled ? onChanged : null,
          items: snoozeTimes.map((int time) {
            return DropdownMenuItem<int>(
              value: time,
              child: Text('$time min'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a test notification to verify your settings are working correctly.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.send),
                label: const Text('Send Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.showNotification(
        id: 999,
        title: 'Test Notification',
        body: 'This is a test notification from Dosifi. Your notification settings are working!',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// State Notifiers for settings
class NotificationEnabledNotifier extends StateNotifier<bool> {
  NotificationEnabledNotifier() : super(true);

  Future<void> loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> updateSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    state = enabled;
  }
}

class MedicationRemindersNotifier extends StateNotifier<bool> {
  MedicationRemindersNotifier() : super(true);

  Future<void> loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('medication_reminders') ?? true;
  }

  Future<void> updateSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('medication_reminders', enabled);
    state = enabled;
  }
}

class LowStockAlertsNotifier extends StateNotifier<bool> {
  LowStockAlertsNotifier() : super(true);

  Future<void> loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('low_stock_alerts') ?? true;
  }

  Future<void> updateSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('low_stock_alerts', enabled);
    state = enabled;
  }
}

class ReminderSoundNotifier extends StateNotifier<String> {
  ReminderSoundNotifier() : super('Default');

  Future<void> loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('reminder_sound') ?? 'Default';
  }

  Future<void> updateSetting(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_sound', sound);
    state = sound;
  }
}

class SnoozeTimeNotifier extends StateNotifier<int> {
  SnoozeTimeNotifier() : super(10);

  Future<void> loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('snooze_time') ?? 10;
  }

  Future<void> updateSetting(int time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('snooze_time', time);
    state = time;
  }
}
