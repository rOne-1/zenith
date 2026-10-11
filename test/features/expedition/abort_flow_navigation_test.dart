import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/storage/storage.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/widgets.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/expedition/controllers/active_session_controller.dart';
import 'package:zenith/features/expedition/screens/active_expedition_screen.dart';

void main() {
  group('Abort Flow Navigation Sequencing (POL-1)', () {
    late SbeeDatabase database;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      database = SbeeDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    WorkoutSession createTestSession() {
      final startTime = DateTime.now();
      return WorkoutSession(
        id: 'abort_test_session',
        startTime: startTime,
        sets: [
          WorkoutSet(
            id: 'set_1',
            sessionId: 'abort_test_session',
            exerciseId: 'standard_pushup',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 8,
            variables: const MillerVariables(
              load: 1,
              bodyPosition: 1,
              rom: 1,
              height: 1,
              tempo: 1,
            ),
            timestamp: startTime,
            restDuration: const Duration(seconds: 60),
          ),
        ],
      );
    }

    testWidgets('aborting active expedition pops route before session state reset without warm-up flash', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(activeSessionControllerProvider.notifier);
      await controller.startSession(createTestSession());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: zenithThemeRegistry.defaultTheme.themeData,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ActiveExpeditionScreen(),
                        ),
                      );
                    },
                    child: const Text('LAUNCH_EXPEDITION'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Launch ActiveExpeditionScreen
      await tester.tap(find.text('LAUNCH_EXPEDITION'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ACTIVE EXPEDITION'), findsOneWidget);
      expect(find.byType(ActiveExpeditionScreen), findsOneWidget);

      // Advance to working set from warm-up
      await tester.tap(find.text('▶ COMMENCE WORKING SETS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('✓ COMPLETE SET'), findsOneWidget);

      // Tap abort (the '✕' button)
      await tester.tap(find.text('✕'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ABORT EXPEDITION'), findsOneWidget);

      // Confirm abort by tapping the dialog's ABORT button
      final dialogAbortButton = find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(PixelButton, 'ABORT'),
      );
      expect(dialogAbortButton, findsOneWidget);
      await tester.tap(dialogAbortButton);

      // Let dialog dismiss and route pop animation run
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Allow background persistence discard and provider invalidation on isolate to complete
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Route should be cleanly popped back to the home launch screen
      expect(find.text('LAUNCH_EXPEDITION'), findsOneWidget);
      expect(find.byType(ActiveExpeditionScreen), findsNothing);
      expect(find.text('WARM-UP MOBILIZATION'), findsNothing);
      expect(container.read(activeSessionControllerProvider).hasActiveSession, isFalse);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('canceling abort confirmation dialog resumes active session without popping route', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(activeSessionControllerProvider.notifier);
      await controller.startSession(createTestSession());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: zenithThemeRegistry.defaultTheme.themeData,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ActiveExpeditionScreen(),
                        ),
                      );
                    },
                    child: const Text('LAUNCH_EXPEDITION'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('LAUNCH_EXPEDITION'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Advance to working set
      await tester.tap(find.text('▶ COMMENCE WORKING SETS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap abort
      await tester.tap(find.text('✕'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap CONTINUE in dialog
      final continueButton = find.widgetWithText(PixelButton, 'CONTINUE');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Still on ActiveExpeditionScreen
      expect(find.text('ACTIVE EXPEDITION'), findsOneWidget);
      expect(find.byType(ActiveExpeditionScreen), findsOneWidget);

      // Cleanup widget tree first to unmount WorkingSetScreen and dispose its periodic timer
      await tester.pumpWidget(const SizedBox());

      // Abort session and allow async persistence to settle inside runAsync
      await tester.runAsync(() async {
        await controller.abortSession();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
    });
  });
}
