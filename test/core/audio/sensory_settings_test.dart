import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/audio/audio.dart';
import 'package:zenith/core/storage/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SensorySettings Model', () {
    test('default baseline enables both sound and haptics', () {
      const settings = SensorySettings();
      expect(settings.soundEffectsEnabled, isTrue);
      expect(settings.hapticFeedbackEnabled, isTrue);
      expect(SensorySettings.baseline.soundEffectsEnabled, isTrue);
      expect(SensorySettings.baseline.hapticFeedbackEnabled, isTrue);
    });

    test('copyWith updates fields selectively', () {
      const settings = SensorySettings();
      final updatedSound = settings.copyWith(soundEffectsEnabled: false);
      expect(updatedSound.soundEffectsEnabled, isFalse);
      expect(updatedSound.hapticFeedbackEnabled, isTrue);

      final updatedHaptics = settings.copyWith(hapticFeedbackEnabled: false);
      expect(updatedHaptics.soundEffectsEnabled, isTrue);
      expect(updatedHaptics.hapticFeedbackEnabled, isFalse);
    });

    test('supports value equality, hashCode, and toString', () {
      const a = SensorySettings(soundEffectsEnabled: true, hapticFeedbackEnabled: false);
      const b = SensorySettings(soundEffectsEnabled: true, hapticFeedbackEnabled: false);
      const c = SensorySettings(soundEffectsEnabled: false, hapticFeedbackEnabled: false);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a.toString(), contains('soundEffectsEnabled: true'));
      expect(a.toString(), contains('hapticFeedbackEnabled: false'));
    });
  });

  group('SensorySettingsNotifier', () {
    test('loads baseline defaults when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = SensorySettingsNotifier(prefs);
      expect(notifier.state.soundEffectsEnabled, isTrue);
      expect(notifier.state.hapticFeedbackEnabled, isTrue);
    });

    test('hydrates persisted preferences from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        kSoundEffectsEnabledKey: false,
        kHapticFeedbackEnabledKey: false,
      });
      final prefs = await SharedPreferences.getInstance();

      final notifier = SensorySettingsNotifier(prefs);
      expect(notifier.state.soundEffectsEnabled, isFalse);
      expect(notifier.state.hapticFeedbackEnabled, isFalse);
    });

    test('toggleSoundEffects updates state immediately and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = SensorySettingsNotifier(prefs);
      expect(notifier.state.soundEffectsEnabled, isTrue);

      await notifier.toggleSoundEffects();
      expect(notifier.state.soundEffectsEnabled, isFalse);
      expect(prefs.getBool(kSoundEffectsEnabledKey), isFalse);

      await notifier.toggleSoundEffects();
      expect(notifier.state.soundEffectsEnabled, isTrue);
      expect(prefs.getBool(kSoundEffectsEnabledKey), isTrue);
    });

    test('toggleHapticFeedback updates state immediately and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = SensorySettingsNotifier(prefs);
      expect(notifier.state.hapticFeedbackEnabled, isTrue);

      await notifier.toggleHapticFeedback();
      expect(notifier.state.hapticFeedbackEnabled, isFalse);
      expect(prefs.getBool(kHapticFeedbackEnabledKey), isFalse);

      await notifier.toggleHapticFeedback();
      expect(notifier.state.hapticFeedbackEnabled, isTrue);
      expect(prefs.getBool(kHapticFeedbackEnabledKey), isTrue);
    });

    test('setSoundEffectsEnabled and setHapticFeedbackEnabled update state explicitly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = SensorySettingsNotifier(prefs);
      await notifier.setSoundEffectsEnabled(false);
      expect(notifier.state.soundEffectsEnabled, isFalse);
      expect(prefs.getBool(kSoundEffectsEnabledKey), isFalse);

      await notifier.setHapticFeedbackEnabled(false);
      expect(notifier.state.hapticFeedbackEnabled, isFalse);
      expect(prefs.getBool(kHapticFeedbackEnabledKey), isFalse);

      // Setting to identical value is a safe no-op
      await notifier.setSoundEffectsEnabled(false);
      expect(notifier.state.soundEffectsEnabled, isFalse);
    });

    test('operates safely with null SharedPreferences in headless isolation', () async {
      final notifier = SensorySettingsNotifier();
      expect(notifier.state.soundEffectsEnabled, isTrue);
      expect(notifier.state.hapticFeedbackEnabled, isTrue);

      await notifier.toggleSoundEffects();
      expect(notifier.state.soundEffectsEnabled, isFalse);

      await notifier.toggleHapticFeedback();
      expect(notifier.state.hapticFeedbackEnabled, isFalse);
    });
  });

  group('sensorySettingsProvider Integration', () {
    test('provides reactive updates within ProviderContainer', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final initial = container.read(sensorySettingsProvider);
      expect(initial.soundEffectsEnabled, isTrue);
      expect(initial.hapticFeedbackEnabled, isTrue);

      final notifier = container.read(sensorySettingsProvider.notifier);
      await notifier.toggleSoundEffects();

      final updated = container.read(sensorySettingsProvider);
      expect(updated.soundEffectsEnabled, isFalse);
    });
  });

  group('PlatformAudioService Sensory Binding', () {
    test('disabling soundEffectsEnabled silences future playCue calls', () async {
      final service = PlatformAudioService();
      expect(service.soundEffectsEnabled, isTrue);

      service.setSoundEffectsEnabled(false);
      expect(service.soundEffectsEnabled, isFalse);

      // playCue returns immediately without throwing or triggering player
      await expectLater(service.playCue(AudioCue.tick), completes);
      service.dispose();
    });
  });
}
