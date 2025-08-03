import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import screens when created
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/medication_list_screen.dart';
// import '../presentation/screens/add_medication_screen.dart';
// import '../presentation/screens/reconstitution_calculator_screen.dart';
// import '../presentation/screens/schedule_screen.dart';
// import '../presentation/screens/inventory_screen.dart';
// import '../presentation/screens/settings_screen.dart';
// import '../presentation/screens/analytics_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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
        child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
        routes: [
          GoRoute(
            path: 'medications',
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
                  child: Container(), // Replace with AddMedicationScreen(),
                ),
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'edit-medication',
                pageBuilder: (context, state) {
                  final medicationId = state.pathParameters['id']!;
                  return MaterialPage(
                    key: state.pageKey,
                    child: Container(), // Replace with EditMedicationScreen(medicationId: medicationId),
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
                    child: Container(), // Replace with MedicationDetailsScreen(medicationId: medicationId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'reconstitution',
            name: 'reconstitution',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: Container(), // Replace with ReconstitutionCalculatorScreen(),
            ),
          ),
          GoRoute(
            path: 'schedule',
            name: 'schedule',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: Container(), // Replace with ScheduleScreen(),
            ),
          ),
          GoRoute(
            path: 'inventory',
            name: 'inventory',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: Container(), // Replace with InventoryScreen(),
            ),
          ),
          GoRoute(
            path: 'analytics',
            name: 'analytics',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: Container(), // Replace with AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: Container(), // Replace with SettingsScreen(),
            ),
          ),
        ],
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
