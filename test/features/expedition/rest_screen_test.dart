import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/widgets.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/expedition/controllers/active_session_controller.dart';
import 'package:zenith/features/expedition/screens/rest_screen.dart';

void main() {
  group('RestScreen Widget Tests', () {
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

    WorkoutSession createTestSession({int setCount = 2}) {
      final sets = [
        WorkoutSet(
          id: 'set_0',
          sessionId: 'test_session_1',
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
          timestamp: DateTime.now(),
          restDuration: const Duration(seconds: 60),
        ),
        WorkoutSet(
          id: 'set_1',
          sessionId: 'test_session_1',
          exerciseId: 'knee_pushup',
          movementPattern: MovementPattern.pushing,
          setNumber: 2,
          reps: 12,
          targetRpe: 8,
          variables: const MillerVariables(
            load: 1,
            bodyPosition: 1,
            rom: 1,
            height: 2,
            tempo: 1,
          ),
          timestamp: DateTime.now(),
          restDuration: const Duration(seconds: 60),
        ),
      ];

      return WorkoutSession(
        id: 'test_session_1',
        startTime: DateTime.now(),
        sets: sets.take(setCount).toList(),
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
            body: RestScreen(),
          ),
        ),
      );
    }

    testWidgets('renders rest countdown, progress bar, and 1-10 RPE selector', (
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

      final session = createTestSession(setCount: 2);
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      await controller.startSession(session);
      controller.completeWarmUp();
      controller.completeCurrentSet(actualReps: 10);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Header verification
      expect(find.text('REST & RECOVERY // 休息中'), findsOneWidget);
      expect(find.text('REST TIME REMAINING'), findsOneWidget);
      expect(find.text('+30s'), findsOneWidget);

      // Countdown & Progress bar
      expect(find.byType(PixelCountdownBar), findsOneWidget);

      // RPE section
      expect(find.text('SET EXERTION (BORG RPE)'), findsOneWidget);
      expect(find.text('TARGET: 8 RPE'), findsOneWidget);

      // Next station ticket
      expect(find.text('NEXT STATION // 次の種目'), findsOneWidget);

      // Action footer
      expect(find.text('SKIP REST & START NEXT SET'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('+30s button extends rest time duration', (tester) async {
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

      final session = createTestSession(setCount: 2);
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      await controller.startSession(session);
      controller.completeWarmUp();
      controller.completeCurrentSet(actualReps: 10);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      final initialRest = container
          .read(activeSessionControllerProvider)
          .restRemaining
          .inSeconds;

      // Tap +30s
      await tester.tap(find.text('+30s'));
      await tester.pump();

      final updatedRest = container
          .read(activeSessionControllerProvider)
          .restRemaining
          .inSeconds;
      expect(updatedRest, equals(initialRest + 30));

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('tapping RPE button updates selected RPE and coaching feedback', (
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

      final session = createTestSession(setCount: 2);
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      await controller.startSession(session);
      controller.completeWarmUp();
      controller.completeCurrentSet(actualReps: 10);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Tap RPE 9
      await tester.tap(find.text('9'));
      await tester.pump();

      expect(
        container.read(activeSessionControllerProvider).selectedRpe,
        equals(9),
      );
      expect(find.textContaining('RPE 9:'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets(
      'renders without RenderFlex overflow at a narrow mobile viewport',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            sbeeDatabaseProvider.overrideWithValue(database),
          ],
        );

        final session = createTestSession(setCount: 2);
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        await controller.startSession(session);
        controller.completeWarmUp();
        controller.completeCurrentSet(actualReps: 10);

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Cleanup
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      },
    );

    testWidgets('tapping skip rest advances to next active set', (tester) async {
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

      final session = createTestSession(setCount: 2);
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      await controller.startSession(session);
      controller.completeWarmUp();
      controller.completeCurrentSet(actualReps: 10);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Tap skip rest button
      await tester.tap(find.text('SKIP REST & START NEXT SET'));
      await tester.pump();

      final state = container.read(activeSessionControllerProvider);
      expect(state.fsmState, equals(SessionState.activeSet));
      expect(state.currentSetIndex, equals(1));

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  });
}
