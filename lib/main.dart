import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_flutter/core/theme/app_theme.dart';
import 'package:dosifi_flutter/config/app_router.dart';
import 'package:dosifi_flutter/services/notification_service.dart';
import 'package:dosifi_flutter/core/services/notification_action_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Startup debug logs can be enabled via verbose logging during development.

  // Initialize services
  await _initializeApp();
  runApp(const ProviderScope(child: DosifiApp()));
}

Future<void> _initializeApp() async {
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize timezone data and set local location
  await _initializeTimezone();

  // Initialize notification service (skip in test environment)
  if (!_isTestEnvironment()) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.requestPermissions();
    } catch (e, stackTrace) {
      // Improved error handling: Log complete stack trace for debugging
      debugPrint('Notification service initialization error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  } else {
    debugPrint(
      'Skipping notification service initialization in test environment',
    );
  }

  // Database init is handled lazily by repositories as needed.

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

Future<void> _initializeTimezone() async {
  try {
    tzdata.initializeTimeZones();
    // Use default local timezone provided by the platform/engine. If the IANA
    // timezone name is needed for advanced cases, re-introduce a platform
    // plugin to obtain it and call tz.setLocalLocation accordingly.
    debugPrint('Timezone initialized (default local): time=${tz.TZDateTime.now(tz.local)}');
  } catch (e, stackTrace) {
    debugPrint('Timezone initialization error: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// Helper function to detect if we're running in a test environment
///
/// Returns true if the app is currently running in a Flutter test or web environment.
/// Used to skip certain initializations during testing.
bool _isTestEnvironment() {
  return Platform.environment.containsKey('FLUTTER_TEST') ||
      kIsWeb && kDebugMode;
}

class DosifiApp extends ConsumerStatefulWidget {
  const DosifiApp({super.key});

  @override
  ConsumerState<DosifiApp> createState() => _DosifiAppState();
}

class _DosifiAppState extends ConsumerState<DosifiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register notification action handler once UI is ready (skip in test environment)
    if (!_isTestEnvironment()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = NotificationService();
        service.onAction = (String? actionId, String? payload) async {
          // Prefer actionId for action buttons; fallback to payload for simple taps
          final toProcess = (actionId != null && actionId.isNotEmpty)
              ? actionId
              : payload;
          if (toProcess == null) return;
          // Delegate logic to NotificationActionHandler which integrates with providers
          final handler = NotificationActionHandler(
            read: ref.read,
            invalidate: ref.invalidate,
          );
          await handler.handleNotificationTap(toProcess);
        };
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-assert timezone on resume in case user changed timezone
      _initializeTimezone();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Dosifi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system, // Will be controlled by user preference later
      routerConfig: router,
    );
  }
}
