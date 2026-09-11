import 'dart:async';

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

/// Delegates to a real [DriftSessionRepository] for every operation except
/// [saveSession], which doesn't complete until [gate] does -- lets a test
/// hold SBEE's fire-and-forget incremental persist open on demand.
class _DelayedSaveSessionRepository implements SessionRepository {
  final DriftSessionRepository _inner;
  final Future<void> gate;
  int saveCount = 0;

  _DelayedSaveSessionRepository(this._inner, this.gate);

  @override
  Future<void> saveSession(WorkoutSession session) async {
    saveCount++;
    await gate;
    await _inner.saveSession(session);
  }

  @override
  Future<WorkoutSession?> getSession(String id) => _inner.getSession(id);

  @override
  Future<List<WorkoutSession>> getSessionsInDateRange(
    DateTime start,
    DateTime end,
  ) => _inner.getSessionsInDateRange(start, end);

  @override
  Future<List<WorkoutSet>> getSetsForMovementPattern(
    MovementPattern pattern,
    DateTime since,
  ) => _inner.getSetsForMovementPattern(pattern, since);

  @override
  Future<List<WorkoutSet>> getSetsInDateRange(DateTime start, DateTime end) =>
      _inner.getSetsInDateRange(start, end);

  @override
  Future<WorkoutSession?> getMostRecentCompletedSession({
    bool requireDayType = false,
  }) => _inner.getMostRecentCompletedSession(requireDayType: requireDayType);

  @override
  Future<DateTime?> getEarliestCompletedSessionStart() =>
      _inner.getEarliestCompletedSessionStart();

  @override
  Future<int> getCompletedSessionCount() => _inner.getCompletedSessionCount();

  @override
  Future<int> getReportedSetCountForExercise(String exerciseId) =>
      _inner.getReportedSetCountForExercise(exerciseId);

  @override
  Future<WorkoutSession?> getActiveIncompleteSession() =>
      _inner.getActiveIncompleteSession();

  @override
  Future<void> deleteSession(String id) => _inner.deleteSession(id);
}

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

    test(
      'a corrected RPE for an earlier set survives advancing past it',
      () async {
        // Regression coverage: the progressStream reconciliation used to
        // only re-merge the CURRENT set index against the manager's
        // (possibly stale) session, so a correction logRpe() made for an
        // earlier set could be silently overwritten by the manager's
        // original placeholder value once the FSM advanced to a later set.
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(setCount: 3);

        await controller.startSession(session);
        controller.completeWarmUp();

        // Set 0: complete, then correct its RPE on the Rest screen.
        controller.completeCurrentSet(actualReps: 10);
        await controller.logRpe(6);
        expect(
          container
              .read(activeSessionControllerProvider)
              .session!
              .sets[0]
              .reportedRpe,
          equals(6),
        );

        // Advance through set 1 (a manager event that used to cause the
        // set-0 correction above to revert). The merge happens inside the
        // manager's progressStream listener, which fires asynchronously --
        // flush pending microtasks so that listener actually runs before
        // asserting, or this test would pass regardless of the bug.
        controller.completeRest();
        controller.completeCurrentSet(actualReps: 10);
        await Future<void>.delayed(Duration.zero);

        expect(
          container
              .read(activeSessionControllerProvider)
              .session!
              .sets[0]
              .reportedRpe,
          equals(6),
          reason:
              'set 0\'s corrected RPE must not revert once the FSM advances past it',
        );
      },
    );

    test(
      'a redundant double-call to an FSM-advancing method is a safe no-op',
      () async {
        // Regression coverage: neither completeCurrentSet nor completeRest
        // guarded against being called again after the FSM had already
        // moved on (e.g. a rapid double-tap firing the same button twice
        // before the widget rebuilds away from it) -- the second call
        // reached SBEE's own state-machine guard, which throws a
        // synchronous, uncaught StateError for an out-of-state call.
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(setCount: 2);
        await controller.startSession(session);
        controller.completeWarmUp();

        // First call is real (activeSet -> rest); the second must be a
        // silent no-op rather than throwing.
        controller.completeCurrentSet(actualReps: 10);
        expect(
          () => controller.completeCurrentSet(actualReps: 10),
          returnsNormally,
        );
        expect(
          container.read(activeSessionControllerProvider).fsmState,
          equals(SessionState.rest),
        );

        controller.completeRest();
        expect(() => controller.completeRest(), returnsNormally);
        expect(
          container.read(activeSessionControllerProvider).fsmState,
          equals(SessionState.activeSet),
        );

        // A stale completeWarmUp() call after already advancing must also
        // be a no-op, not revert the FSM backward.
        expect(() => controller.completeWarmUp(), returnsNormally);
        expect(
          container.read(activeSessionControllerProvider).fsmState,
          equals(SessionState.activeSet),
        );
      },
    );

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

      final after = container
          .read(activeSessionControllerProvider)
          .restRemaining;
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
          reason:
              'manager must be disposed and cleared once a session completes',
        );

        final session2 = createTestSession(setCount: 1);
        await controller.startSession(session2);
        expect(controller.currentManager, isNotNull);

        await controller.abortSession();
        expect(
          controller.currentManager,
          isNull,
          reason:
              'manager must be disposed and cleared once a session is aborted',
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
          reason:
              'macrocycleProvider must be invalidated on session completion',
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

    test(
      'abortSession does not resurrect the session via a still-in-flight incremental persist',
      () async {
        // Regression coverage: SBEE's incremental persist (fired by
        // startSession's initializeSession) is fire-and-forget. If
        // abortSession's discardActiveSession() (read-then-delete) ran
        // before that save landed, the save could complete afterward and
        // resurrect the row the user just discarded.
        final saveGate = Completer<void>();
        final delayedRepo = _DelayedSaveSessionRepository(
          DriftSessionRepository(database),
          saveGate.future,
        );

        final raceContainer = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            sbeeDatabaseProvider.overrideWithValue(database),
            sessionRepositoryProvider.overrideWithValue(delayedRepo),
          ],
        );
        addTearDown(raceContainer.dispose);

        final controller = raceContainer.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession();

        await controller.startSession(session);
        expect(delayedRepo.saveCount, equals(1));

        final abortFuture = controller.abortSession();

        // The initial save is still gated shut -- abortSession must be
        // waiting on it, not racing ahead to discardActiveSession().
        await Future<void>.delayed(Duration.zero);
        expect(
          raceContainer.read(activeSessionControllerProvider).hasActiveSession,
          isTrue,
          reason: 'abortSession must not proceed while a persist is in flight',
        );

        saveGate.complete();
        await abortFuture;

        final survivor = await delayedRepo.getActiveIncompleteSession();
        expect(
          survivor,
          isNull,
          reason:
              'the delayed save must not resurrect the session after discardActiveSession deleted it',
        );
      },
    );
  });
}
