import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

/// The atmospheric background scene for District 01: "Railside Outskirts" (郊外の線路).
///
/// Evokes suburban Japanese rail corridors at midnight: quiet dark skies, distant
/// misty cityscape silhouettes, overhead catenary wire silhouettes, warm amber
/// streetlight glow pools on the ground, and windblown trackside grass.
class RailsideAtmosphereBackdrop extends StatelessWidget {
  final Widget? child;

  const RailsideAtmosphereBackdrop({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep atmospheric gradient: void black to misty skyline and ground
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF070E10), // backgroundVoid
                  Color(0xFF162B2B), // mid-atmosphere
                  Color(0xFF264947), // skylineMist
                  Color(0xFF0C181A), // surfaceDark (ground ballast)
                ],
                stops: [0.0, 0.42, 0.72, 1.0],
              ),
            ),
          ),

          // 2. Warm amber streetlight radial glow pool resting on the ground
          Positioned(
            left: -40,
            right: -40,
            bottom: -50,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.15, 0.25),
                    radius: 0.85,
                    colors: [
                      const Color(0xFFFFAE34).withValues(alpha: 0.16),
                      const Color(0xFFFFD269).withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Custom painted railway catenary overhead wires and trackside grass
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _RailCatenaryPainter()),
            ),
          ),

          // 4. Analog film grain / CRT noise overlay for retro texture depth
          const Positioned.fill(
            child: NoiseGrainOverlay(opacity: 0.03, tint: Color(0xFF162B2B)),
          ),

          // 5. Foreground content if provided
          ?child,
        ],
      ),
    );
  }
}

class _RailCatenaryPainter extends CustomPainter {
  const _RailCatenaryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final width = size.width;
    final height = size.height;

    // --- OVERHEAD CATENARY WIRES & POLE SILHOUETTE ---
    final cablePaint = Paint()
      ..color = const Color(0xFF1A3332).withValues(alpha: 0.75)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Upper contact wire with gentle catenary sag
    final upperCable = Path()
      ..moveTo(0, height * 0.08)
      ..quadraticBezierTo(width * 0.5, height * 0.11, width, height * 0.07);
    canvas.drawPath(upperCable, cablePaint);

    // Lower messenger wire
    final lowerCable = Path()
      ..moveTo(0, height * 0.13)
      ..quadraticBezierTo(width * 0.55, height * 0.15, width, height * 0.12);
    canvas.drawPath(lowerCable, cablePaint);

