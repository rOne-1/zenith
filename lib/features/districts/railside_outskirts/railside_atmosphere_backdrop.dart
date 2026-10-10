import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import '../../../core/widgets/pixel_scanline_overlay.dart';

/// The atmospheric background scene for District 01: "Railside Outskirts" --
/// the illustrated reference art itself (a train arriving trackside at
/// night, overhead catenary wires, a red destination board, windblown
/// trackside foliage), not a procedural approximation of it. Same treatment
/// as District 02's NeonAlleysAtmosphereBackdrop: full-bleed art, a scrim
/// for foreground legibility, then the shared grain/scanline texture.
class RailsideAtmosphereBackdrop extends StatelessWidget {
  final Widget? child;

  const RailsideAtmosphereBackdrop({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background atmosphere layers isolated in their own RepaintBoundary
        // so that foreground animations, timer ticks, and scroll events do
        // not invalidate the expensive rasterization of the art, scrim, grain,
        // and scanline overlays.
        const RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. The illustrated reference art
              Positioned.fill(
                child: Image(
                  image: AssetImage(
                    'assets/backgrounds/railside_outskirts_illustration.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),

              // 2. A scrim so foreground text/cards stay legible over the
              // busy, high-contrast art.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x66070E10)),
                ),
              ),

              // 3. Analog film grain / CRT noise overlay for retro texture depth
              Positioned.fill(
                child: NoiseGrainOverlay(opacity: 0.03, tint: Color(0xFF162B2B)),
              ),

              // 4. Hard scanlines -- the other half of the CRT texture, sitting
              // over the atmosphere but under actual screen content.
              Positioned.fill(
                child: IgnorePointer(child: PixelScanlineOverlay()),
              ),
            ],
          ),
        ),

        // 5. Foreground content if provided (mounted outside the background repaint boundary)
        ?child,
      ],
    );
  }
}
