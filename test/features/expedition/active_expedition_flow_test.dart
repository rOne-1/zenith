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
import 'package:zenith/features/expedition/screens/active_expedition_screen.dart';

void main() {
  group('ActiveExpeditionScreen End-to-End Flow Tests', () {
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

    WorkoutSession createTwoSetSession() {
      final startTime = DateTime.now();
      final sets = [
        WorkoutSet(
          id: 'flow_set_0',
          sessionId: 'flow_session_1',
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
        WorkoutSet(
          id: 'flow_set_1',
          sessionId: 'flow_session_1',
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
          timestamp: startTime,
          restDuration: const Duration(seconds: 60),
        ),
      ];

      return WorkoutSession(
        id: 'flow_session_1',
        startTime: startTime,
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
          home: Navigator(
            onDidRemovePage: (page) {},
            pages: const [
              MaterialPage(child: Scaffold(body: Text('TERMINAL SCREEN'))),
              MaterialPage(child: ActiveExpeditionScreen()),
            ],
          ),
        ),
      );
    }

    testWidgets('full expedition lifecycle flow: warmUp -> set 1 -> rest -> set 2 -> coolDown -> debrief', (
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

      final session = createTwoSetSession();
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      await controller.startSession(session);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // 1. Warm-Up Phase
      expect(find.text('WARM-UP MOBILIZATION'), findsOneWidget);
      expect(find.text('▶ COMMENCE WORKING SETS'), findsOneWidget);

      // Tap commence working sets
      await tester.tap(find.text('▶ COMMENCE WORKING SETS'));
      await tester.pump();

      // 2. Working Set 1
      expect(find.textContaining('SET 1 / 2'), findsOneWidget);
      expect(find.text('⚔ COMPLETE SET'), findsOneWidget);

      // Tap complete set 1
      await tester.tap(find.text('⚔ COMPLETE SET'));
      await tester.pump();

      // 3. Rest Screen
      expect(find.text('REST & RECOVERY'), findsOneWidget);
      expect(find.text('SKIP REST & START NEXT SET'), findsOneWidget);

      // Log RPE 8
      await tester.tap(find.text('8'));
      await tester.pump();
      expect(
        container.read(activeSessionControllerProvider).selectedRpe,
        equals(8),
      );

      // Skip rest and advance to Set 2
      await tester.tap(find.text('SKIP REST & START NEXT SET'));
      await tester.pump();

      // 4. Working Set 2
      expect(find.textContaining('SET 2 / 2'), findsOneWidget);
      expect(find.text('⚔ COMPLETE SET'), findsOneWidget);

      // Complete Set 2 (last set)
      await tester.tap(find.text('⚔ COMPLETE SET'));
      await tester.pump();

      // 5. Cool-Down Phase
      expect(find.text('COOL-DOWN DOWNSHIFT'), findsOneWidget);
      expect(find.text('CONCLUDE & VIEW DEBRIEF ➔'), findsOneWidget);

      // Finish cool-down
      await tester.tap(find.text('CONCLUDE & VIEW DEBRIEF ➔'));
      await tester.pumpAndSettle();

      // 6. Debrief Screen
      expect(find.text('EXPEDITION CONCLUDED'), findsOneWidget);
      expect(find.text('◀ RETURN TO TERMINAL'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('abort expedition dialog cancels or discards session', (
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

      final session = createTwoSetSession();
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      await controller.startSession(session);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Tap close/abort icon in AppBar
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Abort Dialog displayed
      expect(find.text('ABORT EXPEDITION'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(find.text('ABORT'), findsOneWidget);

      // Tap CONTINUE to dismiss
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Session still active in warmUp
      expect(
        container.read(activeSessionControllerProvider).hasActiveSession,
        isTrue,
      );

      // Tap close again and confirm ABORT
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      final abortDialogButton = find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(PixelButton, 'ABORT'),
      );
      await tester.tap(abortDialogButton);
      await tester.pumpAndSettle();

      // Allow asynchronous persistence discard and provider invalidation to complete
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Session discarded
      expect(
        container.read(activeSessionControllerProvider).hasActiveSession,
        isFalse,
      );

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  });
}