    // Minimal catenary dropper wires (vertical ties between cables)
    final dropperPaint = Paint()
      ..color = const Color(0xFF1A3332).withValues(alpha: 0.50)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double xFrac = 0.18; xFrac < 0.90; xFrac += 0.22) {
      final x = width * xFrac;
      final y1 = height * (0.08 + 0.03 * math.sin(xFrac * math.pi));
      final y2 = height * (0.13 + 0.02 * math.sin(xFrac * math.pi));
      canvas.drawLine(Offset(x, y1), Offset(x, y2), dropperPaint);
    }

    // Overhead gantry bracket arm on the left side
    final gantryPaint = Paint()
      ..color = const Color(0xFF152B2C).withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final gantryArm = Path()
      ..moveTo(0, height * 0.05)
      ..lineTo(width * 0.14, height * 0.06)
      ..lineTo(width * 0.14, height * 0.14)
      ..lineTo(0, height * 0.15);
    canvas.drawPath(gantryArm, gantryPaint);

    // Hanging street lamp silhouette bracket on the upper left
    final lampBracketPaint = Paint()
      ..color = const Color(0xFF152B2C)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(width * 0.14, height * 0.06),
      Offset(width * 0.18, height * 0.08),
      lampBracketPaint,
    );
    canvas.drawLine(
      Offset(width * 0.18, height * 0.08),
      Offset(width * 0.18, height * 0.11),
      lampBracketPaint,
    );

    // Streetlight lamp head cowl
    final lampHead = Paint()
      ..color = const Color(0xFF152B2C)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(width * 0.18, height * 0.11),
        width: 10,
        height: 4,
      ),
      lampHead,
    );

    // Subtle streetlight filament point
    final filamentPaint = Paint()
      ..color = const Color(0xFFFFD269).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.18, height * 0.115), 1.5, filamentPaint);

    // --- DISTANT METROPOLITAN SILHOUETTES (HORIZON) ---
    final skylinePaint = Paint()
      ..color = const Color(0xFF152B2C).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final horizonY = height * 0.74;
    final skyline = Path()..moveTo(0, horizonY);
    skyline.lineTo(width * 0.08, horizonY - 14);
    skyline.lineTo(width * 0.14, horizonY - 14);
    skyline.lineTo(width * 0.14, horizonY - 8);
    skyline.lineTo(width * 0.22, horizonY - 8);
    skyline.lineTo(width * 0.22, horizonY - 22);
    skyline.lineTo(width * 0.30, horizonY - 22);
    skyline.lineTo(width * 0.30, horizonY);
    skyline.lineTo(width * 0.44, horizonY);
    skyline.lineTo(width * 0.44, horizonY - 18);
    skyline.lineTo(width * 0.52, horizonY - 18);
    skyline.lineTo(width * 0.52, horizonY - 30);
    skyline.lineTo(width * 0.58, horizonY - 30);
    skyline.lineTo(width * 0.58, horizonY);
    skyline.lineTo(width * 0.72, horizonY);
    skyline.lineTo(width * 0.72, horizonY - 12);
    skyline.lineTo(width * 0.82, horizonY - 12);
    skyline.lineTo(width * 0.82, horizonY);
    skyline.lineTo(width, horizonY);
    skyline.lineTo(width, height);
    skyline.lineTo(0, height);
    skyline.close();
    canvas.drawPath(skyline, skylinePaint);

    // --- TRACKSIDE BALLAST GROUND LINE ---
    final groundPaint = Paint()
      ..color = const Color(0xFF0C181A)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, height - 28, width, 28), groundPaint);

    final ballastLine = Paint()
      ..color = const Color(0xFF1A3332)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, height - 28),
      Offset(width, height - 28),
      ballastLine,
    );

    // --- WINDBLOWN TRACKSIDE WEEDS & GRASS CLUSTERS ---
    final deepFoliage = Paint()
      ..color = const Color(0xFF224231)
      ..style = PaintingStyle.fill;
    final vibrantFoliage = Paint()
      ..color = const Color(0xFF4B8E62)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Grass clumps along the bottom right and left
    _drawGrassCluster(
      canvas,
      Offset(width * 0.05, height - 28),
      deepFoliage,
      vibrantFoliage,
    );
    _drawGrassCluster(
      canvas,
      Offset(width * 0.22, height - 28),
      deepFoliage,
      vibrantFoliage,
    );
    _drawGrassCluster(
      canvas,
      Offset(width * 0.68, height - 28),
      deepFoliage,
      vibrantFoliage,
    );
    _drawGrassCluster(
      canvas,
      Offset(width * 0.85, height - 28),
      deepFoliage,
      vibrantFoliage,
    );
  }

  void _drawGrassCluster(
    Canvas canvas,
    Offset origin,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    // Stepped windblown tufts leaning right
    final tuft = Path()
      ..moveTo(origin.dx - 6, origin.dy)
      ..lineTo(origin.dx - 2, origin.dy - 12)
      ..lineTo(origin.dx + 4, origin.dy - 16)
      ..lineTo(origin.dx + 2, origin.dy - 6)
      ..lineTo(origin.dx + 10, origin.dy - 14)
      ..lineTo(origin.dx + 8, origin.dy)
      ..close();
    canvas.drawPath(tuft, fillPaint);

    // Slender windblown blade highlights
    canvas.drawLine(
      Offset(origin.dx - 1, origin.dy),
      Offset(origin.dx + 6, origin.dy - 18),
      strokePaint,
    );
    canvas.drawLine(
      Offset(origin.dx + 4, origin.dy),
      Offset(origin.dx + 13, origin.dy - 13),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
