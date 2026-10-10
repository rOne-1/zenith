import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../theme/district_background_media.dart';
import '../theme/test_env/test_env.dart';
import '../theme/theme.dart';

/// Shared video controller, keyed by asset path, for any district backdrop
/// backed by [DistrictVideoBackground]. Keyed sharing (rather than one
/// controller per district) means every consumer of the same asset --
/// including a screen that's only incidentally co-mounted, e.g. a pushed
/// route sitting on top of a still-mounted caller -- reads the exact same
/// decoder instead of spawning a competing one. `autoDispose` keeps this
/// lazy and alive only while something is actually watching it.
final districtVideoControllerProvider = Provider.autoDispose
    .family<VideoPlayerController?, String>((ref, assetPath) {
      // video_player has no registered platform implementation under
      // `flutter test` (and no Windows or Linux desktop implementation in
      // pubspec.yaml), so guard both instead of letting either hang or crash
      // the widget tree with MissingPluginException.
      if (isTestEnvironment ||
          (!kIsWeb && (io.Platform.isWindows || io.Platform.isLinux))) {
        return null;
      }
      try {
        final controller = VideoPlayerController.asset(assetPath)
          ..setLooping(true)
          ..setVolume(0);
        // play() must wait for initialize() to actually resolve -- calling
        // it immediately races the controller's own setup and can leave
        // the player silently stalled on an unpopulated frame.
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

/// Renders whichever [DistrictBackgroundMedia] a district declares --
/// image or video -- as a single cover-fit layer. Callers should mount
/// this (indirectly, via a district's atmosphere backdrop) only once per
/// simultaneously-visible asset; see [districtVideoControllerProvider]'s
/// doc for why co-mounting more than one consumer of the same video is
/// still something to avoid even though the controller itself is shared.
class DistrictBackgroundMediaLayer extends ConsumerWidget {
  final DistrictBackgroundMedia media;

  /// Fallback/loading color shown before a video has decoded its first
  /// frame, or when video playback isn't available on this platform.
  final Color placeholderColor;

  const DistrictBackgroundMediaLayer({
    super.key,
    required this.media,
    this.placeholderColor = const Color(0xFF070E10),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (media) {
      DistrictImageBackground(:final assetPath) => Image.asset(
        assetPath,
        fit: BoxFit.cover,
      ),
      DistrictVideoBackground(:final assetPath) => _VideoLayer(
        assetPath: assetPath,
        placeholderColor: placeholderColor,
      ),
    };
  }
}

class _VideoLayer extends ConsumerWidget {
  final String assetPath;
  final Color placeholderColor;

  const _VideoLayer({required this.assetPath, required this.placeholderColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(districtVideoControllerProvider(assetPath));

    if (controller == null) {
      return ColoredBox(color: placeholderColor);
    }

    final disabled = context.animationsDisabled;
    if (controller.value.isInitialized) {
      if (disabled && controller.value.isPlaying) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.value.isPlaying) {
            controller.pause();
          }
        });
      } else if (!disabled && !controller.value.isPlaying) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller.value.isPlaying) {
            controller.play();
          }
        });
      }
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.value.isInitialized) {
          return ColoredBox(color: placeholderColor);
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
    );
  }
}
