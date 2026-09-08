import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/engine/engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bootstrap Exercise Catalog & DAG Invariants', () {
    test('ExerciseGraph initializes cleanly without cycle errors', () {
      expect(() => createBaselineExerciseGraph(), returnsNormally);
      final graph = baselineExerciseGraph;
      expect(graph.exercises.length, equals(15));
    });

    test('All 5 ACE IFT movement patterns are represented in the catalog', () {
      final patterns = baselineExercises.map((e) => e.movementPattern).toSet();
      expect(
        patterns,
        containsAll([
          MovementPattern.pushing,
          MovementPattern.pulling,
          MovementPattern.bendAndLift,
          MovementPattern.singleLeg,
          MovementPattern.rotation,
        ]),
      );
    });

    test('Every movement pattern has a Tier 1 bodyweight-only baseline', () {
      for (final pattern in MovementPattern.values) {
        final matches = baselineExercises.where(
          (e) =>
              e.movementPattern == pattern &&
              e.difficultyTier == 1 &&
              e.equipmentRequirements.contains(Equipment.bodyweight),
        );

        expect(
          matches,
          isNotEmpty,
          reason:
              'Pattern $pattern must have at least one Tier 1 bodyweight exercise',
        );
      }
    });

    test('Every exercise includes biomechanical cues', () {
      for (final exercise in baselineExercises) {
        expect(
          exercise.defaultCues,
          isNotEmpty,
          reason: '${exercise.name} (${exercise.id}) is missing default cues',
        );
      }
    });

    test('Graph permits topological sorting and valid successor traversal', () {
      final order = baselineExerciseGraph.getTopologicalOrder();
      expect(order.length, equals(15));

      final pushupProgressions = baselineExerciseGraph.getProgressions(
        standardPushup,
      );
      expect(pushupProgressions, contains(feetElevatedPushup));

      final pushup2Progressions = baselineExerciseGraph.getProgressions(
        feetElevatedPushup,
      );
      expect(pushup2Progressions, contains(chairDip));

      final chairDipProgressions = baselineExerciseGraph.getProgressions(
        chairDip,
      );
      expect(chairDipProgressions, isEmpty);
    });

    test('findBaselineExercise resolves exercises by unique id', () {
      expect(findBaselineExercise('standard_pushup'), equals(standardPushup));
      expect(findBaselineExercise('standard_pullup'), equals(standardPullup));
      expect(findBaselineExercise('unknown_id'), isNull);
    });
  });

  group('SbeeEngine & Database Integration', () {
    late SbeeDatabase database;
    late DriftSessionRepository sessionRepo;
    late DriftProgressionRepository progressionRepo;
    late SbeeEngine engine;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      sessionRepo = DriftSessionRepository(database);
      progressionRepo = DriftProgressionRepository(database);
      engine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: baselineExerciseGraph,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'generateNextWorkout yields a valid session for bodyweight-only user',
      () async {
        final workout = await engine.generateNextWorkout(
          userId: 'test_user_001',
          currentTime: DateTime(2026, 9, 8, 12, 0),
          availableEquipment: {Equipment.bodyweight},
        );

        expect(workout.id, isNotEmpty);
        expect(workout.sets, isNotEmpty);
        expect(workout.dayType, isNotNull);

        // Verify all prescribed exercises exist in our catalog and require only bodyweight
        for (final set in workout.sets) {
          final exercise = findBaselineExercise(set.exerciseId);
          expect(exercise, isNotNull);
          expect(
            exercise!.equipmentRequirements,
            contains(Equipment.bodyweight),
          );
        }
      },
    );

    test(
      'resumeActiveSession returns null when no incomplete session exists',
      () async {
        final resumed = await engine.resumeActiveSession();
        expect(resumed, isNull);
      },
    );

    test(
      'resumeActiveSession recovers an in-progress session after logging set',
      () async {
        final workout = await engine.generateNextWorkout(
          userId: 'recovery_user',
          currentTime: DateTime(2026, 9, 8, 14, 0),
          availableEquipment: {Equipment.bodyweight},
        );

        final manager = engine.createWorkoutSession(session: workout);
        manager.startWorkout();
        manager.logCurrentSet(
          reps: workout.sets.first.reps,
          reportedRpe: workout.sets.first.targetRpe,
        );
        await Future<void>.delayed(Duration.zero);
        manager.dispose();

        // Probe recovery directly through engine facade
        final recovered = await engine.resumeActiveSession();
        expect(recovered, isNotNull);
        expect(recovered!.currentState.session!.id, equals(workout.id));
        expect(recovered.currentState.currentSetIndex, equals(1));
        expect(recovered.currentState.state, equals(SessionState.activeSet));

        recovered.dispose();
      },
    );

    test(
      'discardActiveSession removes incomplete session from persistence',
      () async {
        final workout = await engine.generateNextWorkout(
          userId: 'discard_user',
          currentTime: DateTime(2026, 9, 8, 15, 0),
          availableEquipment: {Equipment.bodyweight},
        );

        final manager = engine.createWorkoutSession(session: workout);
        manager.startWorkout();
        manager.logCurrentSet(
          reps: workout.sets.first.reps,
          reportedRpe: workout.sets.first.targetRpe,
        );
        await Future<void>.delayed(Duration.zero);
        manager.dispose();

        final existing = await engine.resumeActiveSession();
        expect(existing, isNotNull);
        existing?.dispose();

        await engine.discardActiveSession();
        expect(await engine.resumeActiveSession(), isNull);
      },
    );
  });

  group('Riverpod Providers & SbeeService', () {
    test(
      'sbeeServiceProvider exposes engine facade methods seamlessly',
      () async {
        final container = ProviderContainer(
          overrides: [
            sbeeDatabaseProvider.overrideWithValue(
              SbeeDatabase(NativeDatabase.memory()),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sbeeService = container.read(sbeeServiceProvider);
        expect(sbeeService, isNotNull);

        final workout = await sbeeService.generateNextWorkout(
          currentTime: DateTime(2026, 9, 8, 16, 0),
        );
        expect(workout.sets, isNotEmpty);

        final resumeProbe = await container.read(
          activeSessionResumeProvider.future,
        );
        expect(resumeProbe, isNull);
      },
    );
  });
}
