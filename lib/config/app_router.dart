import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import screens when created
import 'package:dosifi_flutter/presentation/screens/splash_screen.dart';
import 'package:dosifi_flutter/presentation/screens/medications_list_screen.dart';
import 'package:dosifi_flutter/presentation/screens/medication_view_screen.dart';
import 'package:dosifi_flutter/presentation/screens/medication_form_screen_refactored.dart';
import 'package:dosifi_flutter/presentation/screens/schedule_screen.dart';
import 'package:dosifi_flutter/presentation/screens/dashboard_screen.dart';
import 'package:dosifi_flutter/presentation/screens/main_shell_screen.dart';
import 'package:dosifi_flutter/presentation/screens/supplies_screen.dart';
import 'package:dosifi_flutter/presentation/screens/calendar_screen.dart';
import 'package:dosifi_flutter/presentation/screens/add_supply_screen.dart';
import 'package:dosifi_flutter/presentation/screens/add_schedule_screen.dart';
import 'package:dosifi_flutter/presentation/screens/notification_test_screen.dart';
import 'package:dosifi_flutter/presentation/screens/settings_screen.dart';
import 'package:dosifi_flutter/presentation/screens/medication_cards_preview.dart';
import 'package:dosifi_flutter/presentation/screens/reconstitution_calculator_screen.dart';

/// Centralized route names and paths for type-safety and reuse
class RouteNames {
  static const splash = 'splash';
  static const home = 'home';
  static const medications = 'medications';
  static const supplies = 'supplies';
  static const schedule = 'schedule';
  static const calendar = 'calendar';
  static const calculator = 'reconstitution-calculator';
  static const settings = 'settings';
  static const notificationTest = 'notification-test';
  static const devMedicationCards = 'dev-medication-cards';
  static const addMedication = 'add-medication';
  static const editMedication = 'edit-medication';
  static const medicationDetails = 'medication-details';
  static const addSupply = 'add-supply';
  static const editSupply = 'edit-supply';
  static const addSchedule = 'add-schedule';
  static const editSchedule = 'edit-schedule';
}

class RoutePaths {
  static const splash = '/splash';
  static const home = '/';
  static const medications = '/medications';
  static const supplies = '/supplies';
  static const schedule = '/schedule';
  static const calendar = '/calendar';
  static const calculator = '/calculator';
  static const settings = '/settings';
  static const notificationTest = '/test/notifications';
  static const devMedicationCards = '/dev/medication-cards';
  static const addMedication = '/medications/add';
  static const editMedication = '/medications/edit/:id';
  static const medicationDetails = '/medications/:id';
  static const addSupply = '/supplies/add';
  static const editSupply = '/supplies/edit/:id';
  static const addSchedule = '/schedules/add';
  static const editSchedule = '/schedules/edit/:id';
}

/// Public root navigator key so services can deep-link without BuildContext
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const DashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.medications,
        name: RouteNames.medications,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const MedicationsListScreen(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.supplies,
        name: RouteNames.supplies,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const SuppliesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.schedule,
        name: RouteNames.schedule,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const ScheduleScreen(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.calendar,
        name: RouteNames.calendar,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const CalendarScreen(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.calculator,
        name: RouteNames.calculator,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const ReconstitutionCalculatorScreen(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
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
        path: RoutePaths.notificationTest,
        name: RouteNames.notificationTest,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const NotificationTestScreen(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.devMedicationCards,
        name: RouteNames.devMedicationCards,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: MainShellScreen(
            currentPath: state.fullPath,
            child: const MedicationCardsPreviewScreen(),
          ),
        ),
      ),
      // Medication form routes (nested under main structure)
      GoRoute(
        path: RoutePaths.addMedication,
        name: RouteNames.addMedication,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MedicationFormScreenRefactored(compactSheetMode: false),
        ),
      ),
      GoRoute(
        path: RoutePaths.editMedication,
        name: RouteNames.editMedication,
        pageBuilder: (context, state) {
          final medicationId = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: MedicationFormScreenRefactored(
              medicationId: medicationId,
              compactSheetMode: false,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.medicationDetails,
        name: RouteNames.medicationDetails,
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
        path: RoutePaths.addSupply,
        name: RouteNames.addSupply,
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const AddSupplyScreen()),
      ),
      GoRoute(
        path: RoutePaths.editSupply,
        name: RouteNames.editSupply,
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
        path: RoutePaths.addSchedule,
        name: RouteNames.addSchedule,
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const AddScheduleScreen()),
      ),
      GoRoute(
        path: RoutePaths.editSchedule,
        name: RouteNames.editSchedule,
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                onPressed: () => context.go(RoutePaths.home),
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
  void navigateToHome() => go(RoutePaths.home);
  void navigateToMedications() => go(RoutePaths.medications);
  void navigateToSupplies() => go(RoutePaths.supplies);
  void navigateToSchedule({DateTime? date}) {
    if (date != null) {
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      go('${RoutePaths.schedule}?date=$y-$m-$d');
    } else {
      go(RoutePaths.schedule);
    }
  }

  void navigateToCalendar() => go(RoutePaths.calendar);
  void navigateToAddMedication() => go(RoutePaths.addMedication);
  void navigateToMedicationDetails(String id) => go('/medications/$id');
  void navigateToEditMedication(String id) => go('/medications/edit/$id');
  void navigateToAddSupply() => go(RoutePaths.addSupply);
  void navigateToEditSupply(String id) => go('/supplies/edit/$id');
  void navigateToAddSchedule() => go(RoutePaths.addSchedule);
  void navigateToEditSchedule(String id) => go('/schedules/edit/$id');
  void navigateToNotificationTest() => go(RoutePaths.notificationTest);
  void navigateToSettings() => go(RoutePaths.settings);

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
