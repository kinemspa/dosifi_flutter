import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import screens when created
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/medication_list_screen.dart';
import '../presentation/screens/add_medication_screen.dart';
import '../presentation/screens/add_medication_screen_comprehensive.dart';
import '../presentation/screens/medication_screen.dart';
import '../presentation/screens/edit_medication_screen.dart';
import '../presentation/screens/medication_details_screen.dart';
import '../presentation/screens/reconstitution_calculator_screen.dart';
import '../presentation/screens/schedule_screen.dart';
import '../presentation/screens/supply_inventory_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/analytics_screen.dart';
import '../presentation/screens/dashboard_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MedicationScreen(),
        ),
      ),
      GoRoute(
        path: '/schedule',
        name: 'schedule',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ScheduleScreen(),
        ),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/supply-inventory',
        name: 'supply-inventory',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SupplyInventoryScreen(),
        ),
      ),
      GoRoute(
        path: '/reconstitution',
        name: 'reconstitution',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ReconstitutionCalculatorScreen(),
        ),
      ),
      GoRoute(
        path: '/medications',
        name: 'medications',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MedicationListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'add',
            name: 'add-medication',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AddMedicationScreen(),
            ),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'edit-medication',
            pageBuilder: (context, state) {
              final medicationId = state.pathParameters['id']!;
              return MaterialPage(
                key: state.pageKey,
              child: EditMedicationScreen(medicationId: medicationId),
              );
            },
          ),
          GoRoute(
            path: ':id',
            name: 'medication-details',
            pageBuilder: (context, state) {
              final medicationId = state.pathParameters['id']!;
              return MaterialPage(
                key: state.pageKey,
                child: MedicationDetailsScreen(medicationId: medicationId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/add-medication-comprehensive',
        name: 'add-medication-comprehensive',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AddMedicationScreenComprehensive(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

// Navigation extensions
extension NavigationExtensions on BuildContext {
  void navigateToMedications() => go('/medications');
  void navigateToAddMedication() => go('/medications/add');
  void navigateToMedicationDetails(String id) => go('/medications/$id');
  void navigateToEditMedication(String id) => go('/medications/edit/$id');
  void navigateToReconstitution() => go('/reconstitution');
  void navigateToSchedule() => go('/schedule');
  void navigateToInventory() => go('/inventory');
  void navigateToAnalytics() => go('/analytics');
  void navigateToSettings() => go('/settings');
}
