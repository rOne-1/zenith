import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import 'test_env/test_env.dart';
import 'zenith_district_colors.dart';
import 'zenith_district_palette.dart';
import 'zenith_pixel_metrics.dart';

/// Route transitions builder powered by [HouseSpring.curve].
class HouseSpringPageTransitionsBuilder extends PageTransitionsBuilder {
  const HouseSpringPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: HouseSpring.curve,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

/// Builds a [FontBuilder] for [family] (with [fallback] as its fallback
/// family name): a plain [TextStyle] under test (avoiding network font
/// loading), or [safeGoogleFont] otherwise. Every font the theme needs is
/// produced by this one function instead of separately hand-written
/// ~90-line closures repeating the same 19-parameter signature per
/// family/environment combination.
FontBuilder _buildFont({required String family, required String fallback}) {
  return ({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    if (isTestEnvironment) {
      return TextStyle(
        fontFamily: family,
        fontFamilyFallback: [fallback],
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      );
    }
    return safeGoogleFont(
      family: family,
      fallbackFamily: fallback,
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  };
}

/// Factory that consumes a [ZenithDistrictPalette] and returns a fully-configured
/// [AppTheme<ZenithDistrictColors>] wired with pixel metrics, typography, and physics.
class ZenithPixelThemeBuilder {
  const ZenithPixelThemeBuilder._();

  static AppTheme<ZenithDistrictColors> build(
    ZenithDistrictPalette palette, {
    FontBuilder? displayFont,
    FontBuilder? bodyFont,
  }) {
    final colors = ZenithDistrictColors(
      backgroundVoid: palette.backgroundVoid,
      surfaceDark: palette.surfaceDark,
      surfaceElevated: palette.surfaceElevated,
      surfaceHighlight: palette.surfaceHighlight,
      borderMuted: palette.borderMuted,
      borderBright: palette.borderBright,
      amberAccent: palette.amberAccent,
      amberGlow: palette.amberGlow,
      signalRed: palette.signalRed,
      foliageVibrant: palette.foliageVibrant,
      textPrimary: palette.textPrimary,
      textMuted: palette.textMuted,
    );

    const pixelMetrics = ZenithPixelMetrics();

    final FontBuilder effectiveDisplayFont =
        displayFont ?? _buildFont(family: 'Silkscreen', fallback: 'monospace');
    final FontBuilder effectiveBodyFont =
        bodyFont ?? _buildFont(family: 'IBM Plex Mono', fallback: 'monospace');

    final themeData = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.backgroundVoid,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: HouseSpringPageTransitionsBuilder(),
          TargetPlatform.iOS: HouseSpringPageTransitionsBuilder(),
          TargetPlatform.windows: HouseSpringPageTransitionsBuilder(),
          TargetPlatform.macOS: HouseSpringPageTransitionsBuilder(),
          TargetPlatform.linux: HouseSpringPageTransitionsBuilder(),
        },
      ),
      textTheme: buildTextTheme(
        textColor: palette.textPrimary,
        displayFont: effectiveDisplayFont,
        bodyFont: effectiveBodyFont,
      ),
      extensions: [colors, pixelMetrics],
    );

    return AppTheme<ZenithDistrictColors>(
      id: palette.id,
      displayName: palette.nameEn,
      description: palette.description,
      isDark: true,
      colors: colors,
      themeData: themeData,
      signatureMotif: palette.atmosphericMotif,
    );
  }
}
