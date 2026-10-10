import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import 'test_env/test_env.dart';

/// Standard scale size constants for Silkscreen pixel display typography.
const double kPixelDisplaySmSize = 9.0;
const double kPixelDisplayMdSize = 11.0;
const double kPixelDisplayLgSize = 13.0;
const double kPixelDisplayXlSize = 16.0;

/// Primary brand display font (`Silkscreen`) for HUD headers, badges, section titles,
/// and pixel button labels.
///
/// Under test environments (`isTestEnvironment == true`), returns a local [TextStyle]
/// specifying `fontFamily: 'Silkscreen'` and fallback to `'monospace'`, completely
/// avoiding network font fetch hangs under `flutter test`.
///
/// In production, routes through [safeGoogleFont] with local fallback.
TextStyle zenithPixelDisplay({
  required double fontSize,
  Color? color,
  FontWeight? fontWeight = FontWeight.w700,
  double? letterSpacing = 1.0,
  double? height,
}) {
  if (isTestEnvironment) {
    return TextStyle(
      fontFamily: 'Silkscreen',
      fontFamilyFallback: const ['monospace'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }
  return safeGoogleFont(
    family: 'Silkscreen',
    fallbackFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
  );
}

/// Small Silkscreen display preset (9.0dp) for compact tags, sub-headers, and badges.
TextStyle pixelDisplaySm({
  Color? color,
  FontWeight? fontWeight = FontWeight.w700,
  double? letterSpacing = 1.0,
  double? height,
}) =>
    zenithPixelDisplay(
      fontSize: kPixelDisplaySmSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );

/// Medium Silkscreen display preset (11.0dp) for card headers, button labels, and status chips.
TextStyle pixelDisplayMd({
  Color? color,
  FontWeight? fontWeight = FontWeight.w700,
  double? letterSpacing = 1.0,
  double? height,
}) =>
    zenithPixelDisplay(
      fontSize: kPixelDisplayMdSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );

/// Large Silkscreen display preset (13.0dp) for screen section titles and prominent callouts.
TextStyle pixelDisplayLg({
  Color? color,
  FontWeight? fontWeight = FontWeight.w700,
  double? letterSpacing = 1.0,
  double? height,
}) =>
    zenithPixelDisplay(
      fontSize: kPixelDisplayLgSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );

/// Extra-large Silkscreen display preset (16.0dp) for hero headers and milestone titles.
TextStyle pixelDisplayXl({
  Color? color,
  FontWeight? fontWeight = FontWeight.w700,
  double? letterSpacing = 1.0,
  double? height,
}) =>
    zenithPixelDisplay(
      fontSize: kPixelDisplayXlSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );

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
