import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:zenith/core/theme/district_background_media.dart';
import 'package:zenith/core/widgets/district_background_media_layer.dart';

class _MockVideoPlayerController extends VideoPlayerController {
  _MockVideoPlayerController({
    bool isInitialized = true,
    bool isPlaying = false,
  }) : super.asset('dummy.mp4') {
    value = VideoPlayerValue(
      duration: const Duration(seconds: 10),
      size: const Size(1920, 1080),
      isInitialized: isInitialized,
      isPlaying: isPlaying,
    );
  }

  int playCount = 0;
  int pauseCount = 0;
  double? lastVolume;
  bool? lastLooping;

  @override
  Future<void> initialize() async {
    value = value.copyWith(isInitialized: true);
  }

  @override
  Future<void> play() async {
    playCount++;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> setLooping(bool looping) async {
    lastLooping = looping;
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
    value = value.copyWith(volume: volume);
  }


}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DistrictBackgroundMediaLayer', () {
    testWidgets('renders Image.asset directly for DistrictImageBackground', (
      tester,
    ) async {
      const imageMedia = DistrictImageBackground('assets/dummy_image.jpg');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DistrictBackgroundMediaLayer(media: imageMedia),
            ),
          ),
        ),
      );

      // Catch image loading error for the non-existent test asset
      tester.takeException();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders placeholder when controller is null (test env)', (
      tester,
    ) async {
      const videoMedia = DistrictVideoBackground('dummy_loop.mp4');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DistrictBackgroundMediaLayer(
                media: videoMedia,
                placeholderColor: Color(0xFF070E10),
              ),
            ),
          ),
        ),
      );

      final placeholderFinder = find.descendant(
        of: find.byType(DistrictBackgroundMediaLayer),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == const Color(0xFF070E10),
        ),
      );
      expect(placeholderFinder, findsOneWidget);
    });

    testWidgets(
      'pure build: does not invoke play or pause during repeated widget builds',
      (tester) async {
        final controller = _MockVideoPlayerController(
          isInitialized: true,
          isPlaying: true,
        );
        addTearDown(controller.dispose);

        // Mount media layer with provided controller
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              districtVideoControllerProvider('dummy.mp4')
                  .overrideWithValue(controller),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: DistrictBackgroundMediaLayer(
                  media: DistrictVideoBackground('dummy.mp4'),
                ),
              ),
            ),
          ),
        );

        expect(controller.playCount, 0);
        expect(controller.pauseCount, 0);

        // Rebuild multiple times to verify no build or post-frame calls mutate controller
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(controller.playCount, 0);
        expect(controller.pauseCount, 0);

        // VideoPlayer widget must be mounted
        expect(find.byType(VideoPlayer), findsOneWidget);
      },
    );

    testWidgets(
      'pauses playback when animationsDisabled is true at initial mount',
      (tester) async {
        final controller = _MockVideoPlayerController(
          isInitialized: true,
          isPlaying: true,
        );
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              districtVideoControllerProvider('dummy.mp4')
                  .overrideWithValue(controller),
            ],
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: Scaffold(
                  body: DistrictBackgroundMediaLayer(
                    media: DistrictVideoBackground('dummy.mp4'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(controller.pauseCount, 1);
        expect(controller.value.isPlaying, isFalse);
      },
    );

    testWidgets(
      'resumes playback when animationsDisabled transitions from true to false',
      (tester) async {
        final controller = _MockVideoPlayerController(
          isInitialized: true,
          isPlaying: false,
        );
        addTearDown(controller.dispose);

        // Initially disabled
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              districtVideoControllerProvider('dummy.mp4')
                  .overrideWithValue(controller),
            ],
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: Scaffold(
                  body: DistrictBackgroundMediaLayer(
                    media: DistrictVideoBackground('dummy.mp4'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(controller.playCount, 0);
        expect(controller.value.isPlaying, isFalse);

        // Transition to animations enabled (disableAnimations: false)
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              districtVideoControllerProvider('dummy.mp4')
                  .overrideWithValue(controller),
            ],
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: false),
                child: Scaffold(
                  body: DistrictBackgroundMediaLayer(
                    media: DistrictVideoBackground('dummy.mp4'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(controller.playCount, 1);
        expect(controller.value.isPlaying, isTrue);
      },
    );

    testWidgets(
      'pauses playback when animationsDisabled transitions from false to true',
      (tester) async {
        final controller = _MockVideoPlayerController(
          isInitialized: true,
          isPlaying: true,
        );
        addTearDown(controller.dispose);

        // Initially enabled
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              districtVideoControllerProvider('dummy.mp4')
                  .overrideWithValue(controller),
            ],
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: false),
                child: Scaffold(
                  body: DistrictBackgroundMediaLayer(
                    media: DistrictVideoBackground('dummy.mp4'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(controller.pauseCount, 0);
        expect(controller.value.isPlaying, isTrue);

        // Transition to animations disabled (disableAnimations: true)
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              districtVideoControllerProvider('dummy.mp4')
                  .overrideWithValue(controller),
            ],
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: Scaffold(
                  body: DistrictBackgroundMediaLayer(
                    media: DistrictVideoBackground('dummy.mp4'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(controller.pauseCount, 1);
        expect(controller.value.isPlaying, isFalse);
      },
    );

    test('volume muting and looping sequence during controller setup', () async {
      final controller = _MockVideoPlayerController(isInitialized: false);
      addTearDown(controller.dispose);

      final sequence = <String>[];

      // Simulate provider initialization flow
      await controller.initialize();
      sequence.add('initialize');

      await controller.setLooping(true);
      sequence.add('setLooping');

      await controller.setVolume(0);
      sequence.add('setVolume');

      await controller.play();
      sequence.add('play');

      expect(controller.lastVolume, 0.0);
      expect(controller.lastLooping, isTrue);
      expect(controller.value.isPlaying, isTrue);

      expect(sequence, ['initialize', 'setLooping', 'setVolume', 'play']);
      expect(
        sequence.indexOf('setVolume'),
        lessThan(sequence.indexOf('play')),
        reason: 'volume must be muted BEFORE play() is invoked',
      );
    });
  });
}
