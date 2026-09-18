import 'package:flutter/animation.dart';

/// Quantizes an animation into a fixed number of discrete frames, so a
/// tween lands on visible steps instead of interpolating smoothly.
///
/// Replaces `HouseSpring.curve` (a continuous spring ease from
/// `flutter_refined_kit`) wherever motion should read as pixel-art-stepped
/// rather than physically-eased, per the design correction in
/// `local-notes/visual_identity/visual_identity_anchor.md` v2 -- but keeps
/// motion *visible* (this is not `Duration.zero`): a short quantized move
/// still reads as intentional feedback, where an instant cut across every
/// interaction in the app read as broken rather than authentically pixel
/// art. See `local-notes/rules/standing_principles.md`'s SP-2 for why
/// motion isn't removed outright -- uniform, deliberate motion is this
/// app's own standing identity, just re-curved here instead of eased.
class ZenithStepCurve extends Curve {
  final int steps;
  const ZenithStepCurve([this.steps = 6]) : assert(steps >= 2);

  @override
  double transformInternal(double t) => (t * (steps - 1)).round() / (steps - 1);
}

/// Default 6-step quantized curve -- use this in place of `HouseSpring.curve`
/// for interaction feedback (button release, sheet/dialog open-close,
/// collapsible expand/collapse, route transitions).
const zenithStepCurve = ZenithStepCurve();

/// Default duration for quantized motion -- use this in place of
/// `HouseSpring.duration` alongside [zenithStepCurve]. Short enough to read
/// as a snap rather than a lingering animation.
///
/// 250ms over 6 steps holds each step for exactly 50ms -- 3 whole frames at
/// 60Hz and 6 whole frames at 120Hz. That's deliberate: the previous 180ms
/// held each step for 36ms, only ~2.7ms clear of the 60Hz 2-frame boundary
/// (33.3ms), so ordinary vsync jitter pushed some steps to render for 2
/// frames and others for 3 -- uneven hold-times that read as stutter/frame
/// drops rather than a clean retro snap. 50ms sits on an exact frame
/// multiple at both 60Hz and 120Hz, so every step renders for a consistent
/// number of frames on both refresh classes.
const zenithMotionDuration = Duration(milliseconds: 250);
