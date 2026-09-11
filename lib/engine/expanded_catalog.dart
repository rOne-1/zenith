import 'package:sbee/sbee.dart';

/// Comprehensive 31-exercise progression DAG spanning Tiers 1 through 6
/// across all 5 ACE IFT movement patterns.
///
/// **Metaphor**: Tokyo / Osaka Metro Transit Map
/// - Pushing: Ginza Orange Line (#FFAE34)
/// - Pulling: Tozai Teal Line (#2EE6D6)
/// - Bend & Lift: Marunouchi Coral Line (#FF493A)
/// - Single Leg: Chiyoda Green Line (#4B8E62)
/// - Rotation: Hanzomon Purple Line (#D154EC)

// ============================================================================
// 1. PUSHING LINE (8 Exercises, T1 - T6)
// ============================================================================

const wallPushup = Exercise(
  id: 'wall_pushup',
  name: 'Wall Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Stand an arm\'s length from the wall. Place your palms flat at shoulder height.',
    'Bend your elbows to slowly lower your chest toward the wall.',
    'Push back through your palms until your arms are straight again.',
  ],
  correctiveCues: {
    'shrugging': 'Keep your shoulders down, away from your ears.',
  },
);

const kneePushup = Exercise(
  id: 'knee_pushup',
  name: 'Incline Knee Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Rest your knees on the floor or a mat, keeping your body in a straight line from knees to head.',
    'Bend your elbows close to your body and lower your chest toward the floor.',
    'Push back up through your palms, keeping your stomach tight.',
  ],
  correctiveCues: {
    'hip_flexion':
        'Keep your hips in line with your shoulders and knees, not sagging or piked up.',
  },
);

const standardPushup = Exercise(
  id: 'standard_pushup',
  name: 'Standard Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Keep your body in one straight line from head to heels.',
    'Keep your elbows close to your sides as you lower down.',
    'Lower until your chest is a fist\'s width from the floor.',
  ],
  correctiveCues: {
    'flared_elbows':
        'Keep your elbows closer to your body, not pointing out to the sides.',
    'lumbar_sag':
        'Squeeze your butt and tighten your stomach so your hips don\'t sag.',
  },
);

const feetElevatedPushup = Exercise(
  id: 'feet_elevated_pushup',
  name: 'Feet-Elevated Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Rest your toes on a sturdy bench, chair, or step.',
    'Keep your neck relaxed and look down at the floor.',
    'Push evenly through your whole hand as you push up.',
  ],
  correctiveCues: {
    'lumbar_hyperextension':
        'Tuck your hips slightly so your lower back doesn\'t arch.',
  },
);

const chairDip = Exercise(
  id: 'chair_dip',
  name: 'Bench / Chair Dip',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Grip the edge of the bench with your fingers pointing forward.',
    'Lower your hips down until your upper arms are level with the floor.',
    'Push back up until your arms are straight, without shrugging your shoulders up.',
  ],
  correctiveCues: {
    'shoulder_impingement':
        'Keep your shoulders down and don\'t bend your elbows past a right angle.',
  },
);

const bandResistedPushup = Exercise(
  id: 'band_resisted_pushup',
  name: 'Banded Resistance Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.bands},
  defaultCues: [
    'Loop the band across your upper back and hold the ends under your palms.',
    'Lower yourself slowly, taking about 2 seconds, fighting the band\'s pull.',
    'Push all the way back up to straight arms against the band.',
  ],
  correctiveCues: {
    'incomplete_lockout':
        'Push all the way until your arms are fully straight.',
  },
);

const archerPushup = Exercise(
  id: 'archer_pushup',
  name: 'Archer Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 5,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Place your hands wide apart, fingers pointing slightly outward.',
    'Shift your weight onto one arm and keep the other arm straight out to the side.',
    'Push back up mainly with the working arm, while the other arm slides along the floor.',
  ],
  correctiveCues: {
    'weight_leak':
        'Keep the other arm straight — don\'t let it bend and help you push.',
  },
);

