import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import 'test_env/test_env.dart';

/// Body/running-copy font (`IBM Plex Mono`) for coach cues, advisory prose,
/// and gauge sub-labels -- everything that isn't a `Silkscreen` label/badge
/// or a `DotGothic16` HUD numeral (see [pixelHudNumeral]). A monospace body
/// face keeps this text reading as a terminal readout rather than the
/// sans-serif "modern app" look a face like Inter gives it.
///
/// Not pre-warmed by [ZenithPixelThemeBuilder] (only `Silkscreen`/`Inter`
/// are, and this replaces the latter as the theme's own body-font default
/// too), so this calls `safeGoogleFont` directly -- mirroring the same
/// `isTestEnvironment` guard the theme builder and [pixelHudNumeral] use, to
/// avoid a network font fetch under `flutter test`.
TextStyle zenithBodyMono({
  required double fontSize,
  required Color color,
  double height = 1.4,
  FontWeight? fontWeight,
}) {
  if (isTestEnvironment) {
    return TextStyle(
      fontFamily: 'IBM Plex Mono',
      fontFamilyFallback: const ['monospace'],
      fontSize: fontSize,
      height: height,
      color: color,
      fontWeight: fontWeight,
    );
  }
  return safeGoogleFont(
    family: 'IBM Plex Mono',
    fallbackFamily: 'monospace',
    fontSize: fontSize,
    height: height,
    color: color,
    fontWeight: fontWeight,
  );
}
