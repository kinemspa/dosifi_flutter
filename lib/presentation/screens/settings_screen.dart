import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Notifications'),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Medication Reminders',
            subtitle: 'Configure dose reminder notifications',
            onTap: () => _showComingSoon(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notification_important,
            title: 'Low Stock Alerts',
            subtitle: 'Manage inventory alert settings',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 32),
          
          _buildSectionHeader(context, 'Data & Backup'),
          _buildSettingsTile(
            context,
            icon: Icons.backup,
            title: 'Backup Data',
            subtitle: 'Export your medication data',
            onTap: () => _showComingSoon(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.restore,
            title: 'Restore Data',
            subtitle: 'Import medication data from backup',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 32),
          
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'App language settings',
            trailing: const Text('English'),
            onTap: () => _showComingSoon(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.color_lens,
            title: 'Theme',
            subtitle: 'Choose app appearance',
            trailing: const Text('System'),
            onTap: () => _showComingSoon(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.schedule,
            title: 'Time Format',
            subtitle: '12-hour or 24-hour format',
            trailing: const Text('12-hour'),
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 32),
          
          _buildSectionHeader(context, 'Security'),
          _buildSettingsTile(
            context,
            icon: Icons.lock,
            title: 'App Lock',
            subtitle: 'Secure app with PIN or biometrics',
            onTap: () => _showComingSoon(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: 'Use fingerprint or face recognition',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 32),
          
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            context,
            icon: Icons.info,
            title: 'App Version',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAppInfo(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help with using the app',
            onTap: () => _showComingSoon(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () => _showComingSoon(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description,
            title: 'Terms of Service',
            subtitle: 'View terms and conditions',
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 32),
          
          Center(
            child: Text(
              'Dosifi - Medication Manager',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '© 2024 Dosifi. All rights reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title, 
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle: Text(
          subtitle, 
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        trailing: trailing ?? Icon(
          Icons.chevron_right, 
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Dosifi',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.medical_services,
        size: 48,
        color: Theme.of(context).primaryColor,
      ),
      children: [
        const Text(
          'Dosifi is a comprehensive medication management app designed to help you track, manage, and organize your medications efficiently.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features include medication tracking, dose scheduling, inventory management, and reconstitution calculations.',
        ),
      ],
    );
  }
}
