import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/engine/expanded_catalog.dart';

void main() {
  group('Expanded Exercise Catalog & DAG Invariants (PKG-1.5)', () {
    test('Expanded catalog contains 25+ exercises', () {
      expect(expandedExercises.length, greaterThanOrEqualTo(25));
      expect(expandedExercises.length, equals(31));
    });

    test('ExerciseGraph initializes cleanly without cycles', () {
      expect(() => createExpandedExerciseGraph(), returnsNormally);
      final graph = expandedExerciseGraph;
      expect(graph.exercises.length, equals(31));
    });

    test('All 5 ACE IFT movement patterns are represented', () {
      final patterns = expandedExercises.map((e) => e.movementPattern).toSet();
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

    test('Every movement pattern has a Tier 1 bodyweight-only entry', () {
      for (final pattern in MovementPattern.values) {
        final matches = expandedExercises.where(
          (e) =>
              e.movementPattern == pattern &&
              e.difficultyTier == 1 &&
              e.equipmentRequirements.contains(Equipment.bodyweight),
        );

        expect(
          matches,
          isNotEmpty,
          reason:
              'Movement pattern $pattern must have at least one Tier 1 bodyweight exercise',
        );
      }
    });

    test('Catalog spans Difficulty Tiers 1 through 6', () {
      final tiers = expandedExercises.map((e) => e.difficultyTier).toSet();
      expect(tiers, containsAll([1, 2, 3, 4, 5, 6]));

      // Verify clean split: Core (T1-T3) and Specialty (T4-T6)
      final coreCount = expandedExercises
          .where((e) => e.difficultyTier <= 3)
          .length;
      final specialtyCount = expandedExercises
          .where((e) => e.difficultyTier > 3)
          .length;

      expect(coreCount, greaterThanOrEqualTo(15));
      expect(specialtyCount, greaterThanOrEqualTo(8));
    });

    test(
      'Single Leg and Rotation lines have a clean, gap-free tier sequence',
      () {
        // Regression coverage: assistedPistolSquat previously duplicated
        // skaterSquat's tier 4 (skipping tier 5) on the Single Leg line,
        // and dragonFlag previously sat at tier 6 (skipping tier 5) on the
        // Rotation line, both misrepresenting the intended 1..N progression
        // in the Grimoire's Metro Transit Map UI. Scoped to the lines whose
        // exercise count matches their tier span (Bend & Lift, Single Leg,
        // Rotation) -- Pushing (8 exercises across 6 tiers) and Pulling (7
        // across 6) intentionally repeat tiers by design, so a universal
        // no-duplicates rule across all 5 lines would be a false invariant.
        for (final pattern in [
          MovementPattern.bendAndLift,
          MovementPattern.singleLeg,
          MovementPattern.rotation,
        ]) {
          final tiers = expandedExercises
              .where((e) => e.movementPattern == pattern)
              .map((e) => e.difficultyTier)
              .toList()
            ..sort();
          final expected = List<int>.generate(tiers.length, (i) => i + 1);
          expect(
            tiers,
            equals(expected),
            reason:
                '$pattern line has tiers $tiers, expected a clean 1..${tiers.length} sequence with no gaps or duplicates',
          );
        }
      },
    );

    test(
      'Every exercise has non-empty default cues and valid metro metadata',
      () {
        for (final ex in expandedExercises) {
          expect(
            ex.defaultCues,
            isNotEmpty,
            reason: '${ex.name} (${ex.id}) missing default cues',
          );

          final meta = MetroStationMeta.forExercise(ex);
          expect(meta.stationCode, isNotEmpty);
          expect(meta.defaultLoadScore, inInclusiveRange(1, 5));
          expect(meta.defaultPositionScore, inInclusiveRange(1, 5));
          expect(meta.defaultRomScore, inInclusiveRange(1, 5));
          expect(meta.defaultElevationScore, inInclusiveRange(1, 5));
          expect(meta.defaultTempoScore, inInclusiveRange(1, 5));
        }
      },
    );

    test('Topological ordering and progression pathways execute cleanly', () {
      final order = expandedExerciseGraph.getTopologicalOrder();
      expect(order.length, equals(31));

      // Push line progression pathway
      final wallSuccessors = expandedExerciseGraph.getProgressions(wallPushup);
      expect(wallSuccessors, contains(kneePushup));

      final kneeSuccessors = expandedExerciseGraph.getProgressions(kneePushup);
      expect(kneeSuccessors, contains(standardPushup));

      final archerSuccessors = expandedExerciseGraph.getProgressions(
        archerPushup,
      );
      expect(archerSuccessors, contains(oneArmPushup));

      final oneArmSuccessors = expandedExerciseGraph.getProgressions(
        oneArmPushup,
      );
      expect(oneArmSuccessors, isEmpty);

      // Pull line progression pathway
      final doorframeSuccessors = expandedExerciseGraph.getProgressions(
        doorframeRow,
      );
      expect(doorframeSuccessors, contains(towelRow));

      final archerPullSuccessors = expandedExerciseGraph.getProgressions(
        archerPullup,
      );
      expect(archerPullSuccessors, contains(muscleUp));
    });

    test('findExpandedExercise retrieves exercises by id', () {
      expect(findExpandedExercise('one_arm_pushup'), equals(oneArmPushup));
      expect(findExpandedExercise('muscle_up'), equals(muscleUp));
      expect(
        findExpandedExercise('full_pistol_squat'),
        equals(fullPistolSquat),
      );
      expect(findExpandedExercise('non_existent'), isNull);
    });
  });
}
