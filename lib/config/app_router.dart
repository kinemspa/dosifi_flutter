import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import screens when created
import 'package:dosifi_flutter/presentation/screens/splash_screen.dart';
import 'package:dosifi_flutter/presentation/screens/medications_list_screen.dart';
import 'package:dosifi_flutter/presentation/screens/medication_view_screen.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form_screen.dart';
import 'package:dosifi_flutter/presentation/screens/schedule_screen.dart';
import 'package:dosifi_flutter/presentation/screens/dashboard_screen.dart';
import 'package:dosifi_flutter/presentation/screens/main_shell_screen.dart';
import 'package:dosifi_flutter/presentation/screens/supplies_screen.dart';
import 'package:dosifi_flutter/presentation/screens/calendar_screen.dart';
import 'package:dosifi_flutter/presentation/screens/add_supply_screen.dart';
import 'package:dosifi_flutter/presentation/screens/add_schedule_screen.dart';
import 'package:dosifi_flutter/presentation/screens/notification_test_screen.dart';
import 'package:dosifi_flutter/presentation/screens/settings_screen.dart';

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
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const DashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/medications',
        name: 'medications',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const MedicationsListScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/supplies',
        name: 'supplies',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const SuppliesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/schedule',
        name: 'schedule',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const ScheduleScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const CalendarScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const SettingsScreen(),
          ),
        ),
      ),
      // Development/Testing routes
      GoRoute(
        path: '/test/notifications',
        name: 'notification-test',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const NotificationTestScreen(),
          ),
        ),
      ),
      // Medication form routes (nested under main structure)
      GoRoute(
        path: '/medications/add',
        name: 'add-medication',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MedicationFormScreen(),
        ),
      ),
      GoRoute(
        path: '/medications/edit/:id',
        name: 'edit-medication',
        pageBuilder: (context, state) {
          final medicationId = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: MedicationFormScreen(medicationId: medicationId),
          );
        },
      ),
      GoRoute(
        path: '/medications/:id',
        name: 'medication-details',
        pageBuilder: (context, state) {
          final medicationId = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: MedicationViewScreen(medicationId: medicationId),
          );
        },
      ),
      // Supply form routes
      GoRoute(
        path: '/supplies/add',
        name: 'add-supply',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AddSupplyScreen(),
        ),
      ),
      GoRoute(
        path: '/supplies/edit/:id',
        name: 'edit-supply',
        pageBuilder: (context, state) {
          final supplyId = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: AddSupplyScreen(supplyId: supplyId),
          );
        },
      ),
      // Schedule form routes
      GoRoute(
        path: '/schedules/add',
        name: 'add-schedule',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AddScheduleScreen(),
        ),
      ),
      GoRoute(
        path: '/schedules/edit/:id',
        name: 'edit-schedule',
        pageBuilder: (context, state) {
          final scheduleId = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: AddScheduleScreen(scheduleId: scheduleId),
          );
        },
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
  void navigateToHome() => go('/');
  void navigateToMedications() => go('/medications');
  void navigateToSupplies() => go('/supplies');
  void navigateToSchedule() => go('/schedule');
  void navigateToCalendar() => go('/calendar');
  void navigateToAddMedication() => go('/medications/add');
  void navigateToMedicationDetails(String id) => go('/medications/$id');
  void navigateToEditMedication(String id) => go('/medications/edit/$id');
  void navigateToAddSupply() => go('/supplies/add');
  void navigateToEditSupply(String id) => go('/supplies/edit/$id');
  void navigateToAddSchedule() => go('/schedules/add');
  void navigateToEditSchedule(String id) => go('/schedules/edit/$id');
  void navigateToNotificationTest() => go('/test/notifications');
  void navigateToSettings() => go('/settings');
  
  /// Smart back navigation that goes to the appropriate main screen
  void navigateBackSmart() {
    // Get the current location to determine which main screen to return to
    final currentLocation = GoRouterState.of(this).uri.toString();
    
    // Check if we can pop, otherwise navigate to the appropriate main screen
    if (canPop()) {
      pop();
    } else {
      // Navigate to the appropriate main screen based on current route
      if (currentLocation.startsWith('/medications')) {
        navigateToMedications();
      } else if (currentLocation.startsWith('/supplies')) {
        navigateToSupplies();
      } else if (currentLocation.startsWith('/schedule')) {
        navigateToSchedule();
      } else if (currentLocation.startsWith('/calendar')) {
        navigateToCalendar();
      } else {
        navigateToHome();
      }
    }
  }
}