const oneArmPushup = Exercise(
  id: 'one_arm_pushup',
  name: 'One-Arm Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 6,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Stand your feet wide apart for balance, with one hand centered under your chest.',
    'Tighten your core and try not to twist your body as you lower down.',
    'Push back up to a straight arm, keeping your hips level.',
  ],
  correctiveCues: {
    'excessive_rotation':
        'Widen your feet and tighten your side muscles to stop your body from twisting.',
  },
);

// ============================================================================
// 2. PULLING LINE (7 Exercises, T1 - T6)
// ============================================================================

const doorframeRow = Exercise(
  id: 'doorframe_row',
  name: 'Doorframe Bodyweight Row',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Hold onto the doorframe firmly with your feet braced near the bottom of the door.',
    'Squeeze your shoulder blades together before you start pulling.',
    'Lower back down slowly, taking about 2 seconds.',
  ],
  correctiveCues: {
    'cervical_reach':
        'Keep your chin tucked and look at your hands, not up or forward.',
  },
);

const towelRow = Exercise(
  id: 'towel_row',
  name: 'Towel Door-Anchor Row',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.towel},
  defaultCues: [
    'Tie the towel tightly around the hinge side of a closed door.',
    'Hold both ends of the towel and lean back, keeping your body straight.',
    'Pull your elbows back past your ribs.',
  ],
  correctiveCues: {
    'wrist_flexion':
        'Keep your wrists straight and pull with your elbows, not your hands.',
  },
);

const invertedRow = Exercise(
  id: 'inverted_row',
  name: 'Horizontal Inverted Row',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Hang under a bar at waist height, heels on the floor and body straight.',
    'Pull your chest up to the bar by squeezing your shoulder blades together.',
    'Pause briefly at the top, then lower back down slowly.',
  ],
  correctiveCues: {
    'hip_sag': 'Squeeze your butt to keep your body in a straight line.',
  },
);

const standardPullup = Exercise(
  id: 'standard_pullup',
  name: 'Standard Pull-up',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Grip the bar with palms facing away, hands slightly wider than your shoulders.',
    'Pull your shoulders down before you start bending your arms.',
    'Pull yourself up until your chin clears the bar.',
  ],
  correctiveCues: {
    'kipping':
        'Stop swinging your legs — cross your feet and pull with your arms only.',
  },
);

const lSitPullup = Exercise(
  id: 'l_sit_pullup',
  name: 'L-Sit Strict Pull-up',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Hold your legs straight out in front of you the whole time.',
    'Pull your shoulders down first, keeping your hips bent at a right angle.',
    'Pull up until your chin clears the bar, without dropping your legs.',
  ],
  correctiveCues: {
    'drooping_legs':
        'Tighten your hips and point your toes to keep your legs up.',
  },
);

const archerPullup = Exercise(
  id: 'archer_pullup',
  name: 'Archer Pull-up',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 5,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Grip the bar with a wide overhand grip.',
    'Pull yourself up toward one hand while the other arm stays straight and slides along the bar.',
    'Lower down slowly, then switch sides or repeat.',
  ],
  correctiveCues: {
    'bent_glide_arm': 'Keep the sliding arm completely straight.',
  },
);

const muscleUp = Exercise(
  id: 'muscle_up',
  name: 'Strict Bar Muscle-up',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 6,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Grip the bar with your wrists rolled slightly over the top.',
    'Pull yourself up fast and high, toward your lower chest.',
    'Roll your shoulders over the bar, then push up until your arms are straight.',
  ],
  correctiveCues: {
    'chicken_wing':
        'Bring both elbows over the bar at the same time, not one at a time.',
  },
);

// ============================================================================
// 3. BEND & LIFT LINE (5 Exercises, T1 - T5)
// ============================================================================

const hipHinge = Exercise(
  id: 'hip_hinge',
  name: 'Bodyweight Hip Hinge',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Stand with feet shoulder-width apart, knees slightly bent.',
    'Push your hips straight back, like closing a door with your butt.',
    'Keep your back flat and straight the whole time.',
  ],
  correctiveCues: {
    'squatting':
        'Keep your shins mostly upright — this move comes from your hips, not your knees.',
  },
);

