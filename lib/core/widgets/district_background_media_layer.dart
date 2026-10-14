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
        // On web, volume and looping must be explicitly configured after
        // initialization because video_player ignores calls prior to
        // initialization. Setting volume to 0 (muting) is strictly required
        // before play() to satisfy Chrome's Autoplay Policy without prior
        // user interaction.
        controller
            .initialize()
            .then((_) async {
              await controller.setLooping(true);
              await controller.setVolume(0);
              return controller.play();
            })
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

class _VideoLayer extends ConsumerStatefulWidget {
  final String assetPath;
  final Color placeholderColor;

  const _VideoLayer({
    required this.assetPath,
    required this.placeholderColor,
  });

  @override
  ConsumerState<_VideoLayer> createState() => _VideoLayerState();
}

class _VideoLayerState extends ConsumerState<_VideoLayer> {
  VideoPlayerController? _controller;
  bool? _lastAnimationsDisabled;

  @override
  void initState() {
    super.initState();
    _attachController(ref.read(districtVideoControllerProvider(widget.assetPath)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = context.animationsDisabled;
    if (_lastAnimationsDisabled != disabled) {
      _lastAnimationsDisabled = disabled;
      _syncPlaybackWithMotion();
    }
  }

  @override
  void didUpdateWidget(covariant _VideoLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assetPath != oldWidget.assetPath) {
      _detachController();
      _attachController(ref.read(districtVideoControllerProvider(widget.assetPath)));
      _syncPlaybackWithMotion();
    }
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  void _attachController(VideoPlayerController? controller) {
    _controller = controller;
    _controller?.addListener(_onControllerValueChanged);
  }

  void _detachController() {
    _controller?.removeListener(_onControllerValueChanged);
    _controller = null;
  }

  void _onControllerValueChanged() {
    if (!mounted || _controller == null) return;
    if (!_controller!.value.isInitialized) return;
    final disabled = context.animationsDisabled;
    if (disabled && _controller!.value.isPlaying) {
      _controller!.pause().catchError((_) {});
    }
  }

  void _syncPlaybackWithMotion() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final disabled = _lastAnimationsDisabled ?? context.animationsDisabled;
    if (disabled && controller.value.isPlaying) {
      controller.pause().catchError((_) {});
    } else if (!disabled && !controller.value.isPlaying) {
      controller.play().catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VideoPlayerController?>(
      districtVideoControllerProvider(widget.assetPath),
      (previous, next) {
        if (_controller != next) {
          _detachController();
          _attachController(next);
          _syncPlaybackWithMotion();
        }
      },
    );

    final controller = _controller ?? ref.watch(districtVideoControllerProvider(widget.assetPath));

    if (controller == null) {
      return ColoredBox(color: widget.placeholderColor);
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.value.isInitialized) {
          return ColoredBox(color: widget.placeholderColor);
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
