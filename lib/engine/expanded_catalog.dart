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
    'Stand an arm-length from wall, palms flat at shoulder height.',
    'Bend elbows to lower chest toward wall under control.',
    'Press firmly through palms to return to standing plank.',
  ],
  correctiveCues: {'shrugging': 'Keep shoulders packed away from ears.'},
);

const kneePushup = Exercise(
  id: 'knee_pushup',
  name: 'Incline Knee Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 1,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Rest knees on floor or mat, hips extended in straight line with torso.',
    'Tuck elbows to 45 degrees, lowering chest toward deck.',
    'Drive through full palm, bracing abdominal wall.',
  ],
  correctiveCues: {
    'hip_flexion': 'Keep hips extended in line with shoulders and knees.',
  },
);

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

const bandResistedPushup = Exercise(
  id: 'band_resisted_pushup',
  name: 'Banded Resistance Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.bands},
  defaultCues: [
    'Loop band across upper back and anchor under palms.',
    'Descend with strict 2-second tempo resisting band elasticity.',
    'Lock out aggressively against peak band tension.',
  ],
  correctiveCues: {
    'incomplete_lockout': 'Press all the way into full scapular protraction.',
  },
);

const archerPushup = Exercise(
  id: 'archer_pushup',
  name: 'Archer Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 5,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Wide hand placement with fingers pointed slightly outward.',
    'Shift weight entirely to working side, extending trailing arm straight.',
    'Press working side up explosively while trailing arm glides.',
  ],
  correctiveCues: {'weight_leak': 'Do not bend the trailing arm.'},
);

const oneArmPushup = Exercise(
  id: 'one_arm_pushup',
  name: 'One-Arm Push-up',
  movementPattern: MovementPattern.pushing,
  difficultyTier: 6,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Feet wide for tripod stability, single working hand centered under sternum.',
    'Brace core and rotate shoulders minimally during descent.',
    'Drive through palm to lockout maintaining level hips.',
  ],
  correctiveCues: {
    'excessive_rotation': 'Widen foot stance and brace opposite oblique.',
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
    'Grip doorframe securely with feet braced near threshold.',
    'Retract scapulae before initiating elbow pull.',
    'Control eccentric return with smooth 2-second tempo.',
  ],
  correctiveCues: {
    'cervical_reach': 'Keep chin tucked and eyes focused on anchor.',
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

const invertedRow = Exercise(
  id: 'inverted_row',
  name: 'Horizontal Inverted Row',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 2,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Hang beneath waist-height bar, heels on floor and body rigid.',
    'Pull chest to bar by pinching shoulder blades together.',
    'Pause briefly at apex before lowering with control.',
  ],
  correctiveCues: {'hip_sag': 'Fire glutes to maintain straight plank line.'},
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

const lSitPullup = Exercise(
  id: 'l_sit_pullup',
  name: 'L-Sit Strict Pull-up',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Hold legs horizontal in static L-sit throughout pull.',
    'Initiate with scapular depression and maintain 90-degree hip angle.',
    'Clear chin over bar without dropping feet.',
  ],
  correctiveCues: {'drooping_legs': 'Engage hip flexors and point toes.'},
);

const archerPullup = Exercise(
  id: 'archer_pullup',
  name: 'Archer Pull-up',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 5,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Wide overhand grip on bar.',
    'Pull body toward one hand while sliding other arm straight across bar.',
    'Lower smoothly and alternate or complete reps per side.',
  ],
  correctiveCues: {'bent_glide_arm': 'Keep non-working arm fully extended.'},
);