const goodMorning = Exercise(
  id: 'good_morning',
  name: 'Prisoner Good Morning',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Rest your fingertips lightly behind your head, elbows out wide.',
    'Bend forward from your hips until your upper body is about halfway down.',
    'Feel your hamstrings stretch, then squeeze your butt to stand back up.',
  ],
  correctiveCues: {
    'neck_pull': 'Don\'t pull your head forward with your hands.',
  },
);

const singleLegDeadlift = Exercise(
  id: 'single_leg_deadlift',
  name: 'Single-Leg Bodyweight RDL',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Balance on one foot with a slight bend in that knee.',
    'Lift your other leg straight back behind you as your body tips forward.',
    'Keep bending forward until your body is close to flat, facing the floor.',
  ],
  correctiveCues: {
    'hip_rotation':
        'Point your back toes at the floor to keep your hips level.',
  },
);

const towelHamstringCurl = Exercise(
  id: 'towel_hamstring_curl',
  name: 'Floor Towel Hamstring Curl',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.towel},
  defaultCues: [
    'Lie on your back on a smooth floor with your heels resting on a folded towel.',
    'Lift your hips up into a bridge, squeezing your butt.',
    'Slide your heels out slowly, then pull them back in toward your butt.',
  ],
  correctiveCues: {
    'dropping_hips':
        'Keep your hips lifted up the whole time — don\'t let them drop.',
  },
);

const nordicCurl = Exercise(
  id: 'nordic_curl',
  name: 'Assisted Nordic Hamstring Curl',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 5,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Hook your heels under something sturdy, like a couch, or have a partner hold them.',
    'Keep your body in one straight line from knees to head.',
    'Lower your body forward as slowly as you can, using your hamstrings to control it.',
  ],
  correctiveCues: {
    'broken_hip':
        'Don\'t bend at your hips — keep your body straight the whole way down.',
  },
);

// ============================================================================
// 4. SINGLE LEG LINE (6 Exercises, T1 - T6)
// ============================================================================

const airSquat = Exercise(
  id: 'air_squat',
  name: 'Bodyweight Air Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Stand with feet shoulder-width apart, toes turned out slightly.',
    'Bend your knees and hips at the same time as you lower down.',
    'Lower until your thighs are at least level with the floor.',
  ],
  correctiveCues: {
    'knee_valgus': 'Push your knees out so they stay in line with your toes.',
  },
);

const reverseLunge = Exercise(
  id: 'reverse_lunge',
  name: 'Alternating Reverse Lunge',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Step one foot back into a long stride, lowering your back knee toward the floor.',
    'Keep your front shin upright and your chest tall.',
    'Push through your front heel to stand back up.',
  ],
  correctiveCues: {
    'torso_lean': 'Tighten your stomach so you don\'t lean too far forward.',
  },
);

const bulgarianSplitSquat = Exercise(
  id: 'bulgarian_split_squat',
  name: 'Bulgarian Split Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Rest the top of your back foot on a bench or raised surface.',
    'Lower yourself slowly until your front thigh is level with the floor.',
    'Push through the middle of your front foot to stand back up.',
  ],
  correctiveCues: {
    'shallow_depth':
        'Step your front foot further forward if your back knee touches the floor too soon.',
  },
);

const skaterSquat = Exercise(
  id: 'skater_squat',
  name: 'Skater Single-Leg Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Stand on one leg with your other knee bent behind you.',
    'Reach your arms forward for balance as you bend your standing knee.',
    'Gently tap your back knee to the floor without putting weight on it.',
  ],
  correctiveCues: {
    'bouncing':
        'Lower down slowly over about 3 seconds — don\'t drop or bounce.',
  },
);

const assistedPistolSquat = Exercise(
  id: 'assisted_pistol_squat',
  name: 'Assisted Pistol Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 5,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Sit down onto a bench on one leg, with your other leg held straight out in front.',
    'Push through your heel to stand back up without swinging your body.',
    'Lower back down to the bench slowly and under control.',
  ],
  correctiveCues: {
    'knee_cave':
        'Keep your knee pointing the same way as your toes — don\'t let it cave inward.',
  },
);

