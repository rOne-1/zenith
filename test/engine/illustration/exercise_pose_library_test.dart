import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/engine/expanded_catalog.dart';
import 'package:zenith/engine/illustration/exercise_pose_library.dart';
import 'package:zenith/features/grimoire/widgets/exercise_illustration.dart';

/// Exercise ids illustrated via sourced SVG frames rather than
/// [customPoseLibrary] -- kept in sync with the private set of the same
/// name in exercise_illustration.dart so this file can assert full
/// catalog coverage without needing that set to be public.
const _svgSourcedExerciseIds = {
  'wall_pushup',
  'knee_pushup',
  'standard_pushup',
  'feet_elevated_pushup',
  'chair_dip',
  'archer_pushup',
  'doorframe_row',
  'towel_row',
  'inverted_row',
  'standard_pullup',
  'l_sit_pullup',
  'towel_hamstring_curl',
  'nordic_curl',
  'air_squat',
  'reverse_lunge',
  'bulgarian_split_squat',
  'skater_squat',
  'assisted_pistol_squat',
  'full_pistol_squat',
  'dead_bug',
  'side_plank',
  'banded_pallof_press',
  'dragon_flag',
};

// Exercises whose real movement is asymmetric/unilateral *and* which the
// rig can actually depict as such via a secondary-limb override -- these
// must have at least one pose with a non-null override, or they'd
// silently render as an ordinary mirrored bilateral move.
//
// one_arm_pushup is deliberately excluded: a side-profile silhouette
// can't geometrically distinguish "one arm working" from "two arms
// working" the way a front view could (see its pose library comment), so
// it uses the rig's normal single-visible-limb rendering and relies on
// the FORM CUES text for the "one arm" detail instead.
const _asymmetricExerciseIds = {
  'archer_pullup',
  'single_leg_deadlift',
};

void main() {
  group('Exercise illustration coverage', () {
    test('every catalog exercise is illustrated (SVG-sourced or custom-rig)', () {
      for (final exercise in expandedExercises) {
        expect(
          isExerciseIllustrated(exercise.id),
          isTrue,
          reason:
              '${exercise.id} has no entry in _svgSourcedExerciseIds or customPoseLibrary',
        );
      }
    });

    test('the SVG-sourced and custom-rig sets don\'t overlap', () {
      final overlap = _svgSourcedExerciseIds.intersection(
        customPoseLibrary.keys.toSet(),
      );
      expect(
        overlap,
        isEmpty,
        reason: 'an exercise id should have exactly one illustration source',
      );
    });

    test('customPoseLibrary has no orphan keys (typo\'d exercise ids)', () {
      final catalogIds = expandedExercises.map((e) => e.id).toSet();
      for (final id in customPoseLibrary.keys) {
        expect(
          catalogIds.contains(id),
          isTrue,
          reason: "'$id' in customPoseLibrary is not a real catalog exercise id",
        );
      }
    });
  });

  group('customPoseLibrary pose data', () {
    test('every custom-rig exercise has at least 2 poses', () {
      customPoseLibrary.forEach((id, poses) {
        expect(
          poses.length,
          greaterThanOrEqualTo(2),
          reason: '$id has only ${poses.length} pose(s) -- an illustration '
              'must show at least a start and end position',
        );
      });
    });

    test('asymmetric exercises have at least one pose with a secondary-limb override', () {
      for (final id in _asymmetricExerciseIds) {
        final poses = customPoseLibrary[id];
        expect(poses, isNotNull, reason: '$id is missing from customPoseLibrary');
        expect(
          poses!.any((p) => p.isAsymmetric),
          isTrue,
          reason: '$id is a unilateral/asymmetric movement but no pose sets '
              'a secondary-limb override -- it would render as an ordinary '
              'mirrored bilateral move',
        );
      }
    });

    test('every pose cites a cueRef', () {
      customPoseLibrary.forEach((id, poses) {
        for (final pose in poses) {
          expect(pose.cueRef, isNotEmpty, reason: '$id has a pose with no cueRef');
        }
      });
    });
  });
}
