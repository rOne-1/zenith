import 'package:sbee/sbee.dart';

/// Comprehensive baseline exercise catalog for the Zenith expedition engine.
///
/// Contains calibrated progressions across all 5 ACE IFT movement patterns:
/// - Pushing: Standard Push-up -> Feet-Elevated Push-up -> Bench / Chair Dip
/// - Pulling: Doorframe Row -> Towel Row -> Standard Pull-up
/// - Bend & Lift: Bodyweight Hip Hinge -> Prisoner Good Morning -> Single-Leg Deadlift
/// - Single Leg: Air Squat -> Reverse Lunge -> Bulgarian Split Squat
/// - Rotation: Dead Bug -> Side Plank -> Banded Anti-Rotation Hold
///
/// Every movement pattern includes a Tier 1 bodyweight-accessible baseline
/// so that minimally-equipped users never fail postural balance safety checks.

// PUSHING PROGRESSION
const standardPushup = Exercise(
  id: 'standard_pushup',
  name: 'Standard Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Maintain a rigid plank from heels to crown.',
    'Tuck elbows to roughly 45 degrees relative to ribs.',
    'Descend until chest reaches one fist-distance from deck.',
  ],
  correctiveCues: {
    'flared_elbows': 'Draw elbows inward toward torso.',
    'lumbar_sag': 'Engage glutes and brace transverse abdominis.',
  },
);

const feetElevatedPushup = Exercise(
  id: 'feet_elevated_pushup',
  name: 'Feet-Elevated Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Elevate toes on stable bench, chair, or curb.',
    'Keep neck neutral with gaze down.',
    'Drive through full palm including base of index finger.',
  ],
  correctiveCues: {'lumbar_hyperextension': 'Maintain posterior pelvic tilt.'},
);

const chairDip = Exercise(
  id: 'chair_dip',
  name: 'Bench / Chair Dip',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Grip bench edge with palms down and knuckles forward.',
    'Lower hips close to bench until upper arms reach parallel.',
    'Drive through palms to full lockout without shrugging shoulders.',
  ],
  correctiveCues: {
    'shoulder_impingement':
        'Depress scapulae and do not exceed 90-degree elbow flexion.',
  },
);

// PULLING PROGRESSION
const doorframeRow = Exercise(
  id: 'doorframe_row',
  name: 'Doorframe Bodyweight Row',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Grip doorframe securely with feet braced near threshold.',
    'Retract scapulae before initiating elbow pull.',
    'Control eccentric return with smooth 2-second tempo.',
  ],
  correctiveCues: {
    'cervical_reach': 'Keep chin tucked and eyes focused on anchor.',
    'scapular_winging':
        'Pinch lower shoulder blades together at peak contraction.',
  },
);

const towelRow = Exercise(
  id: 'towel_row',
  name: 'Towel Door-Anchor Row',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.towel},
  defaultCues: [
    'Knot towel securely behind closed door hinge.',
    'Grip towel ends firmly, leaning torso back at steady angle.',
    'Drive elbows back past ribcage.',
  ],
  correctiveCues: {
    'wrist_flexion': 'Keep wrists neutral and pull through elbows.',
  },
);

const standardPullup = Exercise(
  id: 'standard_pullup',
  name: 'Standard Pull-up',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Full pronated grip slightly wider than shoulder width.',
    'Engage lats by depressing shoulders before bending arms.',
    'Pull until clavicle or chin clears bar plane.',
  ],
  correctiveCues: {
    'kipping': 'Cross feet, squeeze glutes, and perform strict reps.',
  },
);

// BEND & LIFT PROGRESSION
const hipHinge = Exercise(
  id: 'hip_hinge',
  name: 'Bodyweight Hip Hinge',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Stand feet shoulder-width apart with soft knee bend.',
    'Drive pelvis straight back as if closing door with hips.',
    'Maintain flat lumbar spine throughout excursion.',
  ],
  correctiveCues: {
    'squatting': 'Keep shins near vertical and prioritize hip displacement.',
  },
);