const fullPistolSquat = Exercise(
  id: 'full_pistol_squat',
  name: 'Full Pistol Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 6,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Squat all the way down on one leg, with the other leg held straight out in front.',
    'Lower until the back of your thigh touches your calf, balancing on the middle of your foot.',
    'Push through your whole foot to stand all the way back up.',
  ],
  correctiveCues: {
    'heel_lift':
        'If your heel keeps lifting off the floor, try squatting with a small block under your heel.',
  },
);

// ============================================================================
// 5. ROTATION LINE (5 Exercises, T1 - T5)
// ============================================================================

const deadBug = Exercise(
  id: 'dead_bug',
  name: 'Supine Dead Bug',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Lie on your back with your knees bent at a right angle and arms reaching straight up.',
    'Press your lower back flat against the floor, with no gap underneath.',
    'Slowly straighten one arm and the opposite leg at the same time, keeping your back flat.',
  ],
  correctiveCues: {
    'lumbar_arch':
        'Breathe out and pull your ribs down before you move your arm and leg.',
  },
);

const sidePlank = Exercise(
  id: 'side_plank',
  name: 'Forearm Side Plank',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Place your elbow directly under your shoulder, feet stacked or staggered.',
    'Lift your hips so your body forms one straight line from head to ankles.',
    'Hold this position, breathing normally.',
  ],
  correctiveCues: {
    'hip_drop': 'Lift your hips higher so they don\'t sag toward the floor.',
  },
);

const bandedPallofPress = Exercise(
  id: 'banded_pallof_press',
  name: 'Banded Anti-Rotation Pallof Press',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 3,
  equipmentRequirements: {Equipment.bands},
  defaultCues: [
    'Attach the band at chest height and stand sideways to it, so there\'s tension.',
    'Hold the band at your chest with your feet about shoulder-width apart.',
    'Push the band straight out in front of you, resisting its pull to the side.',
  ],
  correctiveCues: {
    'torso_twisting':
        'Keep your shoulders and hips facing forward — don\'t let the band twist you.',
  },
);

const windshieldWipers = Exercise(
  id: 'windshield_wipers',
  name: 'Floor Windshield Wipers',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Lie on your back with your arms out to the sides and legs straight up in the air.',
    'Lower your legs to one side, keeping your shoulders flat on the floor.',
    'Use your side muscles to bring your legs back to the center, then lower them to the other side.',
  ],
  correctiveCues: {
    'shoulder_lift':
        'Stop lowering your legs if your opposite shoulder starts lifting off the floor.',
  },
);

const dragonFlag = Exercise(
  id: 'dragon_flag',
  name: 'Dragon Flag Core Extension',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 5,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Lie on a bench and hold the top edges firmly behind your head.',
    'Lift your whole body up so only your shoulders touch the bench, keeping it straight.',
    'Lower your body back down slowly, keeping it straight and only bending at your shoulders.',
  ],
  correctiveCues: {
    'hip_bend': 'Squeeze your butt and stomach tight so your hips don\'t bend.',
  },
);

// ============================================================================
// COMPLETE CATALOG LIST & JAPANESE METRO METADATA
// ============================================================================

/// All 31 exercises in the expanded catalog.
const List<Exercise> expandedExercises = [
  // Pushing (8)
  wallPushup,
  kneePushup,
  standardPushup,
  feetElevatedPushup,
  chairDip,
  bandResistedPushup,
  archerPushup,
  oneArmPushup,

  // Pulling (7)
  doorframeRow,
  towelRow,
  invertedRow,
  standardPullup,
  lSitPullup,
  archerPullup,
  muscleUp,

  // Bend & Lift (5)
  hipHinge,
  goodMorning,
  singleLegDeadlift,
  towelHamstringCurl,
  nordicCurl,

  // Single Leg (6)
  airSquat,
  reverseLunge,
  bulgarianSplitSquat,
  skaterSquat,
  assistedPistolSquat,
  fullPistolSquat,

  // Rotation (5)
  deadBug,
  sidePlank,
  bandedPallofPress,
  windshieldWipers,
  dragonFlag,
];

/// Metro transit station metadata for each exercise.
class MetroStationMeta {
  final String stationCode;
  final String lineName;
  final int defaultLoadScore; // 1-5
  final int defaultPositionScore; // 1-5
  final int defaultRomScore; // 1-5
  final int defaultElevationScore; // 1-5
  final int defaultTempoScore; // 1-5

