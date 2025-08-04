import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_router.dart';
import '../../core/widgets/animated_gradient_card.dart';
import '../../core/widgets/floating_particles.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Dosifi Dashboard',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            const FloatingParticles(
              particleCount: 20,
              particleColor: Color(0x22FFFFFF),
            ),
            SafeArea(
              child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
          _buildDashboardTile(
            context,
            icon: Icons.inventory,
            label: 'Inventory',
            onTap: () => context.push('/medication-screen'),
          ),
          _buildDashboardTile(
            context,
            icon: Icons.schedule,
            label: 'Schedules',
            onTap: () => context.navigateToSchedule(),
          ),
          _buildDashboardTile(
            context,
            icon: Icons.calculate,
            label: 'Reconstitution',
            onTap: () => context.navigateToReconstitution(),
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
            ),
          ],
        ),
      ),
    );
  }

Widget _buildDashboardTile(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AnimatedGradientCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              label, 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
