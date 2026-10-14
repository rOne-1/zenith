import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/audio/audio.dart';
import 'package:zenith/core/storage/storage.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/expedition/controllers/active_session_controller.dart';

class _RecordingAudioService implements AudioService {
  final List<AudioCue> playedCues = <AudioCue>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> preloadAll() async {}

  @override
  Future<void> playCue(AudioCue cue) async {
    playedCues.add(cue);
  }

  @override
  void unlockWebAudio() {}

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Workout FSM & Timer Audio Binding Tests (PKG-13.3 / PKG-13.5)', () {
    late SbeeDatabase database;
    late ProviderContainer container;
    late SharedPreferences prefs;
    late _RecordingAudioService mockAudio;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      database = SbeeDatabase(NativeDatabase.memory());
      mockAudio = _RecordingAudioService();

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(database),
          audioServiceProvider.overrideWithValue(mockAudio),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    WorkoutSession createTestSession({
      int setCount = 2,
      Duration restDuration = const Duration(seconds: 5),
      int? holdDurationSeconds,
    }) {
      final sets = List.generate(
        setCount,
        (i) => WorkoutSet(
          id: 'set_$i',
          sessionId: 'test_session_audio',
          exerciseId: 'standard_pushup',
          movementPattern: MovementPattern.pushing,
          setNumber: i + 1,
          reps: holdDurationSeconds == null ? 10 : 0,
          targetRpe: 8,
          variables: const MillerVariables(
            load: 1,
            bodyPosition: 1,
            rom: 1,
            height: 1,
            tempo: 1,
          ),
          timestamp: DateTime.now(),
          restDuration: restDuration,
          holdDurationSeconds: holdDurationSeconds,
        ),
      );

      return WorkoutSession(
        id: 'test_session_audio',
        startTime: DateTime.now(),
        sets: sets,
      );
    }

    testWidgets(
      'warmUp completion fires AudioCue.start and commences working set',
      (tester) async {
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(setCount: 2);

        await controller.startSession(session);
        expect(mockAudio.playedCues, isEmpty);

        controller.completeWarmUp();
        expect(mockAudio.playedCues, [AudioCue.start]);
        expect(
          container.read(activeSessionControllerProvider).fsmState,
          SessionState.activeSet,
        );
      },
    );

    testWidgets(
      'completeCurrentSet transitions to rest and plays AudioCue.rest immediately',
      (tester) async {
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(setCount: 2);

        await controller.startSession(session);
        controller.completeWarmUp();
        mockAudio.playedCues.clear();

        controller.completeCurrentSet(actualReps: 10);
        expect(mockAudio.playedCues, [AudioCue.rest]);
        expect(
          container.read(activeSessionControllerProvider).fsmState,
          SessionState.rest,
        );
        controller.completeRest();
      },
    );

    testWidgets(
      'rest countdown timer fires ticks at 3, 2, 1 seconds and AudioCue.start at expiry',
      (tester) async {
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(
          setCount: 2,
          restDuration: const Duration(seconds: 5),
        );

        await controller.startSession(session);
        controller.completeWarmUp();
        mockAudio.playedCues.clear();

        controller.completeCurrentSet(actualReps: 10);
        // t=0: rest interval commenced
        expect(mockAudio.playedCues, [AudioCue.rest]);

        // t=1: remaining drops to 4s (no tick)
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [AudioCue.rest]);

        // t=2: remaining drops to 3s (threshold: 3)
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [AudioCue.rest, AudioCue.tick]);

        // t=3: remaining drops to 2s (threshold: 2)
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [
          AudioCue.rest,
          AudioCue.tick,
          AudioCue.tick,
        ]);

        // t=4: remaining drops to 1s (threshold: 1)
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [
          AudioCue.rest,
          AudioCue.tick,
          AudioCue.tick,
          AudioCue.tick,
        ]);

        // t=5: countdown expires, remaining reaches 0s (GO / start cue)
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [
          AudioCue.rest,
          AudioCue.tick,
          AudioCue.tick,
          AudioCue.tick,
          AudioCue.start,
        ]);
        expect(
          container.read(activeSessionControllerProvider).restRemaining,
          Duration.zero,
        );
      },
    );

    testWidgets(
      'skipping rest before timer expiration immediately triggers AudioCue.start',
      (tester) async {
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(
          setCount: 2,
          restDuration: const Duration(seconds: 90),
        );

        await controller.startSession(session);
        controller.completeWarmUp();
        controller.completeCurrentSet(actualReps: 10);
        mockAudio.playedCues.clear();

        controller.completeRest();
        expect(mockAudio.playedCues, [AudioCue.start]);
        expect(
          container.read(activeSessionControllerProvider).fsmState,
          SessionState.activeSet,
        );
      },
    );

    testWidgets(
      'toggling soundEffectsEnabled to false silences all audio cue dispatches during workout',
      (tester) async {
        final sensoryNotifier = container.read(
          sensorySettingsProvider.notifier,
        );
        await sensoryNotifier.setSoundEffectsEnabled(false);

        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(
          setCount: 2,
          restDuration: const Duration(seconds: 5),
        );

        await controller.startSession(session);
        controller.completeWarmUp();
        controller.completeCurrentSet(actualReps: 10);

        // Elapse through the entire countdown
        await tester.pump(const Duration(seconds: 6));

        // When sound effects are disabled, zero cues should be played
        expect(mockAudio.playedCues, isEmpty);
      },
    );

    testWidgets(
      'static hold timer ticks at 3, 2, 1 and chimes AudioCue.complete on hold expiry',
      (tester) async {
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(setCount: 1, holdDurationSeconds: 5);

        await controller.startSession(session);
        mockAudio.playedCues.clear();

        controller.completeWarmUp();
        // Warm up fires start cue
        expect(mockAudio.playedCues, [AudioCue.start]);

        // t=1: hold timer remaining drops to 4s (no tick)
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [AudioCue.start]);

        // t=2: hold timer remaining drops to 3s -> tick
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [AudioCue.start, AudioCue.tick]);

        // t=3: hold timer remaining drops to 2s -> tick
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [
          AudioCue.start,
          AudioCue.tick,
          AudioCue.tick,
        ]);

        // t=4: hold timer remaining drops to 1s -> tick
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [
          AudioCue.start,
          AudioCue.tick,
          AudioCue.tick,
          AudioCue.tick,
        ]);

        // t=5: hold timer completes -> complete cue
        await tester.pump(const Duration(seconds: 1));
        expect(mockAudio.playedCues, [
          AudioCue.start,
          AudioCue.tick,
          AudioCue.tick,
          AudioCue.tick,
          AudioCue.complete,
        ]);
        expect(
          container.read(activeSessionControllerProvider).workRemaining,
          Duration.zero,
        );
      },
    );

    test(
      'session finalization triggers AudioCue.complete debrief fanfare',
      () async {
        final controller = container.read(
          activeSessionControllerProvider.notifier,
        );
        final session = createTestSession(setCount: 1);

        await controller.startSession(session);
        controller.completeWarmUp();
        controller.completeCurrentSet(actualReps: 10);
        mockAudio.playedCues.clear();

        await controller.completeCoolDown();

        expect(mockAudio.playedCues, [AudioCue.complete]);
        expect(
          container.read(activeSessionControllerProvider).fsmState,
          SessionState.completed,
        );
      },
    );
  });
}
