import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';
import '../theme/theme.dart';
import 'stepped_pixel_border.dart';

/// Style variants for [PixelButton].
enum PixelButtonVariant {
  /// Amber/gold hero CTA.
  primary,

  /// Dark slate elevated button for secondary actions.
  secondary,

  /// Signal red for destructive or warning actions.
  danger,
}

/// An authentic retro mechanical arcade button featuring stepped corners,
/// a 1-frame physical drop on tap, and damped [HouseSpring] rebound.
class PixelButton extends StatefulWidget {
  final String? label;
  final Widget? child;
  final Widget? icon;
  final VoidCallback? onPressed;
  final PixelButtonVariant variant;
  final bool enabled;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? buttonDropOffset;
  final double? bevelDepth;
  final double? cornerStepSize;

  /// Accessible name announced by screen readers. Defaults to [label] when
  /// omitted, since a text-label button's visible text already doubles as
  /// its accessible name -- but an icon-only button (built via [child],
  /// with no [label]) has no text for [Semantics] to fall back on, so
  /// callers using [child] alone must supply this explicitly or the button
  /// is announced with no name at all.
  final String? semanticLabel;

  const PixelButton({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.onPressed,
    this.variant = PixelButtonVariant.primary,
    this.enabled = true,
    this.width,
    this.height,
    this.padding,
    this.buttonDropOffset,
    this.bevelDepth,
    this.cornerStepSize,
    this.semanticLabel,
  }) : assert(
         label != null || child != null,
         'Either label or child must be provided to PixelButton',
       );

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  bool get _isInteractive => widget.enabled && widget.onPressed != null;

  void _handleTapDown(TapDownDetails details) {
    if (!_isInteractive) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isInteractive) return;
    setState(() {
      _isPressed = false;
    });
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!_isInteractive) return;
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;

    final dropOffset = widget.buttonDropOffset ?? metrics.buttonDropOffset;
    final bevelDepth = widget.bevelDepth ?? metrics.bevelDepth;
    final stepSize = widget.cornerStepSize ?? metrics.cornerStepSize;
    final borderWidth = metrics.borderWidth;

    Color backgroundColor;
    Color textColor;
    Color borderColor;
    Color bevelColor;

    if (!_isInteractive) {
      backgroundColor = colors.surfaceDark;
      textColor = colors.textMuted;
      borderColor = colors.borderMuted;
      bevelColor = colors.backgroundVoid;
    } else {
      switch (widget.variant) {
        case PixelButtonVariant.primary:
          backgroundColor = colors.amberAccent;
          textColor = colors.backgroundVoid;
          borderColor = colors.amberGlow;
          bevelColor = const Color(0xFFB37410);
          break;
        case PixelButtonVariant.secondary:
          backgroundColor = colors.surfaceElevated;
          textColor = colors.textPrimary;
          borderColor = colors.borderBright;
          bevelColor = colors.surfaceDark;
          break;
        case PixelButtonVariant.danger:
          backgroundColor = colors.signalRed;
          textColor = colors.textPrimary;
          borderColor = const Color(0xFFFF7A6E);
          bevelColor = const Color(0xFF8B1810);
          break;
      }
    }

    final currentDrop = _isPressed ? dropOffset : 0.0;
    final currentBevel = math.max(1.0, bevelDepth - currentDrop);

    Widget content =
        widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: 8.0),
            ],
            Flexible(
              child: Text(
                widget.label ?? '',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.0,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

    final effectivePadding =
        widget.padding ??
        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);

    return Semantics(
      button: true,
      enabled: _isInteractive,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: _isPressed
              ? const Duration(milliseconds: 60)
              : HouseSpring.duration,
          curve: HouseSpring.curve,
          child: SizedBox(
            width: widget.width,
            height: widget.height != null ? widget.height! + bevelDepth : null,
            child: CustomPaint(
              painter: _PixelButtonPainter(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                bevelColor: bevelColor,
                borderWidth: borderWidth,
                stepSize: stepSize,
                bevelDepth: currentBevel,
                dropOffset: currentDrop,
              ),
              child: Padding(
                padding: effectivePadding.add(
                  EdgeInsets.only(top: currentDrop, bottom: currentBevel),
                ),
                child: Center(
                  widthFactor: widget.width != null ? null : 1.0,
                  heightFactor: 1.0,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelButtonPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final Color bevelColor;
  final double borderWidth;
  final double stepSize;
  final double bevelDepth;
  final double dropOffset;

  _PixelButtonPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.bevelColor,
    required this.borderWidth,
    required this.stepSize,
    required this.bevelDepth,
    required this.dropOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final border = SteppedPixelBorder(
      side: BorderSide(color: borderColor, width: borderWidth),
      stepSize: stepSize,
    );

    // Bevel shadow behind
    if (bevelDepth > 0) {
      final shadowRect = Rect.fromLTWH(
        0,
        dropOffset + bevelDepth,
        size.width,
        size.height - dropOffset - bevelDepth,
      );
      final shadowPath = border.getOuterPath(shadowRect);
      final shadowPaint = Paint()
        ..color = bevelColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // Button face
    final faceRect = Rect.fromLTWH(
      0,
      dropOffset,
      size.width,
      size.height - dropOffset - bevelDepth,
    );
    final facePath = border.getOuterPath(faceRect);
    final facePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(facePath, facePaint);

    border.paint(canvas, faceRect);
  }

  @override
  bool shouldRepaint(covariant _PixelButtonPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.bevelColor != bevelColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.stepSize != stepSize ||
        oldDelegate.bevelDepth != bevelDepth ||
        oldDelegate.dropOffset != dropOffset;
  }
}
