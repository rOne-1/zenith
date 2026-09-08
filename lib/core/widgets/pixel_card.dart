import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';
import '../theme/theme.dart';
import 'stepped_pixel_border.dart';

/// A retro 16-bit card container featuring stepped staircase corners and
/// an authentic 3D-effect bottom bevel shadow.
class PixelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? bevelColor;
  final double? borderWidth;
  final double? cornerStepSize;
  final double? bevelDepth;
  final VoidCallback? onTap;

  const PixelCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.bevelColor,
    this.borderWidth,
    this.cornerStepSize,
    this.bevelDepth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;

    final effectiveBackground = backgroundColor ?? colors.surfaceDark;
    final effectiveBorder = borderColor ?? colors.borderBright;
    final effectiveBevel = bevelColor ?? colors.borderMuted;
    final effectiveBorderWidth = borderWidth ?? metrics.borderWidth;
    final effectiveStepSize = cornerStepSize ?? metrics.cornerStepSize;
    final effectiveBevelDepth = bevelDepth ?? metrics.bevelDepth;
    final effectivePadding = padding ?? const EdgeInsets.all(16.0);

    Widget cardBody = CustomPaint(
      painter: _PixelCardPainter(
        backgroundColor: effectiveBackground,
        borderColor: effectiveBorder,
        bevelColor: effectiveBevel,
        borderWidth: effectiveBorderWidth,
        stepSize: effectiveStepSize,
        bevelDepth: effectiveBevelDepth,
      ),
      child: Padding(
        padding: effectivePadding.add(
          EdgeInsets.only(bottom: effectiveBevelDepth),
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      cardBody = PressableScale(onTap: onTap, child: cardBody);
    }

    if (margin != null) {
      cardBody = Padding(padding: margin!, child: cardBody);
    }

    return cardBody;
  }
}

class _PixelCardPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final Color bevelColor;
  final double borderWidth;
  final double stepSize;
  final double bevelDepth;

  _PixelCardPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.bevelColor,
    required this.borderWidth,
    required this.stepSize,
    required this.bevelDepth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final border = SteppedPixelBorder(
      side: BorderSide(color: borderColor, width: borderWidth),
      stepSize: stepSize,
    );

    if (bevelDepth > 0) {
      // Paint 3D bottom bevel shadow
      final shadowRect = Rect.fromLTWH(
        0,
        bevelDepth,
        size.width,
        size.height - bevelDepth,
      );
      final shadowPath = border.getOuterPath(shadowRect);
      final shadowPaint = Paint()
        ..color = bevelColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(shadowPath, shadowPaint);

      final shadowBorder = SteppedPixelBorder(
        side: BorderSide(color: bevelColor, width: borderWidth),
        stepSize: stepSize,
      );
      shadowBorder.paint(canvas, shadowRect);
    }

    // Paint card surface
    final faceRect = Rect.fromLTWH(0, 0, size.width, size.height - bevelDepth);
    final facePath = border.getOuterPath(faceRect);
    final facePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(facePath, facePaint);

    // Paint surface border outline
    border.paint(canvas, faceRect);
  }

  @override
  bool shouldRepaint(covariant _PixelCardPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.bevelColor != bevelColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.stepSize != stepSize ||
        oldDelegate.bevelDepth != bevelDepth;
  }
}
