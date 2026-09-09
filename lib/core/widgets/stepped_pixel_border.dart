import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom [OutlinedBorder] that paints 90-degree stepped staircase corners
/// instead of smooth vector radius arcs.
///
/// Gives containers, buttons, and cards an authentic 16-bit retro silhouette.
class SteppedPixelBorder extends OutlinedBorder {
  /// Size of the corner notch in logical pixels (the total run/rise of the
  /// staircase, not the size of an individual tread).
  final double stepSize;

  /// Number of descending treads the corner staircase is built from.
  ///
  /// `1` reproduces the original single-notch corner. `2`-`4` subdivide the
  /// same [stepSize] into that many smaller treads so the corner actually
  /// reads as pixel-art stairs rather than a single diagonal-ish cut.
  final int stepCount;

  const SteppedPixelBorder({
    super.side = const BorderSide(color: Colors.white, width: 2.0),
    this.stepSize = 4.0,
    this.stepCount = 2,
  }) : assert(stepCount >= 1, 'stepCount must be at least 1');

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return SteppedPixelBorder(
      side: side.scale(t),
      stepSize: stepSize * t,
      stepCount: stepCount,
    );
  }

  @override
  OutlinedBorder copyWith({BorderSide? side, double? stepSize, int? stepCount}) {
    return SteppedPixelBorder(
      side: side ?? this.side,
      stepSize: stepSize ?? this.stepSize,
      stepCount: stepCount ?? this.stepCount,
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

    final unit = effectiveStep / stepCount;

    path.moveTo(rect.left + effectiveStep, rect.top);
    // Top edge
    path.lineTo(rect.right - effectiveStep, rect.top);

    // Top-right staircase (descends, then runs right — repeated)
    var x = rect.right - effectiveStep;
    var y = rect.top;
    for (var i = 0; i < stepCount; i++) {
      y += unit;
      path.lineTo(x, y);
      x += unit;
      path.lineTo(x, y);
    }

    // Right edge
    path.lineTo(rect.right, rect.bottom - effectiveStep);

    // Bottom-right staircase (runs left, then descends — repeated)
    x = rect.right;
    y = rect.bottom - effectiveStep;
    for (var i = 0; i < stepCount; i++) {
      x -= unit;
      path.lineTo(x, y);
      y += unit;
      path.lineTo(x, y);
    }

    // Bottom edge
    path.lineTo(rect.left + effectiveStep, rect.bottom);

    // Bottom-left staircase (ascends, then runs left — repeated)
    x = rect.left + effectiveStep;
    y = rect.bottom;
    for (var i = 0; i < stepCount; i++) {
      y -= unit;
      path.lineTo(x, y);
      x -= unit;
      path.lineTo(x, y);
    }

    // Left edge
    path.lineTo(rect.left, rect.top + effectiveStep);

    // Top-left staircase (runs right, then ascends — repeated)
    x = rect.left;
    y = rect.top + effectiveStep;
    for (var i = 0; i < stepCount; i++) {
      x += unit;
      path.lineTo(x, y);
      y -= unit;
      path.lineTo(x, y);
    }

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
        stepCount: t < 0.5 ? a.stepCount : stepCount,
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
        stepCount: t < 0.5 ? stepCount : b.stepCount,
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
        other.stepSize == stepSize &&
        other.stepCount == stepCount;
  }

  @override
  int get hashCode => Object.hash(side, stepSize, stepCount);
}
