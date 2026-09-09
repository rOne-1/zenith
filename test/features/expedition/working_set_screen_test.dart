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
import 'package:zenith/features/expedition/screens/working_set_screen.dart';

void main() {
  group('WorkingSetScreen Widget Tests', () {
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
      final sets = List.generate(
        setCount,
        (i) => WorkoutSet(
          id: 'set_$i',
          sessionId: 'test_session_1',
          exerciseId: 'standard_pushup',
          movementPattern: MovementPattern.pushing,
          setNumber: i + 1,
          reps: 10,
          targetRpe: 8,
          variables: const MillerVariables(
            load: 2,
            bodyPosition: 1,
            rom: 3,
            height: 1,
            tempo: 2,
          ),
          timestamp: DateTime.now(),
          restDuration: const Duration(seconds: 60),
        ),
      );

      return WorkoutSession(
        id: 'test_session_1',
        startTime: DateTime.now(),
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
            body: WorkingSetScreen(),
          ),
        ),
      );
    }

    testWidgets('renders station signboard, cues card, and Kenneth Miller badges', (
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

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Signboard verification
      expect(find.textContaining('SET 1 / 2'), findsOneWidget);
      expect(find.textContaining('PUSH LINE'), findsWidgets);

      // Cues card verification
      expect(find.text('FORM CUES'), findsOneWidget);

      // Kenneth Miller badges verification (LOAD, POS, ROM, ELEV, TEMPO)
      expect(find.text('LOAD: '), findsOneWidget);
      expect(find.text('POS: '), findsOneWidget);
      expect(find.text('ROM: '), findsOneWidget);
      expect(find.text('ELEV: '), findsOneWidget);
      expect(find.text('TEMPO: '), findsOneWidget);

      // Reps verification
      expect(find.text('10'), findsWidgets);
      expect(find.text('TARGET: 10 REPS'), findsOneWidget);

      // Hero complete button
      expect(find.text('✓ COMPLETE SET'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('rep adjuster buttons modify reps input count', (tester) async {
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

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Initial reps should be 10
      expect(container.read(activeSessionControllerProvider).currentRepsInput, 10);

      // Tap '+' button
      await tester.tap(find.text('+'));
      await tester.pump();
      expect(container.read(activeSessionControllerProvider).currentRepsInput, 11);

      // Tap '−' (Unicode minus) button twice
      await tester.tap(find.text('−'));
      await tester.pump();
      await tester.tap(find.text('−'));
      await tester.pump();
      expect(container.read(activeSessionControllerProvider).currentRepsInput, 9);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('tapping complete set button advances to rest state', (tester) async {
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

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Tap Complete Set
      await tester.tap(find.text('✓ COMPLETE SET'));
      await tester.pump();

      expect(
        container.read(activeSessionControllerProvider).fsmState,
        equals(SessionState.rest),
      );

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('tactical skip opens confirmation dialog and can cancel or skip', (
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

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Tap bottom SKIP button
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('SKIP SET'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      // Still in activeSet
      expect(
        container.read(activeSessionControllerProvider).fsmState,
        equals(SessionState.activeSet),
      );

      // Open again and confirm skip
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      // Tap the SKIP button inside the dialog
      final skipDialogButton = find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(PixelButton, 'SKIP'),
      );
      await tester.tap(skipDialogButton);
      await tester.pump();

      // Skipped: transitioned to rest
      expect(
        container.read(activeSessionControllerProvider).fsmState,
        equals(SessionState.rest),
      );

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

        // Use the longest movement-pattern line name ("BEND & LIFT LINE")
        // to stress-test the signboard header row at the narrowest width.
        final session = WorkoutSession(
          id: 'test_session_1',
          startTime: DateTime.now(),
          sets: [
            WorkoutSet(
              id: 'set_0',
              sessionId: 'test_session_1',
              exerciseId: 'bodyweight_hip_hinge',
              movementPattern: MovementPattern.bendAndLift,
              setNumber: 1,
              reps: 10,
              targetRpe: 8,
              variables: const MillerVariables(
                load: 2,
                bodyPosition: 1,
                rom: 3,
                height: 1,
                tempo: 2,
              ),
              timestamp: DateTime.now(),
              restDuration: const Duration(seconds: 60),
            ),
          ],
        );
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        await controller.startSession(session);
        controller.completeWarmUp();

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Cleanup
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      },
    );
  });
}
