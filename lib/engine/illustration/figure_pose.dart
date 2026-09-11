/// A closed set of body/prop orientations for [FigurePose]'s kinematic
/// chain. Each anchor pins one joint to a fixed reference point and fixes
/// which direction the chain is solved from that point -- see
/// `local-notes/architecture/exercise_illustration_rig.md` for the full
/// convention writeup (root point, solve direction, and a worked example
/// per anchor).
///
/// This is a closed enum, not a general inverse-kinematics system: the rig
/// exists to hand-author a fixed, small set of exercises, not to pose an
/// arbitrary figure, so every anchor here is added because a specific
/// exercise needs it (see the doc for which).
enum FigureAnchor {
  /// Root = hip, at a fixed height above the floor line. Chain solves
  /// upward (torso -> shoulder -> arm) and downward (thigh -> shin -> foot).
  standing,

  /// Root = shoulder, on the floor line, torso horizontal by default.
  /// Used for prone (face-down) positions, e.g. the top of a push-up.
  lyingProne,

  /// Root = hip, on the floor line, torso horizontal by default. Used for
  /// supine (face-up) positions.
  lyingSupine,

  /// Root = hands, pinned to a fixed bar prop near the top of the canvas.
  /// Chain solves downward (forearm -> upper arm -> shoulder -> torso ->
  /// hip -> leg). Body position relative to the fixed bar is what changes
  /// between poses sharing this anchor.
  hangingFromBar,

  /// Root = hands, same fixed bar position as [hangingFromBar], but the
  /// chain solves upward -- the torso rises above the hand-line into
  /// lockout. A discrete flip from [hangingFromBar], not a continuous
  /// angle, which is why it's a separate anchor rather than another field.
  dipSupportOnBar,
}

/// One hand-authored body position for an exercise illustration.
///
/// Bone-length ratios (torso/upper-arm/forearm/thigh/shin, as fractions of
/// a fixed figure-height constant) are anatomy, not authored content --
/// they live in the painter, not here. This class holds only what varies
/// per pose: the anchor and the joint angles.
///
/// All angles are in degrees. `0` means "straight" (no flexion) for every
/// joint field; sign/magnitude conventions are documented per-field below
/// and in the architecture doc.
class FigurePose {
  /// Which fixed reference point and solve direction this pose uses.
  final FigureAnchor anchor;

  /// Torso lean away from the anchor's neutral (upright/horizontal) axis.
  final double torsoLean;

  /// Thigh angle relative to the torso. `0` = thigh in line with torso.
  final double hipFlexion;

  /// Shin angle relative to the thigh. `0` = straight leg.
  final double kneeFlexion;

  /// Upper-arm angle relative to the torso. `0` = arm in line with torso.
  final double shoulderFlexion;

  /// Forearm angle relative to the upper arm. `0` = straight arm.
  final double elbowFlexion;

  /// Secondary-limb overrides for asymmetric/unilateral exercises (e.g. an
  /// archer push-up's straight trailing arm, a single-leg deadlift's
  /// trailing leg). `null` means "mirror the primary limb" -- rendered as
  /// one bilateral silhouette limb, the common case. Non-null means render
  /// a second, visually distinct limb at this angle instead.
  final double? hipFlexionRear;
  final double? kneeFlexionRear;
  final double? shoulderFlexionRear;
  final double? elbowFlexionRear;

  /// Which of the exercise's `defaultCues` entries this pose depicts, e.g.
  /// `"cue[1]"` -- keeps the mapping from SBEE's authored biomechanical
  /// text to this illustration auditable rather than guesswork. Not
  /// rendered to the user.
  final String cueRef;

  const FigurePose({
    required this.anchor,
    this.torsoLean = 0,
    this.hipFlexion = 0,
    this.kneeFlexion = 0,
    this.shoulderFlexion = 0,
    this.elbowFlexion = 0,
    this.hipFlexionRear,
    this.kneeFlexionRear,
    this.shoulderFlexionRear,
    this.elbowFlexionRear,
    required this.cueRef,
  });

  /// True if this pose has any non-null secondary-limb override, i.e. it
  /// depicts asymmetric/unilateral loading rather than a mirrored bilateral
  /// limb.
  bool get isAsymmetric =>
      hipFlexionRear != null ||
      kneeFlexionRear != null ||
      shoulderFlexionRear != null ||
      elbowFlexionRear != null;
}
