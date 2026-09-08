import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom [OutlinedBorder] that paints 90-degree stepped staircase corners
/// instead of smooth vector radius arcs.
///
/// Gives containers, buttons, and cards an authentic 16-bit retro silhouette.
class SteppedPixelBorder extends OutlinedBorder {
  /// Size of the corner notch step in logical pixels.
  final double stepSize;

  const SteppedPixelBorder({
    super.side = const BorderSide(color: Colors.white, width: 2.0),
    this.stepSize = 4.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return SteppedPixelBorder(side: side.scale(t), stepSize: stepSize * t);
  }

  @override
  OutlinedBorder copyWith({BorderSide? side, double? stepSize}) {
    return SteppedPixelBorder(
      side: side ?? this.side,
      stepSize: stepSize ?? this.stepSize,
    );
  }

  Path _buildSteppedPath(Rect rect, double step) {
    final effectiveStep = math.max(
      0.0,
      math.min(step, math.min(rect.width, rect.height) / 2),
    );

    final path = Path();
    if (effectiveStep <= 0.0) {
      path.addRect(rect);
      return path;
    }

    path.moveTo(rect.left + effectiveStep, rect.top);
    // Top edge
    path.lineTo(rect.right - effectiveStep, rect.top);
    // Top-right step
    path.lineTo(rect.right - effectiveStep, rect.top + effectiveStep);
    path.lineTo(rect.right, rect.top + effectiveStep);
    // Right edge
    path.lineTo(rect.right, rect.bottom - effectiveStep);
    // Bottom-right step
    path.lineTo(rect.right - effectiveStep, rect.bottom - effectiveStep);
    path.lineTo(rect.right - effectiveStep, rect.bottom);
    // Bottom edge
    path.lineTo(rect.left + effectiveStep, rect.bottom);
    // Bottom-left step
    path.lineTo(rect.left + effectiveStep, rect.bottom - effectiveStep);
    path.lineTo(rect.left, rect.bottom - effectiveStep);
    // Left edge
    path.lineTo(rect.left, rect.top + effectiveStep);
    // Top-left step
    path.lineTo(rect.left + effectiveStep, rect.top + effectiveStep);
    path.close();

    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildSteppedPath(rect, stepSize);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final innerRect = rect.deflate(side.width);
    final innerStep = math.max(0.0, stepSize - side.width);
    return _buildSteppedPath(innerRect, innerStep);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;

    final paintRect = rect.deflate(side.width / 2);
    final paintStep = math.max(0.0, stepSize - (side.width / 2));
    final path = _buildSteppedPath(paintRect, paintStep);

    canvas.drawPath(path, side.toPaint());
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SteppedPixelBorder) {
      return SteppedPixelBorder(
        side: BorderSide.lerp(a.side, side, t),
        stepSize: a.stepSize + (stepSize - a.stepSize) * t,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SteppedPixelBorder) {
      return SteppedPixelBorder(
        side: BorderSide.lerp(side, b.side, t),
        stepSize: stepSize + (b.stepSize - stepSize) * t,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is SteppedPixelBorder &&
        other.side == side &&
        other.stepSize == stepSize;
  }

  @override
  int get hashCode => Object.hash(side, stepSize);
}
