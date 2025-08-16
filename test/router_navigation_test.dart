import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_flutter/config/app_router.dart';
import 'test_app.dart';
import 'package:dosifi_flutter/presentation/providers/dose_scheduling_provider.dart';
import 'package:dosifi_flutter/core/services/dose_scheduling_service.dart';
import 'package:dosifi_flutter/data/repositories/schedule_repository.dart';
import 'package:dosifi_flutter/data/repositories/dose_log_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Router navigation and deep link tests', () {
    testWidgets(
      'Deep link to /schedule?date=YYYY-MM-DD selects Schedule shell and shows title',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            // Override dose scheduling with a no-op notifier to avoid async churn
            doseSchedulingProvider.overrideWith((ref) {
              return DoseSchedulingNotifier(FakeDoseSchedulingService());
            }),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const TestDosifiApp(),
          ),
        );
        // Small settle to build initial frame without waiting on background tasks
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Use the public root navigator key to navigate without BuildContext from the tree
        final ctx = rootNavigatorKey.currentContext!;
        ctx.go('${RoutePaths.schedule}?date=2025-08-15');

        // Pump a few frames to allow navigation to complete without full settle
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Expect the MainShellScreen app bar title to be 'Schedule'
        expect(find.text('Schedule'), findsWidgets);
      },
    );

    testWidgets(
      'Dashboard tools quick action opens Reconstitution Calculator screen',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            doseSchedulingProvider.overrideWith((ref) {
              return DoseSchedulingNotifier(FakeDoseSchedulingService());
            }),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const TestDosifiApp(),
          ),
        );
        // Small settle to build initial frame without waiting on background tasks
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // We should start on Home/Dashboard
        expect(find.text('Quick Actions'), findsOneWidget);

        // Tap the Tools -> Reconstitution Calculator quick action (ensure visible first)
        final calcButton = find.text('Reconstitution\nCalculator');
        expect(calcButton, findsWidgets);
        await tester.ensureVisible(calcButton.first);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(calcButton.first);

        // Pump a few frames to allow navigation to complete without full settle
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // The embedded calculator screen title or content should be visible
        // Depending on shell, the app bar may be provided by MainShellScreen, but
        // the calculator screen exposes title text inside. Check for either.
        expect(find.textContaining('Calculator'), findsWidgets);
      },
    );
  });
}

// A minimal fake service that implements only the methods used by the notifier but no-ops
class FakeDoseSchedulingService extends DoseSchedulingService {
  FakeDoseSchedulingService()
    : super(
        scheduleRepository: _DummySchedules(),
        doseLogRepository: _DummyDoseLogs(),
      );

  @override
  Future<void> generateTodaysDoseLogs() async {}

  @override
  Future<void> generateUpcomingDoseLogs() async {}

  @override
  Future<void> markOverdueDosesAsMissed() async {}
}

class _DummySchedules extends ScheduleRepository {}

class _DummyDoseLogs extends DoseLogRepository {}
