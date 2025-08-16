import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dosifi_flutter/config/app_router.dart';
import 'package:dosifi_flutter/presentation/screens/main_shell_screen.dart';
import 'package:dosifi_flutter/presentation/screens/dashboard_screen.dart';
import 'package:dosifi_flutter/presentation/screens/schedule_screen.dart';
import 'package:dosifi_flutter/presentation/screens/reconstitution_calculator_screen.dart';

/// A lightweight app used for widget tests to avoid splash/async setup.
class TestDosifiApp extends ConsumerWidget {
  const TestDosifiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testRouter = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: RoutePaths.home,
      routes: [
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
      ],
    );

    return MaterialApp.router(
      title: 'Dosifi Test',
      debugShowCheckedModeBanner: false,
      routerConfig: testRouter,
    );
  }
}
