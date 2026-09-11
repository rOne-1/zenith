import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../engine/illustration/exercise_pose_library.dart';
import '../../../engine/illustration/figure_pose.dart';
import 'metro_transit_map.dart';

/// Exercise ids with sourced illustrations at
/// `assets/exercises/<id>_frame_{1,2,3}.svg` (from bryllim/workout-guide,
/// CC BY-SA 4.0 -- see assets/exercises/ATTRIBUTION.md and the in-app
/// credits section). Every exercise in this set has exactly 3 frames; that
/// invariant is what lets this be a plain id set rather than a
/// per-exercise frame-count map.
const Set<String> _svgSourcedExerciseIds = {
  // Pushing
  'wall_pushup',
  'knee_pushup',
  'standard_pushup',
  'feet_elevated_pushup',
  'chair_dip',
  'archer_pushup',
  // Pulling
  'doorframe_row',
  'towel_row',
  'inverted_row',
  'standard_pullup',
  'l_sit_pullup',
  // Bend & Lift
  'good_morning',
  'towel_hamstring_curl',
  'nordic_curl',
  // Single Leg
  'air_squat',
  'reverse_lunge',
  'bulgarian_split_squat',
  'skater_squat',
  'assisted_pistol_squat',
  'full_pistol_squat',
  // Rotation
  'dead_bug',
  'side_plank',
  'banded_pallof_press',
  'dragon_flag',
};

/// True if [exerciseId] has an illustration -- sourced or custom-rig --
/// available. Exposed so callers/tests can check coverage without
/// depending on [_svgSourcedExerciseIds]'s privacy.
bool isExerciseIllustrated(String exerciseId) =>
    _svgSourcedExerciseIds.contains(exerciseId) ||
    customPoseLibrary.containsKey(exerciseId);

/// True if [exerciseId] is illustrated via a vendored SVG (as opposed to
/// the custom rig) -- exposed so the credits section can list exactly the
/// exercises the CC BY-SA attribution actually covers.
bool isSvgSourcedExercise(String exerciseId) =>
    _svgSourcedExerciseIds.contains(exerciseId);

/// Renders an exercise's illustrated movement -- either sourced SVG frames
/// or a hand-authored [FigurePose] sequence (see [customPoseLibrary]) --
/// as a themed strip of poses tinted to the exercise's movement-pattern
/// accent color. Both art sources share one outer layout so they're
/// visually indistinguishable to the user.
class ExerciseIllustration extends StatelessWidget {
  final Exercise exercise;

  const ExerciseIllustration({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = MetroLineTheme.forPattern(exercise.movementPattern).color;

    final Widget content;
    if (_svgSourcedExerciseIds.contains(exercise.id)) {
      content = _SvgFrameStrip(exerciseId: exercise.id, accentColor: accentColor);
    } else if (customPoseLibrary.containsKey(exercise.id)) {
      content = _RigFrameStrip(
        poses: customPoseLibrary[exercise.id]!,
        accentColor: accentColor,
      );
    } else {
      // Every catalog exercise has an entry in one of the two libraries
      // (enforced by exercise_pose_library_test.dart's completeness
      // check), but render nothing rather than a broken placeholder for
      // any exercise that somehow doesn't -- the FORM CUES text above/
      // below still stands on its own.
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: colors.backgroundVoid,
        border: Border.all(color: colors.borderMuted, width: 1.0),
      ),
      child: content,
    );
  }
}

class _SvgFrameStrip extends StatelessWidget {
  final String exerciseId;
  final Color accentColor;

  const _SvgFrameStrip({required this.exerciseId, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return _FrameRow(
      frameCount: 3,
      accentColor: accentColor,
      frameBuilder: (i) => SvgPicture.asset(
        'assets/exercises/${exerciseId}_frame_${i + 1}.svg',
        colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
        fit: BoxFit.contain,
      ),
    );
  }
}

class _RigFrameStrip extends StatelessWidget {
  final List<FigurePose> poses;
  final Color accentColor;

  const _RigFrameStrip({required this.poses, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return _FrameRow(
      frameCount: poses.length,
      accentColor: accentColor,
      frameBuilder: (i) => CustomPaint(
        painter: _FigureRigPainter(pose: poses[i], color: accentColor),
      ),
    );
  }
}

/// Shared layout for both art sources: N square thumbnails in a row, each
/// followed by a ">" transition chevron except the last.
class _FrameRow extends StatelessWidget {
  final int frameCount;
  final Color accentColor;
  final Widget Function(int index) frameBuilder;

  const _FrameRow({
    required this.frameCount,
    required this.accentColor,
    required this.frameBuilder,
  });

