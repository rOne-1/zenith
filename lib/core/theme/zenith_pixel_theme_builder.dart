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

    final FontBuilder effectiveDisplayFont;
    if (displayFont != null) {
      effectiveDisplayFont = displayFont;
    } else if (isTestEnvironment) {
      effectiveDisplayFont =
          ({
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
          }) => TextStyle(
            fontFamily: 'Silkscreen',
            fontFamilyFallback: const ['monospace'],
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
    } else {
      effectiveDisplayFont =
          ({
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
          }) => safeGoogleFont(
            family: 'Silkscreen',
            fallbackFamily: 'monospace',
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
    }

    final FontBuilder effectiveBodyFont;
    if (bodyFont != null) {
      effectiveBodyFont = bodyFont;
    } else if (isTestEnvironment) {
      effectiveBodyFont =
          ({
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
          }) => TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: const ['sans-serif'],
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
    } else {
      effectiveBodyFont =
          ({
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
          }) => safeGoogleFont(
            family: 'Inter',
            fallbackFamily: 'sans-serif',
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
    }

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