  const MetroStationMeta({
    required this.stationCode,
    required this.lineName,
    required this.defaultLoadScore,
    required this.defaultPositionScore,
    required this.defaultRomScore,
    required this.defaultElevationScore,
    required this.defaultTempoScore,
  });

  static const Map<String, MetroStationMeta> registry = {
    // Pushing
    'wall_pushup': MetroStationMeta(
      stationCode: 'P01',
      lineName: 'Push Line',
      defaultLoadScore: 1,
      defaultPositionScore: 1,
      defaultRomScore: 2,
      defaultElevationScore: 1,
      defaultTempoScore: 2,
    ),
    'knee_pushup': MetroStationMeta(
      stationCode: 'P02',
      lineName: 'Push Line',
      defaultLoadScore: 2,
      defaultPositionScore: 2,
      defaultRomScore: 3,
      defaultElevationScore: 2,
      defaultTempoScore: 2,
    ),
    'standard_pushup': MetroStationMeta(
      stationCode: 'P03',
      lineName: 'Push Line',
      defaultLoadScore: 3,
      defaultPositionScore: 3,
      defaultRomScore: 4,
      defaultElevationScore: 3,
      defaultTempoScore: 3,
    ),
    'feet_elevated_pushup': MetroStationMeta(
      stationCode: 'P04',
      lineName: 'Push Line',
      defaultLoadScore: 3,
      defaultPositionScore: 4,
      defaultRomScore: 4,
      defaultElevationScore: 4,
      defaultTempoScore: 3,
    ),
    'chair_dip': MetroStationMeta(
      stationCode: 'P05',
      lineName: 'Push Line',
      defaultLoadScore: 4,
      defaultPositionScore: 3,
      defaultRomScore: 4,
      defaultElevationScore: 3,
      defaultTempoScore: 3,
    ),
    'band_resisted_pushup': MetroStationMeta(
      stationCode: 'P06',
      lineName: 'Push Line',
      defaultLoadScore: 4,
      defaultPositionScore: 4,
      defaultRomScore: 4,
      defaultElevationScore: 3,
      defaultTempoScore: 4,
    ),
    'archer_pushup': MetroStationMeta(
      stationCode: 'P07',
      lineName: 'Push Line',
      defaultLoadScore: 5,
      defaultPositionScore: 4,
      defaultRomScore: 5,
      defaultElevationScore: 3,
      defaultTempoScore: 4,
    ),
    'one_arm_pushup': MetroStationMeta(
      stationCode: 'P08',
      lineName: 'Push Line',
      defaultLoadScore: 5,
      defaultPositionScore: 5,
      defaultRomScore: 5,
      defaultElevationScore: 4,
      defaultTempoScore: 5,
    ),

    // Pulling
    'doorframe_row': MetroStationMeta(
      stationCode: 'L01',
      lineName: 'Pull Line',
      defaultLoadScore: 1,
      defaultPositionScore: 1,
      defaultRomScore: 2,
      defaultElevationScore: 1,
      defaultTempoScore: 2,
    ),
    'towel_row': MetroStationMeta(
      stationCode: 'L02',
      lineName: 'Pull Line',
      defaultLoadScore: 2,
      defaultPositionScore: 2,
      defaultRomScore: 3,
      defaultElevationScore: 2,
      defaultTempoScore: 3,
    ),
    'inverted_row': MetroStationMeta(
      stationCode: 'L03',
      lineName: 'Pull Line',
      defaultLoadScore: 3,
      defaultPositionScore: 3,
      defaultRomScore: 4,
      defaultElevationScore: 3,
      defaultTempoScore: 3,
    ),
    'standard_pullup': MetroStationMeta(
      stationCode: 'L04',
      lineName: 'Pull Line',
      defaultLoadScore: 4,
      defaultPositionScore: 4,
      defaultRomScore: 4,
      defaultElevationScore: 4,
      defaultTempoScore: 3,
    ),
    'l_sit_pullup': MetroStationMeta(
      stationCode: 'L05',
      lineName: 'Pull Line',
      defaultLoadScore: 4,
      defaultPositionScore: 5,
      defaultRomScore: 4,
      defaultElevationScore: 4,
      defaultTempoScore: 4,
    ),
    'archer_pullup': MetroStationMeta(
      stationCode: 'L06',
      lineName: 'Pull Line',
      defaultLoadScore: 5,
      defaultPositionScore: 5,
      defaultRomScore: 5,
      defaultElevationScore: 4,
      defaultTempoScore: 4,
    ),
    'muscle_up': MetroStationMeta(
      stationCode: 'L07',
      lineName: 'Pull Line',
      defaultLoadScore: 5,
      defaultPositionScore: 5,
      defaultRomScore: 5,
      defaultElevationScore: 5,
      defaultTempoScore: 5,
    ),

    // Bend & Lift
    'hip_hinge': MetroStationMeta(
      stationCode: 'B01',
      lineName: 'Bend Line',
      defaultLoadScore: 1,
      defaultPositionScore: 1,
      defaultRomScore: 2,
      defaultElevationScore: 1,
      defaultTempoScore: 2,
    ),
    'good_morning': MetroStationMeta(
      stationCode: 'B02',
      lineName: 'Bend Line',
      defaultLoadScore: 2,
      defaultPositionScore: 2,
      defaultRomScore: 3,
      defaultElevationScore: 2,
      defaultTempoScore: 3,
    ),
    'single_leg_deadlift': MetroStationMeta(
      stationCode: 'B03',
      lineName: 'Bend Line',
      defaultLoadScore: 3,
      defaultPositionScore: 4,
      defaultRomScore: 4,
      defaultElevationScore: 2,
      defaultTempoScore: 3,
    ),
    'towel_hamstring_curl': MetroStationMeta(
      stationCode: 'B04',
      lineName: 'Bend Line',
      defaultLoadScore: 4,
      defaultPositionScore: 4,
      defaultRomScore: 4,
      defaultElevationScore: 1,
      defaultTempoScore: 4,
    ),
    'nordic_curl': MetroStationMeta(
      stationCode: 'B05',
      lineName: 'Bend Line',
      defaultLoadScore: 5,
      defaultPositionScore: 5,
      defaultRomScore: 5,
      defaultElevationScore: 1,
      defaultTempoScore: 5,
    ),

    // Single Leg
    'air_squat': MetroStationMeta(
      stationCode: 'S01',
      lineName: 'Legs Line',
      defaultLoadScore: 1,
      defaultPositionScore: 1,
      defaultRomScore: 3,
      defaultElevationScore: 1,
      defaultTempoScore: 2,
    ),
    'reverse_lunge': MetroStationMeta(
      stationCode: 'S02',
      lineName: 'Legs Line',
      defaultLoadScore: 2,
      defaultPositionScore: 2,
      defaultRomScore: 3,
      defaultElevationScore: 2,
      defaultTempoScore: 3,
    ),
    'bulgarian_split_squat': MetroStationMeta(
      stationCode: 'S03',
      lineName: 'Legs Line',
      defaultLoadScore: 3,
      defaultPositionScore: 3,
      defaultRomScore: 4,
      defaultElevationScore: 3,
      defaultTempoScore: 3,
    ),
    'skater_squat': MetroStationMeta(
      stationCode: 'S04',
      lineName: 'Legs Line',
      defaultLoadScore: 4,
      defaultPositionScore: 4,
      defaultRomScore: 4,
      defaultElevationScore: 2,
      defaultTempoScore: 4,
    ),
    'assisted_pistol_squat': MetroStationMeta(
      stationCode: 'S05',
      lineName: 'Legs Line',
      defaultLoadScore: 4,
      defaultPositionScore: 4,
      defaultRomScore: 5,
      defaultElevationScore: 3,
      defaultTempoScore: 4,
    ),
    'full_pistol_squat': MetroStationMeta(
      stationCode: 'S06',
      lineName: 'Legs Line',
      defaultLoadScore: 5,
      defaultPositionScore: 5,
      defaultRomScore: 5,
      defaultElevationScore: 2,
      defaultTempoScore: 5,
    ),

    // Rotation
    'dead_bug': MetroStationMeta(
      stationCode: 'R01',
      lineName: 'Rotation Line',
      defaultLoadScore: 1,
      defaultPositionScore: 1,
      defaultRomScore: 2,
      defaultElevationScore: 1,
      defaultTempoScore: 2,
    ),
    'side_plank': MetroStationMeta(
      stationCode: 'R02',
      lineName: 'Rotation Line',
      defaultLoadScore: 2,
      defaultPositionScore: 2,
      defaultRomScore: 2,
      defaultElevationScore: 2,
      defaultTempoScore: 3,
    ),
    'banded_pallof_press': MetroStationMeta(
      stationCode: 'R03',
      lineName: 'Rotation Line',
      defaultLoadScore: 3,
      defaultPositionScore: 3,
      defaultRomScore: 3,
      defaultElevationScore: 3,
      defaultTempoScore: 3,
    ),
    'windshield_wipers': MetroStationMeta(
      stationCode: 'R04',
      lineName: 'Rotation Line',
      defaultLoadScore: 4,
      defaultPositionScore: 4,
      defaultRomScore: 4,
      defaultElevationScore: 2,
      defaultTempoScore: 4,
    ),
    'dragon_flag': MetroStationMeta(
      stationCode: 'R05',
      lineName: 'Rotation Line',
      defaultLoadScore: 5,
      defaultPositionScore: 5,
      defaultRomScore: 5,
      defaultElevationScore: 4,
      defaultTempoScore: 5,
    ),
  };