  static const _frameSize = 96.0;

  @override
  Widget build(BuildContext context) {
    // A 3-frame strip at _frameSize doesn't reliably fit this codebase's
    // narrow-mobile-viewport baseline (375px) once the surrounding card's
    // own padding is accounted for -- scrolling horizontally instead of
    // shrinking the frames (or risking overflow) keeps every illustration
    // at a consistent, legible size regardless of screen width.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Center(child: _row(context)),
    );
  }

  Widget _row(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < frameCount; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(Icons.chevron_right, color: accentColor, size: 16.0),
            ),
          SizedBox(
            width: _frameSize,
            height: _frameSize,
            child: frameBuilder(i),
          ),
        ],
      ],
    );
  }
}

/// One resolved joint chain, ready to draw: every point the painter needs,
/// already positioned in canvas space.
class _ResolvedFigure {
  final Offset hip;
  final Offset shoulder;
  final Offset elbow;
  final Offset hand;
  final Offset headCenter;
  final Offset knee;
  final Offset foot;
  final Offset? rearElbow;
  final Offset? rearHand;
  final Offset? rearKnee;
  final Offset? rearFoot;

  const _ResolvedFigure({
    required this.hip,
    required this.shoulder,
    required this.elbow,
    required this.hand,
    required this.headCenter,
    required this.knee,
    required this.foot,
    this.rearElbow,
    this.rearHand,
    this.rearKnee,
    this.rearFoot,
  });
}

/// Draws one [FigurePose] as a side-profile silhouette skeleton: fixed
/// bone-length ratios (anatomy, not authored content) driven by the pose's
/// joint angles via forward kinematics.
///
/// Angle convention: every direction is a "compass" angle in degrees where
/// 0 deg points straight up and angles increase clockwise (so a positive
/// angle sweeps toward the figure's front/right, matching the fixed
/// right-facing silhouette convention used throughout this rig). See
/// [_dir].
///
/// The hip<->hand kinematic chain is walked in one of two directions
/// depending on which end is actually fixed in space -- solved as two
/// explicit branches (see [_resolveHipRooted]/[_resolveHandRooted]) rather
/// than one template forced to cover both, matching this rig's own
/// "closed set of anchors, not a general IK solver" design (see
/// [FigureAnchor]'s doc):
///  * hip-rooted (standing/lyingProne/lyingSupine): the hip is fixed; the
///    chain walks hip -> shoulder -> elbow -> hand and hip -> knee -> foot.
///  * hand-rooted (hangingFromBar/dipSupportOnBar): the hands are fixed to
///    the bar; the chain walks hand -> elbow -> shoulder -> hip -> knee ->
///    foot, the reverse order.
class _FigureRigPainter extends CustomPainter {
  final FigurePose pose;
  final Color color;

  _FigureRigPainter({required this.pose, required this.color});

  // Bone-length ratios as fractions of the painted figure's height.
  static const _headRadiusRatio = 0.07;
  static const _torsoRatio = 0.32;
  static const _upperArmRatio = 0.17;
  static const _forearmRatio = 0.15;
  static const _thighRatio = 0.24;
  static const _shinRatio = 0.22;

  // Forward bias applied to a relaxed (0-flexion) arm so it doesn't render
  // exactly collinear with the torso/leg line -- see _resolveHipRooted.
  static const _armRestBiasDeg = 12.0;

  static Offset _dir(double compassDeg) {
    final rad = compassDeg * math.pi / 180.0;
    return Offset(math.sin(rad), -math.cos(rad));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final figureHeight = size.shortestSide * 0.85;
    final boneWidth = figureHeight * 0.045;
    final center = Offset(size.width / 2, size.height / 2);

    final bones = <double>[
      figureHeight * _torsoRatio,
      figureHeight * _upperArmRatio,
      figureHeight * _forearmRatio,
      figureHeight * _thighRatio,
      figureHeight * _shinRatio,
    ];
    final headRadius = figureHeight * _headRadiusRatio;

    final figure = pose.anchor == FigureAnchor.hangingFromBar ||
            pose.anchor == FigureAnchor.dipSupportOnBar
        ? _resolveHandRooted(center, figureHeight, bones, headRadius)
        : _resolveHipRooted(center, figureHeight, bones, headRadius);

    final jointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final bonePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = boneWidth
      ..strokeCap = StrokeCap.round;
    final rearPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = boneWidth
      ..strokeCap = StrokeCap.round;

    if (figure.rearElbow != null) {
      canvas.drawLine(figure.shoulder, figure.rearElbow!, rearPaint);
      canvas.drawLine(figure.rearElbow!, figure.rearHand!, rearPaint);
    }
    if (figure.rearKnee != null) {
      canvas.drawLine(figure.hip, figure.rearKnee!, rearPaint);
      canvas.drawLine(figure.rearKnee!, figure.rearFoot!, rearPaint);
    }

    canvas.drawLine(figure.hip, figure.shoulder, bonePaint);
    canvas.drawLine(figure.shoulder, figure.elbow, bonePaint);
    canvas.drawLine(figure.elbow, figure.hand, bonePaint);
    canvas.drawLine(figure.hip, figure.knee, bonePaint);
    canvas.drawLine(figure.knee, figure.foot, bonePaint);

    for (final p in [
      figure.hip,
      figure.shoulder,
      figure.elbow,
      figure.hand,
      figure.knee,
      figure.foot,
    ]) {
      canvas.drawCircle(p, boneWidth * 0.65, jointPaint);
    }
    canvas.drawCircle(figure.headCenter, headRadius, jointPaint);
  }