const muscleUp = Exercise(
  id: 'muscle_up',
  name: 'Strict Bar Muscle-up',
  movementPattern: MovementPattern.pulling,
  difficultyTier: 6,
  equipmentRequirements: {Equipment.pullUpBar},
  defaultCues: [
    'Use false or aggressive overhand grip.',
    'Pull explosively toward lower sternum.',
    'Transition shoulders over bar and press out into straight-bar dip.',
  ],
  correctiveCues: {
    'chicken_wing': 'Drive both elbows over the bar simultaneously.',
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

const towelHamstringCurl = Exercise(
  id: 'towel_hamstring_curl',
  name: 'Floor Towel Hamstring Curl',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.towel},
  defaultCues: [
    'Lie supine on smooth floor with heels placed on folded towel.',
    'Elevate hips into bridge position, glutes fully engaged.',
    'Slide heels out under control, then curl back toward glutes.',
  ],
  correctiveCues: {
    'dropping_hips': 'Keep pelvis high and hips extended throughout curl.',
  },
);

const nordicCurl = Exercise(
  id: 'nordic_curl',
  name: 'Assisted Nordic Hamstring Curl',
  movementPattern: MovementPattern.bendAndLift,
  difficultyTier: 5,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Anchor heels securely beneath sturdy furniture or partner.',
    'Maintain rigid straight line from knees through hips to head.',
    'Fall forward as slowly as possible resisting with eccentric hamstring tension.',
  ],
  correctiveCues: {
    'broken_hip': 'Do not bend at waist; maintain rigid hip extension.',
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
    'Stance shoulder-width with toes slightly turned out.',
    'Initiate descent with simultaneous knee and hip flexion.',
    'Descend until thighs are at least parallel to floor.',
  ],
  correctiveCues: {
    'knee_valgus': 'Actively drive knees outward tracking in line with toes.',
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

const skaterSquat = Exercise(
  id: 'skater_squat',
  name: 'Skater Single-Leg Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Stand on working leg with trailing knee bent to 90 degrees.',
    'Reach arms forward for counter-balance as working knee flexes.',
    'Tap trailing knee softly to deck without resting weight.',
  ],
  correctiveCues: {
    'bouncing': 'Lower with 3-second eccentric control and zero impact.',
  },
);

const assistedPistolSquat = Exercise(
  id: 'assisted_pistol_squat',
  name: 'Assisted Pistol Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Sit down to bench on single working foot, opposite leg extended out.',
    'Drive through heel to stand tall without using momentum.',
    'Lower back to seat with complete deceleration control.',
  ],
  correctiveCues: {'knee_cave': 'Keep working knee tracking over second toe.'},
);

const fullPistolSquat = Exercise(
  id: 'full_pistol_squat',
  name: 'Full Pistol Squat',
  movementPattern: MovementPattern.singleLeg,
  difficultyTier: 6,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Single leg full-depth squat with non-working leg held straight in front.',
    'Descend until hamstring meets calf, maintaining balance on mid-foot.',
    'Drive up through heel and midfoot to full standing lockout.',
  ],
  correctiveCues: {
    'heel_lift': 'Improve ankle dorsiflexion or elevate heel on micro-plate.',
  },
);

// ============================================================================
// 5. ROTATION LINE (5 Exercises, T1 - T6)
// ============================================================================

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

const windshieldWipers = Exercise(
  id: 'windshield_wipers',
  name: 'Floor Windshield Wipers',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 4,
  equipmentRequirements: {Equipment.bodyweight},
  defaultCues: [
    'Lie on back, arms in T-formation, legs extended straight up.',
    'Lower legs toward floor to one side while keeping shoulders pinned.',
    'Engage obliques to return legs to center before rotating to opposite side.',
  ],
  correctiveCues: {
    'shoulder_lift':
        'Halt descent if opposite shoulder blade loses contact with deck.',
  },
);

const dragonFlag = Exercise(
  id: 'dragon_flag',
  name: 'Dragon Flag Core Extension',
  movementPattern: MovementPattern.rotation,
  difficultyTier: 6,
  equipmentRequirements: {Equipment.benchOrChair},
  defaultCues: [
    'Lie on bench gripping top edges firmly behind head.',
    'Lift entire body up on shoulder blades in rigid unbroken straight line.',
    'Lower body slowly toward bench pivoting solely at shoulder joint.',
  ],
  correctiveCues: {
    'hip_bend': 'Squeeze glutes and abdominal wall to prevent hip flexion.',
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