const goodMorning = Exercise(
  id: 'good_morning',
  name: 'Prisoner Good Morning',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Place fingertips lightly behind head, elbows flaring wide.',
    'Hinge forward from hips until torso approaches 45 to 60 degrees.',
    'Feel active hamstring tension, then fire glutes to stand tall.',
  ],
  correctiveCues: {'neck_pull': 'Avoid pulling head forward with hands.'},
);

const singleLegDeadlift = Exercise(
  id: 'single_leg_deadlift',
  name: 'Single-Leg Bodyweight RDL',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Balance on single working foot, micro-bending stance knee.',
    'Extend trailing leg back in straight line with torso.',
    'Hinge until torso is parallel to deck, hips square.',
  ],
  correctiveCues: {
    'hip_rotation':
        'Point trailing toe straight toward deck to keep pelvis level.',
  },
);

// SINGLE LEG PROGRESSION
const airSquat = Exercise(
  id: 'air_squat',
  name: 'Bodyweight Air Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Stance shoulder-width with toes slightly turned out.',
    'Initiate descent with simultaneous knee and hip flexion.',
    'Descend until thighs are at least parallel to floor.',
  ],
  correctiveCues: {
    'knee_valgus': 'Actively drive knees outward tracking in line with toes.',
    'heel_rise': 'Distribute weight evenly across tripod of foot.',
  },
);

const reverseLunge = Exercise(
  id: 'reverse_lunge',
  name: 'Alternating Reverse Lunge',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Step back into deep stride, dropping back knee toward floor.',
    'Keep lead shin vertical and torso upright.',
    'Drive through front heel to return to standing position.',
  ],
  correctiveCues: {
    'torso_lean': 'Brace core to prevent excessive forward trunk lean.',
  },
);

const bulgarianSplitSquat = Exercise(
  id: 'bulgarian_split_squat',
  name: 'Bulgarian Split Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Rest top of rear foot on bench or elevated edge.',
    'Lower under control until front thigh reaches parallel.',
    'Maintain forward shin angle and press firmly through front mid-foot.',
  ],
  correctiveCues: {
    'shallow_depth':
        'Adjust front stance forward if rear knee hits deck prematurely.',
  },
);

// ROTATION & CORE PROGRESSION
const deadBug = Exercise(
  id: 'dead_bug',
  name: 'Supine Dead Bug',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Lie on back with knees at 90 degrees and arms extended ceiling-ward.',
    'Press lumbar spine flat into deck with no gap.',
    'Extend opposite arm and leg simultaneously while maintaining flat back.',
  ],
  correctiveCues: {
    'lumbar_arch':
        'Exhale sharply and anchor ribcage down before extending limbs.',
  },
);

const sidePlank = Exercise(
  id: 'side_plank',
  name: 'Forearm Side Plank',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Elbow stacked directly beneath shoulder, feet stacked or staggered.',
    'Lift hips to form unbroken straight diagonal from crown to ankles.',
    'Hold static contraction breathing rhythmically into abdomen.',
  ],
  correctiveCues: {'hip_drop': 'Elevate bottom oblique away from the floor.'},
);

const bandedPallofPress = Exercise(
  id: 'banded_pallof_press',
  name: 'Banded Anti-Rotation Pallof Press',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.bands},
  defaultCues: [
    'Anchor band at chest height, stand sideways to anchor with tension.',
    'Hold band handle at sternum, feet athletic width.',
    'Press hands straight out resisting rotational pull of band.',
  ],
  correctiveCues: {
    'torso_twisting':
        'Keep shoulders and hips squared forward throughout press.',
  },
);

/// Complete list of all baseline exercises.
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

/// Compiled acyclic Directed Acyclic Graph (DAG) for Zenith.
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

/// Global lazy instance of the baseline exercise graph.
final ExerciseGraph baselineExerciseGraph = createBaselineExerciseGraph();

/// Quick lookup helper by ID.
Exercise? findBaselineExercise(String id) {
  for (final exercise in baselineExercises) {
    if (exercise.id == id) return exercise;
  }
  return null;
}
