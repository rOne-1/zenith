import 'package:flutter/material.dart';

/// Lightweight data contract for defining city district themes.
class ZenithDistrictPalette {
  final String id;
  final String nameEn;
  final String description;

  final Color backgroundVoid;
  final Color surfaceDark;
  final Color surfaceElevated;
  final Color surfaceHighlight;
  final Color borderMuted;
  final Color borderBright;
  final Color amberAccent;
  final Color amberGlow;
  final Color signalRed;
  final Color foliageVibrant;
  final Color textPrimary;
  final Color textMuted;

  /// Atmospheric background backdrop builder (passing train, rain, lanterns).
  final WidgetBuilder? atmosphericMotif;

  const ZenithDistrictPalette({
    required this.id,
    required this.nameEn,
    required this.description,
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
    this.atmosphericMotif,
  });
}
