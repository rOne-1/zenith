import 'package:sbee/sbee.dart';

import 'expanded_catalog.dart';
export 'expanded_catalog.dart';

/// Baseline 15-exercise catalog for the initial onboarding foundation.
const List<Exercise> baselineExercises = [
  standardPushup,
  feetElevatedPushup,
  chairDip,
  doorframeRow,
  towelRow,
  standardPullup,
  hipHinge,
  goodMorning,
  singleLegDeadlift,
  airSquat,
  reverseLunge,
  bulgarianSplitSquat,
  deadBug,
  sidePlank,
  bandedPallofPress,
];

/// Compiled acyclic Directed Acyclic Graph (DAG) for baseline Zenith.
ExerciseGraph createBaselineExerciseGraph() {
  final Map<Exercise, Set<Exercise>> dag = {
    // Pushing
    standardPushup: {feetElevatedPushup},
    feetElevatedPushup: {chairDip},
    chairDip: <Exercise>{},

    // Pulling
    doorframeRow: {towelRow},
    towelRow: {standardPullup},
    standardPullup: <Exercise>{},

    // Bend & Lift
    hipHinge: {goodMorning},
    goodMorning: {singleLegDeadlift},
    singleLegDeadlift: <Exercise>{},

    // Single Leg
    airSquat: {reverseLunge},
    reverseLunge: {bulgarianSplitSquat},
    bulgarianSplitSquat: <Exercise>{},

    // Rotation
    deadBug: {sidePlank},
    sidePlank: {bandedPallofPress},
    bandedPallofPress: <Exercise>{},
  };

  return ExerciseGraph(dag);
}

/// Global instance of the baseline exercise graph.
final ExerciseGraph baselineExerciseGraph = createBaselineExerciseGraph();

/// Quick lookup helper by ID for baseline exercises.
Exercise? findBaselineExercise(String id) {
  for (final exercise in baselineExercises) {
    if (exercise.id == id) return exercise;
  }
  return null;
}