  static MetroStationMeta forExercise(Exercise exercise) {
    return registry[exercise.id] ??
        MetroStationMeta(
          stationCode: exercise.id.substring(0, 3).toUpperCase(),
          lineName: exercise.movementPattern.name.toUpperCase(),
          defaultLoadScore: exercise.difficultyTier.clamp(1, 5),
          defaultPositionScore: exercise.difficultyTier.clamp(1, 5),
          defaultRomScore: 3,
          defaultElevationScore: 2,
          defaultTempoScore: 3,
        );
  }
}

/// Compiles the complete acyclic DAG for the expanded catalog.
ExerciseGraph createExpandedExerciseGraph() {
  final Map<Exercise, Set<Exercise>> dag = {
    // Pushing
    wallPushup: {kneePushup},
    kneePushup: {standardPushup},
    standardPushup: {feetElevatedPushup},
    feetElevatedPushup: {chairDip},
    chairDip: {bandResistedPushup},
    bandResistedPushup: {archerPushup},
    archerPushup: {oneArmPushup},
    oneArmPushup: <Exercise>{},

    // Pulling
    doorframeRow: {towelRow},
    towelRow: {invertedRow},
    invertedRow: {standardPullup},
    standardPullup: {lSitPullup},
    lSitPullup: {archerPullup},
    archerPullup: {muscleUp},
    muscleUp: <Exercise>{},

    // Bend & Lift
    hipHinge: {goodMorning},
    goodMorning: {singleLegDeadlift},
    singleLegDeadlift: {towelHamstringCurl},
    towelHamstringCurl: {nordicCurl},
    nordicCurl: <Exercise>{},

    // Single Leg
    airSquat: {reverseLunge},
    reverseLunge: {bulgarianSplitSquat},
    bulgarianSplitSquat: {skaterSquat},
    skaterSquat: {assistedPistolSquat},
    assistedPistolSquat: {fullPistolSquat},
    fullPistolSquat: <Exercise>{},

    // Rotation
    deadBug: {sidePlank},
    sidePlank: {bandedPallofPress},
    bandedPallofPress: {windshieldWipers},
    windshieldWipers: {dragonFlag},
    dragonFlag: <Exercise>{},
  };

  return ExerciseGraph(dag);
}

/// Global lazy instance of the expanded exercise graph.
final ExerciseGraph expandedExerciseGraph = createExpandedExerciseGraph();

/// Quick lookup helper for expanded exercises.
Exercise? findExpandedExercise(String id) {
  for (final ex in expandedExercises) {
    if (ex.id == id) return ex;
  }
  return null;
}
