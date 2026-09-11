import 'figure_pose.dart';

/// Hand-authored pose sequences for the exercises with no usable match in
/// the bryllim/workout-guide illustration set (see
/// `local-notes/architecture/exercise_illustration_rig.md` for why each of
/// these needed a custom pose rather than a sourced illustration, and for
/// the angle/anchor conventions used below).
///
/// Organized by movement pattern, matching `expanded_catalog.dart`'s own
/// section layout. Each pose's `cueRef` cites the `defaultCues` index (from
/// that same file) it depicts.
const Map<String, List<FigurePose>> customPoseLibrary = {
  // ============================================================================
  // PUSHING
  // ============================================================================

  // One-Arm Push-up -- the rig is a side-profile silhouette, so it can't
  // geometrically distinguish "one arm working" from "two arms working"
  // the way a front view could (the rig only ever draws one visible arm
  // per the mirrored-limb convention, same as a normal push-up would).
  // The FORM CUES text carries the "single working hand" detail this
  // illustration can't.
  'one_arm_pushup': [
    FigurePose(
      anchor: FigureAnchor.lyingProne,
      cueRef: 'cue[0]', // tripod stance, single hand centered under sternum
    ),
    FigurePose(
      anchor: FigureAnchor.lyingProne,
      shoulderFlexion: 35,
      elbowFlexion: 80,
      cueRef: 'cue[1]', // brace core, minimal rotation during descent
    ),
  ],

  // Banded Resistance Push-up -- same plank motion as a standard push-up;
  // the band itself isn't drawn (a prop-rendering scope this rig doesn't
  // cover), so the FORM CUES text carries that detail.
  'band_resisted_pushup': [
    FigurePose(
      anchor: FigureAnchor.lyingProne,
      cueRef: 'cue[0]', // band looped across back, top plank
    ),
    FigurePose(
      anchor: FigureAnchor.lyingProne,
      shoulderFlexion: 40,
      elbowFlexion: 85,
      cueRef: 'cue[1]', // 2-second resisted descent
    ),
  ],

  // ============================================================================
  // PULLING
  // ============================================================================

  // Archer Pull-up -- one arm pulls, the other slides straight across the
  // bar. This rig models a single fixed hand root (see FigureAnchor's
  // doc), not two independently anchored hands on a wide grip, so the
  // rear ("gliding") arm is an approximation: drawn straight from the
  // same shoulder point rather than from its own true bar position.
  'archer_pullup': [
    FigurePose(
      anchor: FigureAnchor.hangingFromBar,
      shoulderFlexion: 5,
      elbowFlexion: 5,
      cueRef: 'cue[0]', // wide overhand grip, hang
    ),
    FigurePose(
      anchor: FigureAnchor.hangingFromBar,
      shoulderFlexion: 55,
      elbowFlexion: 130,
      shoulderFlexionRear: 5,
      elbowFlexionRear: 5,
      cueRef: 'cue[1]', // pull toward one hand, other arm slides straight
    ),
  ],

  // Strict Bar Muscle-up -- the one 3-phase custom exercise: dead hang,
  // pulled to the bar, then transitioned into a supported dip lockout.
  'muscle_up': [
    FigurePose(
      anchor: FigureAnchor.hangingFromBar,
      shoulderFlexion: 5,
      elbowFlexion: 5,
      cueRef: 'cue[0]', // false/aggressive overhand grip, dead hang
    ),
    FigurePose(
      anchor: FigureAnchor.hangingFromBar,
      shoulderFlexion: 60,
      elbowFlexion: 145,
      cueRef: 'cue[1]', // pulled explosively toward lower sternum
    ),
    FigurePose(
      anchor: FigureAnchor.dipSupportOnBar,
      torsoLean: 10,
      shoulderFlexion: 15,
      elbowFlexion: 10,
      cueRef: 'cue[2]', // transitioned over the bar, straight-arm dip lockout
    ),
  ],

  // ============================================================================
  // BEND & LIFT
  // ============================================================================

  // Bodyweight Hip Hinge -- standing tall, then hips driven straight back
  // with a flat lumbar spine (the control case: pure torsoLean/hipFlexion,
  // no limb asymmetry, no equipment prop).
  'hip_hinge': [
    FigurePose(
      anchor: FigureAnchor.standing,
      kneeFlexion: 10,
      cueRef: 'cue[0]', // standing, soft knee bend
    ),
    FigurePose(
      anchor: FigureAnchor.standing,
      torsoLean: 65,
      // Legs stay close to vertical through a hinge -- the torso does
      // almost all the rotating, not the thighs -- so hipFlexion (which
      // rotates the thigh's own screen direction, independent of
      // torsoLean) stays small even though the real anatomical hip angle
      // opens up a lot as the torso leans away from the still-vertical legs.
      hipFlexion: 12,
      kneeFlexion: 15,
      shoulderFlexion: 55,
      cueRef: 'cue[1]', // hips driven back, flat lumbar hinge
    ),
  ],

  // Single-Leg Bodyweight RDL -- standing leg stays near-vertical (same
  // principle as the hip hinge above); the trailing leg extends backward
  // in roughly a straight line with the torso, which is what the rear-leg
  // override exists for.
  'single_leg_deadlift': [
    FigurePose(
      anchor: FigureAnchor.standing,
      kneeFlexion: 8,
      cueRef: 'cue[0]', // balance on single foot, micro-bent stance knee
    ),
    FigurePose(
      anchor: FigureAnchor.standing,
      torsoLean: 75,
      hipFlexion: 10,
      kneeFlexion: 8,
      shoulderFlexion: 45,
      // Trailing leg extends backward continuing the torso's own line --
      // roughly opposite the torso's lean direction, not forward like the
      // standing leg's small hipFlexion.
      hipFlexionRear: -75,
      kneeFlexionRear: 0,
      cueRef: 'cue[2]', // trailing leg extended back, torso parallel to deck
    ),
  ],

  // ============================================================================
  // ROTATION
  // ============================================================================

  // Floor Windshield Wipers -- a true lateral (coronal-plane) rotation,
  // which a side-profile silhouette can't depict directly (see side_plank's
  // note in the architecture doc for the same limitation elsewhere in this
  // rig). Approximated here as legs arcing from vertical toward horizontal,
  // which reads as "legs lowering" even though it doesn't capture the real
  // sideways direction -- the FORM CUES text carries that detail.
  'windshield_wipers': [
    FigurePose(
      anchor: FigureAnchor.lyingSupine,
      hipFlexion: 178,
      cueRef: 'cue[0]', // arms in T, legs extended straight up
    ),
    FigurePose(
      anchor: FigureAnchor.lyingSupine,
      hipFlexion: 95,
      cueRef: 'cue[1]', // legs lowered toward the floor to one side
    ),
  ],
};