  /// Root = hip. Torso stands "up" (or lies flat for the supine/prone
  /// anchors) from there; arms hang "down" at 0 flexion and swing toward
  /// the torso's own direction as shoulderFlexion increases; legs hang
  /// straight down at 0 flexion and swing forward as hipFlexion increases.
  _ResolvedFigure _resolveHipRooted(
    Offset center,
    double figureHeight,
    List<double> bones,
    double headRadius,
  ) {
    final torsoLen = bones[0], upperArmLen = bones[1], forearmLen = bones[2];
    final thighLen = bones[3], shinLen = bones[4];

    final hip = pose.anchor == FigureAnchor.standing
        ? center + const Offset(0, 1) * (figureHeight * 0.18)
        : center;

    final torsoBaseDir = switch (pose.anchor) {
      FigureAnchor.lyingSupine || FigureAnchor.lyingProne => 90.0,
      _ => 0.0,
    };
    final torsoDir = torsoBaseDir + pose.torsoLean;
    final shoulder = hip + _dir(torsoDir) * torsoLen;
    final headCenter = shoulder + _dir(torsoDir) * (headRadius * 1.3);

    // A relaxed arm hangs a little forward of the torso/leg line, not
    // perfectly collinear with it -- without this bias, a 0-flexion arm
    // and a 0-flexion leg are both drawn straight down from their (offset
    // but parallel) attachment points and read as one overlapping line.
    final armRestDir = torsoDir + 180 - _armRestBiasDeg;
    final upperArmDir = armRestDir - pose.shoulderFlexion;
    final elbow = shoulder + _dir(upperArmDir) * upperArmLen;
    final forearmDir = upperArmDir - pose.elbowFlexion;
    final hand = elbow + _dir(forearmDir) * forearmLen;

    // Legs extend opposite the torso's own rest direction -- "down" from a
    // standing hip, or the other way along the body line from a prone hip
    // (forming one straight plank rather than both branches heading the
    // same way). lyingSupine intentionally keeps the plain 180 (down)
    // rest direction rather than mirroring lyingProne here -- its poses
    // (see exercise_pose_library.dart) already express "legs raised" via
    // a large hipFlexion off that same down-facing rest, and changing it
    // would need re-deriving those angles for no visual benefit.
    final legBaseDir =
        pose.anchor == FigureAnchor.lyingProne ? torsoBaseDir + 180 : 180.0;
    final thighDir = legBaseDir - pose.hipFlexion;
    final knee = hip + _dir(thighDir) * thighLen;
    final shinDir = thighDir + pose.kneeFlexion;
    final foot = knee + _dir(shinDir) * shinLen;

    Offset? rearElbow, rearHand, rearKnee, rearFoot;
    if (pose.shoulderFlexionRear != null || pose.elbowFlexionRear != null) {
      final sf = pose.shoulderFlexionRear ?? pose.shoulderFlexion;
      final ef = pose.elbowFlexionRear ?? pose.elbowFlexion;
      final rUpperDir = armRestDir - sf;
      rearElbow = shoulder + _dir(rUpperDir) * upperArmLen;
      rearHand = rearElbow + _dir(rUpperDir - ef) * forearmLen;
    }
    if (pose.hipFlexionRear != null || pose.kneeFlexionRear != null) {
      final hf = pose.hipFlexionRear ?? pose.hipFlexion;
      final kf = pose.kneeFlexionRear ?? pose.kneeFlexion;
      final rThighDir = legBaseDir - hf;
      rearKnee = hip + _dir(rThighDir) * thighLen;
      rearFoot = rearKnee + _dir(rThighDir + kf) * shinLen;
    }

    return _ResolvedFigure(
      hip: hip,
      shoulder: shoulder,
      elbow: elbow,
      hand: hand,
      headCenter: headCenter,
      knee: knee,
      foot: foot,
      rearElbow: rearElbow,
      rearHand: rearHand,
      rearKnee: rearKnee,
      rearFoot: rearFoot,
    );
  }

