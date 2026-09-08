import 'package:flutter/material.dart';

/// Standardized pixel geometry metrics for retro frames, buttons, and cards.
@immutable
class ZenithPixelMetrics extends ThemeExtension<ZenithPixelMetrics> {
  /// Base pixel scale multiplier (e.g. 2.0 or 3.0 logical pixels per pixel unit).
  final double pixelScale;

  /// Standard outline thickness for retro stepped borders (default: 2.0).
  final double borderWidth;

  /// Distance the button moves downward on press to simulate mechanical depth (default: 3.0).
  final double buttonDropOffset;

  /// Size of the stepped notch in card corners (default: 4.0).
  final double cornerStepSize;

  /// Depth of the 3D-effect bottom shadow for cards and buttons (default: 4.0).
  final double bevelDepth;

  const ZenithPixelMetrics({
    this.pixelScale = 2.0,
    this.borderWidth = 2.0,
    this.buttonDropOffset = 3.0,
    this.cornerStepSize = 4.0,
    this.bevelDepth = 4.0,
  });

  @override
  ZenithPixelMetrics copyWith({
    double? pixelScale,
    double? borderWidth,
    double? buttonDropOffset,
    double? cornerStepSize,
    double? bevelDepth,
  }) {
    return ZenithPixelMetrics(
      pixelScale: pixelScale ?? this.pixelScale,
      borderWidth: borderWidth ?? this.borderWidth,
      buttonDropOffset: buttonDropOffset ?? this.buttonDropOffset,
      cornerStepSize: cornerStepSize ?? this.cornerStepSize,
      bevelDepth: bevelDepth ?? this.bevelDepth,
    );
  }

  @override
  ThemeExtension<ZenithPixelMetrics> lerp(
    covariant ThemeExtension<ZenithPixelMetrics>? other,
    double t,
  ) {
    if (other is! ZenithPixelMetrics) return this;
    return ZenithPixelMetrics(
      pixelScale: pixelScale + (other.pixelScale - pixelScale) * t,
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
      buttonDropOffset:
          buttonDropOffset + (other.buttonDropOffset - buttonDropOffset) * t,
      cornerStepSize:
          cornerStepSize + (other.cornerStepSize - cornerStepSize) * t,
      bevelDepth: bevelDepth + (other.bevelDepth - bevelDepth) * t,
    );
  }
}
