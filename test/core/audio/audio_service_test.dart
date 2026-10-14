import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/audio/audio.dart';
import 'package:zenith/core/storage/storage.dart';
import 'package:zenith/features/armory/armory.dart';
import 'package:zenith/features/onboarding/providers/onboarding_provider.dart';
import 'package:zenith/main.dart';

class _RecordingAudioService implements AudioService {
  final List<AudioCue> playedCues = <AudioCue>[];
  bool isInitialized = false;
  bool isPreloaded = false;
  bool isWebAudioUnlocked = false;
  bool isDisposed = false;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<void> playCue(AudioCue cue) async {
    playedCues.add(cue);
  }

  @override
  Future<void> preloadAll() async {
    isPreloaded = true;
  }

  @override
  void unlockWebAudio() {
    isWebAudioUnlocked = true;
  }

  @override
  void dispose() {
    isDisposed = true;
  }
}

void main() {
  group('AudioCue Enum', () {
    test('declares all 4 canonical 16-bit arcade cues with asset paths', () {
      expect(AudioCue.values, hasLength(4));
      expect(AudioCue.tick.assetPath, 'audio/tick.wav');
      expect(AudioCue.start.assetPath, 'audio/start.wav');
      expect(AudioCue.rest.assetPath, 'audio/rest.wav');
      expect(AudioCue.complete.assetPath, 'audio/complete.wav');
    });
  });

  group('NoOpAudioService', () {
    test(
      'safely executes all contract methods with zero-throw semantics',
      () async {
        const service = NoOpAudioService();
        await expectLater(service.initialize(), completes);
        await expectLater(service.preloadAll(), completes);
        await expectLater(service.playCue(AudioCue.tick), completes);
        expect(service.unlockWebAudio, returnsNormally);
        expect(service.dispose, returnsNormally);
      },
    );
  });

  group('audioServiceProvider', () {
    test(
      'automatically resolves to NoOpAudioService under test environment',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(audioServiceProvider);
        expect(service, isA<NoOpAudioService>());
      },
    );

    test('cleanly supports test double overrides', () async {
      final mock = _RecordingAudioService();
      final container = ProviderContainer(
        overrides: [audioServiceProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      final service = container.read(audioServiceProvider);
      expect(service, same(mock));

      await service.playCue(AudioCue.start);
      expect(mock.playedCues, [AudioCue.start]);
    });
  });

  group('ZenithApp Web Audio Gesture Unlock', () {
    testWidgets('triggers unlockWebAudio on first pointer down', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        kHasCompletedOnboardingKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final mockAudio = _RecordingAudioService();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioServiceProvider.overrideWithValue(mockAudio),
          userProfileProvider.overrideWith((ref) => UserProfileNotifier(prefs)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ZenithApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(mockAudio.isWebAudioUnlocked, isFalse);

      // Simulate first user touch/tap anywhere on screen
      final gesture = await tester.createGesture();
      await gesture.down(const Offset(100, 100));
      await gesture.up();
      await tester.pump();

      expect(mockAudio.isWebAudioUnlocked, isTrue);
    });
  });
}
