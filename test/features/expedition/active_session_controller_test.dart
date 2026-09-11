import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/expedition/controllers/active_session_controller.dart';
import 'package:zenith/features/armory/models/user_profile.dart';
import 'package:zenith/features/armory/providers/user_profile_provider.dart';
import 'package:zenith/features/outpost/services/streak_service.dart';
import 'package:zenith/features/sanctuary/services/macrocycle_service.dart';

void main() {
  group('ActiveSessionController Unit Tests', () {
    late SbeeDatabase database;
    late ProviderContainer container;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      database = SbeeDatabase(NativeDatabase.memory());

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(database),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
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
            load: 1,
            bodyPosition: 1,
            rom: 1,
            height: 1,
            tempo: 1,
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

    test('startSession initializes FSM in warmUp state', () async {
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      final session = createTestSession();

      await controller.startSession(session);

      final state = container.read(activeSessionControllerProvider);
      expect(state.hasActiveSession, isTrue);
      expect(state.fsmState, equals(SessionState.warmUp));
      expect(state.currentSetIndex, equals(0));
      expect(state.totalSets, equals(2));
      expect(state.currentRepsInput, equals(10));
    });

    test('completeWarmUp advances FSM to activeSet', () async {
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      final session = createTestSession();

      await controller.startSession(session);
      controller.completeWarmUp();

      final state = container.read(activeSessionControllerProvider);
      expect(state.fsmState, equals(SessionState.activeSet));
      expect(state.currentSetIndex, equals(0));
    });

    test('updateRepsInput updates reps count', () async {
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      final session = createTestSession();

      await controller.startSession(session);
      controller.completeWarmUp();
      controller.updateRepsInput(12);

      expect(
        container.read(activeSessionControllerProvider).currentRepsInput,
        equals(12),
      );
    });

    test('completeCurrentSet transitions to rest on non-last set', () async {
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      final session = createTestSession(setCount: 2);

      await controller.startSession(session);
      controller.completeWarmUp();
      controller.completeCurrentSet(actualReps: 10);

      final state = container.read(activeSessionControllerProvider);
      expect(state.fsmState, equals(SessionState.rest));
      expect(state.restRemaining.inSeconds, greaterThan(0));
    });

    test('logRpe updates reported RPE for current set', () async {
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      final session = createTestSession(setCount: 2);

      await controller.startSession(session);
      controller.completeWarmUp();
      controller.completeCurrentSet(actualReps: 10);

      await controller.logRpe(9);

      final state = container.read(activeSessionControllerProvider);
      expect(state.selectedRpe, equals(9));
      expect(state.session!.sets[0].reportedRpe, equals(9));
    });

    test('addRestTime extends rest duration', () async {
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      final session = createTestSession(setCount: 2);

      await controller.startSession(session);
      controller.completeWarmUp();
      controller.completeCurrentSet(actualReps: 10);

      final before = container
          .read(activeSessionControllerProvider)
          .restRemaining;
      controller.addRestTime(const Duration(seconds: 30));

      final after = container.read(activeSessionControllerProvider).restRemaining;
      expect(after.inSeconds, equals(before.inSeconds + 30));
    });

    test('completeRest transitions to next activeSet', () async {
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      final session = createTestSession(setCount: 2);

      await controller.startSession(session);
      controller.completeWarmUp();
      controller.completeCurrentSet(actualReps: 10);

      controller.completeRest();

      final state = container.read(activeSessionControllerProvider);
      expect(state.fsmState, equals(SessionState.activeSet));
      expect(state.currentSetIndex, equals(1));
    });

    test('completing last set transitions directly to coolDown', () async {
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      final session = createTestSession(setCount: 1); // Only 1 set

      await controller.startSession(session);
      controller.completeWarmUp();
      controller.completeCurrentSet(actualReps: 10);

      final state = container.read(activeSessionControllerProvider);
      expect(state.fsmState, equals(SessionState.coolDown));
    });

    test(
      'completeCoolDown finalizes session and logs Miller adaptations',
      () async {
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(setCount: 1);

        await controller.startSession(session);
        controller.completeWarmUp();
        controller.completeCurrentSet(actualReps: 10);
        await controller.logRpe(8);

        await controller.completeCoolDown();

        final state = container.read(activeSessionControllerProvider);
        expect(state.fsmState, equals(SessionState.completed));
        expect(state.session!.isCompleted, isTrue);
        expect(state.adaptations, isNotEmpty);
      },
    );

    test(
      'completeCoolDown and abortSession both dispose the SessionStreamManager',
      () async {
        // Regression coverage: the manager (and its underlying RxDart
        // subject) used to never be disposed anywhere, leaking a stream on
        // every session lifecycle transition.
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session1 = createTestSession(setCount: 1);
        await controller.startSession(session1);
        controller.completeWarmUp();
        controller.completeCurrentSet(actualReps: 10);
        await controller.logRpe(8);
        await controller.completeCoolDown();

        expect(
          controller.currentManager,
          isNull,
          reason: 'manager must be disposed and cleared once a session completes',
        );

        final session2 = createTestSession(setCount: 1);
        await controller.startSession(session2);
        expect(controller.currentManager, isNotNull);

        await controller.abortSession();
        expect(
          controller.currentManager,
          isNull,
          reason: 'manager must be disposed and cleared once a session is aborted',
        );
      },
    );

    test(
      'finalizeSession reflects SBEE\'s female-adjusted decision, not a raw RPE comparison',
      () async {
        // Untrained_Female, cycle day 1-3 -> SBEE internally adjusts the
        // target RPE down by 1 before evaluating (adjustTargetRpe). Raw
        // targetRpe 5, reportedRpe 3: comparing against the RAW target
        // (5) would say increment (3 < 5-1=4); comparing against SBEE's
        // real ADJUSTED target (4) is "maintain" (3 is not < 4-1=3). This
        // asserts the controller reports what SBEE actually did, not the
        // raw comparison a naive re-derivation would produce.
        container.read(userProfileProvider.notifier).state = UserProfile(
          availableEquipment: const {Equipment.bodyweight},
          femaleProfile: const FemaleProfile(
            userStatus: 'Untrained_Female',
            cycleDay: 2,
            hasKneeDiscomfort: false,
            age: 25,
            hasJointPain: false,
          ),
        );

        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = WorkoutSession(
          id: 'female_adjust_session',
          startTime: DateTime.now(),
          sets: [
            WorkoutSet(
              id: 'set_0',
              sessionId: 'female_adjust_session',
              exerciseId: 'standard_pushup',
              movementPattern: MovementPattern.pushing,
              setNumber: 1,
              reps: 10,
              targetRpe: 5,
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
          ],
        );

        await controller.startSession(session);
        controller.completeWarmUp();
        controller.completeCurrentSet(actualReps: 10);
        await controller.logRpe(3);
        await controller.completeCoolDown();

        final state = container.read(activeSessionControllerProvider);
        final record = state.adaptations.single;
        expect(record.action, equals(AutoregulationAction.maintain));
        expect(record.variables, equals(const MillerVariables()));
      },
    );

    test(
      'completeCoolDown invalidates the Outpost dashboard\'s streak and weekly-stats providers',
      () async {
        // Force both dashboard providers to resolve once, up front, so
        // there's a "before" Future identity to compare against -- a
        // FutureProvider's read().future returns a new Future instance
        // each time the provider is invalidated and recomputed, which is
        // exactly what should happen once a session completes (the Outpost
        // screen would otherwise show stale numbers forever, since it never
        // gets disposed inside the app shell's IndexedStack).
        final streakBefore = container.read(currentStreakProvider.future);
        final macrocycleBefore = container.read(macrocycleProvider.future);
        await streakBefore;
        await macrocycleBefore;

        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(setCount: 1);

        await controller.startSession(session);
        controller.completeWarmUp();
        controller.completeCurrentSet(actualReps: 10);
        await controller.logRpe(8);
        await controller.completeCoolDown();

        final streakAfter = container.read(currentStreakProvider.future);
        final macrocycleAfter = container.read(macrocycleProvider.future);

        expect(
          identical(streakBefore, streakAfter),
          isFalse,
          reason:
              'currentStreakProvider must be invalidated on session completion',
        );
        expect(
          identical(macrocycleBefore, macrocycleAfter),
          isFalse,
          reason: 'macrocycleProvider must be invalidated on session completion',
        );

        // Both must still resolve cleanly after invalidation.
        await streakAfter;
        await macrocycleAfter;
      },
    );

    test('abortSession clears state and cancels active session', () async {
      final controller = container.read(
        activeSessionControllerProvider.notifier,
      );
      final session = createTestSession();

      await controller.startSession(session);
      await controller.abortSession();

      final state = container.read(activeSessionControllerProvider);
      expect(state.hasActiveSession, isFalse);
    });
  });
}
