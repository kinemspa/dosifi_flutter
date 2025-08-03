import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosifi Dashboard'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardTile(
            context,
            icon: Icons.medical_services,
            label: 'Medications',
            onTap: () => context.navigateToMedications(),
          ),
          _buildDashboardTile(
            context,
            icon: Icons.schedule,
            label: 'Schedules',
            onTap: () => context.navigateToSchedule(),
          ),
          _buildDashboardTile(
            context,
            icon: Icons.inventory,
            label: 'Med Inventory',
            onTap: () => context.navigateToInventory(),
          ),
          _buildDashboardTile(
            context,
            icon: Icons.calculate,
            label: 'Reconstitution',
            onTap: () => context.navigateToReconstitution(),
          ),
          _buildDashboardTile(
            context,
            icon: Icons.healing,
            label: 'Supplies',
            onTap: () => context.push('/supplies'),
          ),
          _buildDashboardTile(
            context,
            icon: Icons.analytics,
            label: 'Analytics',
            onTap: () => context.navigateToAnalytics(),
          ),
          _buildDashboardTile(
            context,
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => context.navigateToSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTile(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(label, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
