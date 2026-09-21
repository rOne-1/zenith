import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/test_env/test_env.dart';
import '../../../core/widgets/pixel_scanline_overlay.dart';

/// The atmospheric background scene for District 02: "Neon Alleys" --
/// a looping muted video of the reference art (a rain-slicked, neon-signed
/// back-alley stairwell) instead of a procedurally painted scene. First cut
/// of this district: same palette as District 01 for now (see
/// `neon_alleys_palette.dart`), just a different backdrop.
class NeonAlleysAtmosphereBackdrop extends StatefulWidget {
  final Widget? child;

  const NeonAlleysAtmosphereBackdrop({super.key, this.child});

  @override
  State<NeonAlleysAtmosphereBackdrop> createState() =>
      _NeonAlleysAtmosphereBackdropState();
}

class _NeonAlleysAtmosphereBackdropState
    extends State<NeonAlleysAtmosphereBackdrop> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    // video_player has no registered platform implementation under
    // `flutter test` (and no Windows-desktop implementation at all), so
    // guard both instead of letting either hang or crash the widget tree --
    // same guard shape as the breathing lamp glow's isTestEnvironment check
    // in RailsideAtmosphereBackdrop, plus a try/catch for the unsupported
    // -platform case a plain flag can't cover.
    if (isTestEnvironment) return;
    try {
      final controller = VideoPlayerController.asset(
        'assets/backgrounds/neon_alleys_loop.mp4',
      );
      _controller = controller;
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        }, onError: (_) {})
        ..play();
    } catch (_) {
      // Falls back to the static ColoredBox in build() below.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final videoReady = controller != null && controller.value.isInitialized;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The looping video, or a plain dark fallback while it loads
          // (or on a platform/test environment without video support).
          if (videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            const ColoredBox(color: Color(0xFF070E10)),

          // 2. A scrim so foreground text/cards stay legible over the
          // busy, high-contrast footage -- same treatment the temporary
          // still-image experiment used.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0x66070E10)),
            ),
          ),

          // 3. Analog film grain / CRT noise overlay for retro texture depth
          const Positioned.fill(
            child: NoiseGrainOverlay(opacity: 0.03, tint: Color(0xFF162B2B)),
          ),

          // 4. Hard scanlines -- the other half of the CRT texture, sitting
          // over the atmosphere but under actual screen content.
          const Positioned.fill(
            child: IgnorePointer(child: PixelScanlineOverlay()),
          ),

          // 5. Foreground content if provided
          ?widget.child,
        ],
      ),
    );
  }
}
