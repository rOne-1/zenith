import 'package:flutter/animation.dart';

/// The app's shared interaction-motion curve: continuous (not stepped) and
/// front-loaded so the motion reads as a fast, decisive snap into place
/// rather than a lingering ease.
///
/// This replaces an earlier discrete-step curve (`ZenithStepCurve`, quantized
/// into 6 held frames) that was meant to read as pixel-art-stepped per the
/// v2 design correction. On a real device it read as stutter/frame drops
/// instead -- retuning the step timing to align with 60Hz/120Hz frame
/// boundaries didn't fix it, because the discreteness itself (each step
/// visibly *held*, then jumped) was the problem, not its alignment. A
/// continuous curve has no held frames to misalign in the first place: the
/// compositor interpolates a new correct value every real vsync tick at
/// whatever refresh rate the device renders at.
const zenithMotionCurve = Curves.easeOutExpo;

/// Default duration for interaction motion -- use this in place of
/// `HouseSpring.duration` alongside [zenithMotionCurve]. Short, so a fast
/// curve like [zenithMotionCurve] still reads as a snap rather than a
/// lingering animation.
const zenithMotionDuration = Duration(milliseconds: 160);
