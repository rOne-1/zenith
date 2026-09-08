import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'stepped_pixel_border.dart';

/// A segmented retro countdown and progress indicator with discrete pixel blocks.
///
/// Gives rest countdowns, set trackers, and periodization timers an authentic
/// 16-bit HUD aesthetic.
class PixelCountdownBar extends StatelessWidget {
  /// Normalized progress value from 0.0 (empty) to 1.0 (full).
  final double progress;

  /// Total number of discrete blocks in the meter.
  final int totalBlocks;

  /// Height of the meter bar in logical pixels.
  final double height;

  /// Spacing between adjacent blocks.
  final double blockSpacing;

  /// Color of illuminated/active blocks (defaults to [ZenithDistrictColors.amberAccent]).
  final Color? activeColor;

  /// Color of dormant/inactive blocks (defaults to [ZenithDistrictColors.borderMuted]).
  final Color? inactiveColor;

  /// Color of the outer frame border (defaults to [ZenithDistrictColors.borderBright]).
  final Color? borderColor;

  /// Color of the meter track background (defaults to [ZenithDistrictColors.surfaceDark]).
  final Color? backgroundColor;

  /// Thickness of the frame border.
  final double borderWidth;

  /// Step notch size for the frame corners.
  final double cornerStepSize;

  /// Inner padding separating the frame from the blocks.
  final EdgeInsetsGeometry padding;

  const PixelCountdownBar({
    super.key,
    required this.progress,
    this.totalBlocks = 20,
    this.height = 14.0,
    this.blockSpacing = 2.0,
    this.activeColor,
    this.inactiveColor,
    this.borderColor,
    this.backgroundColor,
    this.borderWidth = 1.5,
    this.cornerStepSize = 2.0,
    this.padding = const EdgeInsets.all(3.0),
  }) : assert(totalBlocks > 0, 'totalBlocks must be greater than zero');

  /// Computes the number of illuminated blocks for the current progress.
  int get filledBlocks => (progress.clamp(0.0, 1.0) * totalBlocks).round();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final effectiveActive = activeColor ?? colors.amberAccent;
    final effectiveInactive = inactiveColor ?? colors.borderMuted;
    final effectiveBorder = borderColor ?? colors.borderBright;
    final effectiveBackground = backgroundColor ?? colors.surfaceDark;

    return Container(
      height: height,
      padding: padding,
      decoration: ShapeDecoration(
        color: effectiveBackground,
        shape: SteppedPixelBorder(
          side: BorderSide(color: effectiveBorder, width: borderWidth),
          stepSize: cornerStepSize,
        ),
      ),
      child: Row(
        children: List.generate(totalBlocks, (index) {
          final isFilled = index < filledBlocks;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < totalBlocks - 1 ? blockSpacing : 0.0,
              ),
              color: isFilled ? effectiveActive : effectiveInactive,
            ),
          );
        }),
      ),
    );
  }
}
