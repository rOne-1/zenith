import 'package:flutter/material.dart';

/// Hard horizontal scanlines layered over a screen's backdrop -- the other
/// half of the CRT-terminal texture alongside grain (`NoiseGrainOverlay`,
/// from `flutter_refined_kit`, already used in `RailsideAtmosphereBackdrop`).
/// Static, non-interactive, and painted once (`shouldRepaint` is always
/// false) -- this is atmosphere, not an animated effect.
///
/// Defaults are a starting point tuned down from the design correction's
/// literal spec (1px lines every 3px at 35% black) since that read as too
/// heavy against this app's actual body-copy density; verify legibility
/// live on text-dense screens before changing the defaults again.
class PixelScanlineOverlay extends StatelessWidget {
  /// Vertical distance between the start of one line and the next.
  final double pitch;

  /// Opacity of each 1px black line.
  final double lineOpacity;

  const PixelScanlineOverlay({
    super.key,
    this.pitch = 3.0,
    this.lineOpacity = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanlinePainter(pitch: pitch, lineOpacity: lineOpacity),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double pitch;
  final double lineOpacity;

  const _ScanlinePainter({required this.pitch, required this.lineOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: lineOpacity);
    for (double y = 0; y < size.height; y += pitch) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) =>
      oldDelegate.pitch != pitch || oldDelegate.lineOpacity != lineOpacity;
}
