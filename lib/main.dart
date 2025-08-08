import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_flutter/core/theme/app_theme.dart';
import 'package:dosifi_flutter/config/app_router.dart';
import 'package:dosifi_flutter/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test debug print at startup
  debugPrint('🔴🔴🔴 [MAIN DEBUG] APP STARTING - Debug prints are working!');
  debugPrint('==================================================');
  
  // Initialize services
  await _initializeApp();
  runApp(
    const ProviderScope(
      child: DosifiApp(),
    ),
  );
}

Future<void> _initializeApp() async {
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
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
    debugPrint('Skipping notification service initialization in test environment');
  }
  
  // Initialize database
  // try {
  //   await DatabaseService.database;
  //   final isIntegrityOk = await DatabaseService.checkDatabaseIntegrity();
  //   if (!isIntegrityOk) {
  //     debugPrint('Database integrity check failed');
  //   }
  // } catch (e) {
  //   debugPrint('Database initialization error: $e');
  // }
  
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

/// Helper function to detect if we're running in a test environment
/// 
/// Returns true if the app is currently running in a Flutter test or web environment.
/// Used to skip certain initializations during testing.
bool _isTestEnvironment() {
  return Platform.environment.containsKey('FLUTTER_TEST') || kIsWeb && kDebugMode;
}

class DosifiApp extends ConsumerWidget {
  const DosifiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Register notification action handler once UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = NotificationService();
      service.onAction = (String? actionId, String? payload) async {
        // Prefer actionId for action buttons; fallback to payload for simple taps
        final toProcess = (actionId != null && actionId.isNotEmpty) ? actionId : payload;
        if (toProcess == null) return;
        // Delegate logic to NotificationActionHandler which integrates with providers
        final handler = NotificationActionHandler(ref);
        await handler.handleNotificationTap(toProcess);
      };
    });
    
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
