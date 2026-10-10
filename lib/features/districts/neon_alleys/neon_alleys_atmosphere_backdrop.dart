import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import '../../../core/theme/district_background_media.dart';
import '../../../core/widgets/district_background_media_layer.dart';
import '../../../core/widgets/pixel_scanline_overlay.dart';

/// Neon Alleys' backdrop media. Currently a placeholder video of the
/// reference art while final art is commissioned -- swapping this to
/// `DistrictImageBackground('assets/backgrounds/neon_alleys_still.png')`
/// (or to a different video asset later) is the entire change needed,
/// since [DistrictBackgroundMediaLayer] renders either kind identically.
const DistrictBackgroundMedia _neonAlleysBackgroundMedia =
    DistrictVideoBackground('assets/backgrounds/neon_alleys_loop.mp4');

/// The atmospheric background scene for District 02: "Neon Alleys" --
/// temporary placeholder media (see [_neonAlleysBackgroundMedia]) of the
/// reference art (a rain-slicked, neon-signed back-alley stairwell)
/// instead of a procedurally painted scene. First cut of this district:
/// same palette as District 01 for now (see `neon_alleys_palette.dart`),
/// just a different backdrop.
class NeonAlleysAtmosphereBackdrop extends StatelessWidget {
  final Widget? child;

  const NeonAlleysAtmosphereBackdrop({super.key, this.child});

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
              // 1. The district's backdrop media (image or video).
              Positioned.fill(
                child: DistrictBackgroundMediaLayer(
                  media: _neonAlleysBackgroundMedia,
                ),
              ),

              // 2. A scrim so foreground text/cards stay legible over the
              // busy, high-contrast footage -- same treatment the temporary
              // still-image experiment used.
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
