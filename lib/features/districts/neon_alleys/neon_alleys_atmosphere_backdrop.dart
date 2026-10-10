import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/test_env/test_env.dart';
import '../../../core/widgets/pixel_scanline_overlay.dart';

/// Single shared video controller for the Neon Alleys loop -- every screen
/// using [NeonAlleysAtmosphereBackdrop] reads from this ONE controller
/// instead of creating its own.
///
/// `IndexedStack` keeps Outpost/Atlas/Depot/Sanctuary mounted at the same
/// time for the app's whole lifetime, and all 4 rebuild together on every
/// theme switch -- so a per-widget controller meant 4 simultaneous decoders
/// for the same asset the moment Neon Alleys was selected. Only one (the
/// visible one) actually played; the rest silently stalled on their first
/// decoded frame, which is exactly why the backdrop read as a static image
/// on every screen except whichever one happened to be active. `autoDispose`
/// keeps this lazy (never created while the active theme is Railside) and
/// alive for as long as any screen is actually watching it, without needing
/// an explicit keepAlive -- the IndexedStack tabs alone are permanent
/// watchers whenever Neon Alleys is selected.
final neonAlleysVideoControllerProvider =
    Provider.autoDispose<VideoPlayerController?>((ref) {
      // video_player has no registered platform implementation under
      // `flutter test` (and no Windows-desktop implementation at all), so
      // guard both instead of letting either hang or crash the widget tree.
      if (isTestEnvironment) return null;
      try {
        final controller =
            VideoPlayerController.asset(
                'assets/backgrounds/neon_alleys_loop.mp4',
              )
              ..setLooping(true)
              ..setVolume(0);
        // play() must wait for initialize() to actually resolve -- calling
        // it immediately races the controller's own setup (video_player_web
        // in particular won't have a populated platform view yet) and can
        // leave the player silently stalled on an unpopulated frame.
        controller
            .initialize()
            .then((_) => controller.play())
            .catchError((_) {});
        ref.onDispose(controller.dispose);
        return controller;
      } catch (_) {
        return null;
      }
    });

/// The atmospheric background scene for District 02: "Neon Alleys" --
/// a looping muted video of the reference art (a rain-slicked, neon-signed
/// back-alley stairwell) instead of a procedurally painted scene. First cut
/// of this district: same palette as District 01 for now (see
/// `neon_alleys_palette.dart`), just a different backdrop.
class NeonAlleysAtmosphereBackdrop extends ConsumerWidget {
  final Widget? child;

  const NeonAlleysAtmosphereBackdrop({super.key, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(neonAlleysVideoControllerProvider);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The shared looping video, or a plain dark fallback while it
          // loads (or on a platform/test environment without video support).
          if (controller != null)
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (!controller.value.isInitialized) {
                  return const ColoredBox(color: Color(0xFF070E10));
                }
                return FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                );
              },
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
          ?child,
        ],
      ),
    );
  }
}
