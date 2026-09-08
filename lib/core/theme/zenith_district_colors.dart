import 'package:flutter/material.dart';

/// Semantic color tokens for Japan city districts in Zenith.
///
/// Consumed by widgets via `context.colors` to avoid `isDark` branching.
@immutable
class ZenithDistrictColors extends ThemeExtension<ZenithDistrictColors> {
  // Surface Layers
  final Color backgroundVoid;
  final Color surfaceDark;
  final Color surfaceElevated;
  final Color surfaceHighlight;

  // Pixel Borders & Grids
  final Color borderMuted;
  final Color borderBright;

  // Accents & Signals
  final Color amberAccent;
  final Color amberGlow;
  final Color signalRed;
  final Color foliageVibrant;

  // Typography
  final Color textPrimary;
  final Color textMuted;

  const ZenithDistrictColors({
    required this.backgroundVoid,
    required this.surfaceDark,
    required this.surfaceElevated,
    required this.surfaceHighlight,
    required this.borderMuted,
    required this.borderBright,
    required this.amberAccent,
    required this.amberGlow,
    required this.signalRed,
    required this.foliageVibrant,
    required this.textPrimary,
    required this.textMuted,
  });

  /// Default fallback tokens based on District 01 (Railside Outskirts).
  static const ZenithDistrictColors fallback = ZenithDistrictColors(
    backgroundVoid: Color(0xFF070E10),
    surfaceDark: Color(0xFF0C181A),
    surfaceElevated: Color(0xFF152B2C),
    surfaceHighlight: Color(0xFF1F3E3D),
    borderMuted: Color(0xFF1A3332),
    borderBright: Color(0xFF2D5552),
    amberAccent: Color(0xFFFFAE34),
    amberGlow: Color(0xFFFFD269),
    signalRed: Color(0xFFFF493A),
    foliageVibrant: Color(0xFF4B8E62),
    textPrimary: Color(0xFFE8F5F2),
    textMuted: Color(0xFF7D9B98),
  );

  @override
  ZenithDistrictColors copyWith({
    Color? backgroundVoid,
    Color? surfaceDark,
    Color? surfaceElevated,
    Color? surfaceHighlight,
    Color? borderMuted,
    Color? borderBright,
    Color? amberAccent,
    Color? amberGlow,
    Color? signalRed,
    Color? foliageVibrant,
    Color? textPrimary,
    Color? textMuted,
  }) {
    return ZenithDistrictColors(
      backgroundVoid: backgroundVoid ?? this.backgroundVoid,
      surfaceDark: surfaceDark ?? this.surfaceDark,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      borderMuted: borderMuted ?? this.borderMuted,
      borderBright: borderBright ?? this.borderBright,
      amberAccent: amberAccent ?? this.amberAccent,
      amberGlow: amberGlow ?? this.amberGlow,
      signalRed: signalRed ?? this.signalRed,
      foliageVibrant: foliageVibrant ?? this.foliageVibrant,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ThemeExtension<ZenithDistrictColors> lerp(
    covariant ThemeExtension<ZenithDistrictColors>? other,
    double t,
  ) {
    if (other is! ZenithDistrictColors) return this;
    return ZenithDistrictColors(
      backgroundVoid: Color.lerp(backgroundVoid, other.backgroundVoid, t)!,
      surfaceDark: Color.lerp(surfaceDark, other.surfaceDark, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceHighlight: Color.lerp(
        surfaceHighlight,
        other.surfaceHighlight,
        t,
      )!,
      borderMuted: Color.lerp(borderMuted, other.borderMuted, t)!,
      borderBright: Color.lerp(borderBright, other.borderBright, t)!,
      amberAccent: Color.lerp(amberAccent, other.amberAccent, t)!,
      amberGlow: Color.lerp(amberGlow, other.amberGlow, t)!,
      signalRed: Color.lerp(signalRed, other.signalRed, t)!,
      foliageVibrant: Color.lerp(foliageVibrant, other.foliageVibrant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}
