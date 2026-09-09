import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/expedition/controllers/active_session_controller.dart';
import 'package:zenith/features/expedition/screens/expedition_debrief_screen.dart';

void main() {
  group('ExpeditionDebriefScreen Widget Tests', () {
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

    WorkoutSession createFinishedSession() {
      final startTime = DateTime.now().subtract(const Duration(minutes: 15));
      final sets = [
        WorkoutSet(
          id: 'set_0',
          sessionId: 'test_session_debrief',
          exerciseId: 'standard_pushup',
          movementPattern: MovementPattern.pushing,
          setNumber: 1,
          reps: 12,
          targetRpe: 8,
          reportedRpe: 7,
          variables: const MillerVariables(
            load: 2,
            bodyPosition: 1,
            rom: 3,
            height: 1,
            tempo: 2,
          ),
          timestamp: startTime.add(const Duration(minutes: 5)),
          restDuration: const Duration(seconds: 60),
        ),
        WorkoutSet(
          id: 'set_1',
          sessionId: 'test_session_debrief',
          exerciseId: 'standard_pushup',
          movementPattern: MovementPattern.pushing,
          setNumber: 2,
          reps: 10,
          targetRpe: 8,
          reportedRpe: 9,
          variables: const MillerVariables(
            load: 2,
            bodyPosition: 1,
            rom: 3,
            height: 1,
            tempo: 2,
          ),
          timestamp: startTime.add(const Duration(minutes: 10)),
          restDuration: const Duration(seconds: 60),
        ),
      ];

      return WorkoutSession(
        id: 'test_session_debrief',
        startTime: startTime,
        endTime: startTime.add(const Duration(minutes: 15)),
        sets: sets,
      );
    }

    Widget createTestWidget({
      required ProviderContainer container,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: const Scaffold(
            body: ExpeditionDebriefScreen(),
          ),
        ),
      );
    }

    testWidgets('renders telemetry metrics and Kenneth Miller adaptations', (
      tester,
    ) async {
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

      final session = createFinishedSession();
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      await controller.startSession(session);

      // Simulate completed session with adaptation records
      final adaptations = [
        const MillerAdaptationRecord(
          exerciseId: 'standard_pushup',
          exerciseName: 'Standard Push-up',
          reps: 12,
          targetRpe: 8,
          reportedRpe: 7,
          variables: MillerVariables(
            load: 2,
            bodyPosition: 1,
            rom: 3,
            height: 1,
            tempo: 2,
          ),
          action: AutoregulationAction.increment,
          adaptationSummary:
              'Low exertion detected. Kenneth Miller progressive overload unlocked.',
        ),
      ];

      // Update state to completed with adaptations
      controller.state = controller.state.copyWith(
        fsmState: SessionState.completed,
        session: session,
        adaptations: adaptations,
      );

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Header verification
      expect(find.text('EXPEDITION CONCLUDED'), findsOneWidget);
      expect(find.text('SESSION DEBRIEF & NEUROMUSCULAR TELEMETRY'), findsOneWidget);

      // Telemetry cards
      expect(find.text('COMPLETED SETS'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('TOTAL VOLUME'), findsOneWidget);
      expect(find.text('22 REPS'), findsOneWidget);
      expect(find.text('AVERAGE RPE'), findsOneWidget);
      expect(find.text('8.0'), findsOneWidget);
      expect(find.text('DURATION'), findsOneWidget);

      // Adaptations card
      expect(find.text('KENNETH MILLER ADAPTATIONS'), findsOneWidget);
      expect(find.text('STANDARD PUSH-UP'), findsOneWidget);
      expect(find.textContaining('RPE 7 (TARGET 8)'), findsOneWidget);
      expect(
        find.textContaining('progressive overload unlocked'),
        findsOneWidget,
      );

      // Return button
      expect(find.text('◀ RETURN TO TERMINAL'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('tapping return to terminal pops screen', (tester) async {
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

      final session = createFinishedSession();
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      await controller.startSession(session);
      controller.state = controller.state.copyWith(
        fsmState: SessionState.completed,
        session: session,
      );

      bool popped = false;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: zenithThemeRegistry.defaultTheme.themeData,
            home: Navigator(
              onDidRemovePage: (page) {
                popped = true;
              },
              pages: const [
                MaterialPage(child: Text('TERMINAL SCREEN')),
                MaterialPage(child: ExpeditionDebriefScreen()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap Return button
      await tester.tap(find.text('◀ RETURN TO TERMINAL'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  });
}