  /// Root = hands, fixed near the top of the canvas (the bar prop sits at
  /// this height). At 0 flexion the whole chain hangs as one straight
  /// vertical line below the hands ([FigureAnchor.hangingFromBar]'s dead
  /// hang). [FigureAnchor.dipSupportOnBar] flips the solve so the torso
  /// rises *above* the fixed hand-line instead -- the discrete flip
  /// [FigureAnchor] itself exists to express.
  _ResolvedFigure _resolveHandRooted(
    Offset center,
    double figureHeight,
    List<double> bones,
    double headRadius,
  ) {
    final torsoLen = bones[0], upperArmLen = bones[1], forearmLen = bones[2];
    final thighLen = bones[3], shinLen = bones[4];

    final hand = center - const Offset(0, 1) * (figureHeight * 0.32);

    if (pose.anchor == FigureAnchor.dipSupportOnBar) {
      // Body rises above the fixed hand-line: torso goes UP from the
      // hands, straight-armed brace down to the hands, legs hang below
      // hip. The arm is (near-)straight in a lockout, so the elbow sits
      // on the hand-to-shoulder line rather than getting its own bend.
      final torsoDir = 0.0 + pose.torsoLean;
      final armDir = 180.0 - pose.shoulderFlexion;
      final shoulder = hand + _dir(armDir) * (upperArmLen + forearmLen);
      final elbow = hand + _dir(armDir + pose.elbowFlexion) * forearmLen;
      final hip = shoulder + _dir(torsoDir) * torsoLen;
      final headCenter = hip + _dir(torsoDir) * (headRadius * 1.3);
      const legBaseDir = 180.0;
      final thighDir = legBaseDir - pose.hipFlexion;
      final knee = hip + _dir(thighDir) * thighLen;
      final foot = knee + _dir(thighDir + pose.kneeFlexion) * shinLen;
      return _ResolvedFigure(
        hip: hip,
        shoulder: shoulder,
        elbow: elbow,
        hand: hand,
        headCenter: headCenter,
        knee: knee,
        foot: foot,
      );
    }

    // hangingFromBar: chain walks down from the fixed hands.
    final forearmDir = 180.0 + pose.elbowFlexion;
    final elbow = hand + _dir(forearmDir) * forearmLen;
    final upperArmDir = forearmDir - pose.elbowFlexion + pose.shoulderFlexion;
    final shoulder = elbow + _dir(upperArmDir) * upperArmLen;
    final torsoDir = upperArmDir - pose.shoulderFlexion;
    final hip = shoulder + _dir(torsoDir) * torsoLen;
    // The head sits above the shoulder (the end of the chain away from the
    // hip), so it extends opposite torsoDir, not beyond the hip.
    final headCenter = shoulder + _dir(torsoDir + 180) * (headRadius * 1.3);

    const legBaseDir = 0.0; // legs continue the hang, straight down from hip
    final thighDir = legBaseDir - pose.hipFlexion;
    final knee = hip + _dir(thighDir) * thighLen;
    final foot = knee + _dir(thighDir + pose.kneeFlexion) * shinLen;

    // Rear arm, e.g. an archer pull-up's straight "gliding" arm. Drawn from
    // the same shoulder point reaching toward its own hand position -- an
    // approximation, since this rig models a single fixed hand root, not
    // two independently anchored hands on a wide bar grip.
    Offset? rearElbow, rearHand;
    if (pose.shoulderFlexionRear != null || pose.elbowFlexionRear != null) {
      final sf = pose.shoulderFlexionRear ?? pose.shoulderFlexion;
      final ef = pose.elbowFlexionRear ?? pose.elbowFlexion;
      final rUpperArmDir = 180.0 + sf;
      rearElbow = shoulder + _dir(rUpperArmDir) * upperArmLen;
      rearHand = rearElbow + _dir(rUpperArmDir - ef) * forearmLen;
    }

    return _ResolvedFigure(
      hip: hip,
      shoulder: shoulder,
      elbow: elbow,
      hand: hand,
      headCenter: headCenter,
      knee: knee,
      foot: foot,
      rearElbow: rearElbow,
      rearHand: rearHand,
    );
  }

  @override
  bool shouldRepaint(covariant _FigureRigPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.color != color;
}
