import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A small bordered pixel-style chip: bordered box around a single line of
/// Silkscreen-styled text. Used throughout the app for status/tier/phase
/// badges (e.g. "MAX TIER 02", "CYCLE 03", "PROFICIENT").
class PixelBadge extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color borderColor;
  final Color? backgroundColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final EdgeInsetsGeometry padding;

  const PixelBadge({
    super.key,
    required this.text,
    required this.textColor,
    required this.borderColor,
    this.backgroundColor,
    this.fontSize = 10.0,
    this.fontWeight = FontWeight.w800,
    this.letterSpacing = 0.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.backgroundVoid,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Silkscreen',
          fontFamilyFallback: const ['monospace'],
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
