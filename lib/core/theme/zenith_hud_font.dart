import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import 'test_env/test_env.dart';

/// Digital-numeral display font (`DotGothic16`) reserved for large HUD-scale
/// numbers -- rest countdowns, big rep/RPE readouts -- per
/// `visual_identity_anchor.md`'s Display Tier note. Kept distinct from the
/// theme's `Silkscreen` display font (general titles/labels/badges) since a
/// dot-matrix numeral face is specifically what makes a countdown clock read
/// as a digital display.
///
/// Not pre-warmed by [ZenithPixelThemeBuilder] (only `Silkscreen`/`Inter`
/// are), so this calls `safeGoogleFont` directly -- mirroring the same
/// `isTestEnvironment` guard the theme builder uses, to avoid a network font
/// fetch under `flutter test`.
TextStyle pixelHudNumeral({
  required double fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) {
  if (isTestEnvironment) {
    return TextStyle(
      fontFamily: 'DotGothic16',
      fontFamilyFallback: const ['monospace'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
  return safeGoogleFont(
    family: 'DotGothic16',
    fallbackFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
