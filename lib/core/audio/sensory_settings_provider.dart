import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/storage.dart';
import 'sensory_settings.dart';

/// StateNotifier that manages operator audio and haptics preferences,
/// persisting changes immediately to [SharedPreferences].
class SensorySettingsNotifier extends StateNotifier<SensorySettings> {
  final SharedPreferences? _prefs;

  SensorySettingsNotifier([this._prefs])
      : super(_loadInitialSettings(_prefs));

  static SensorySettings _loadInitialSettings(SharedPreferences? prefs) {
    if (prefs == null) {
      return SensorySettings.baseline;
    }
    final sound = prefs.getBool(kSoundEffectsEnabledKey) ?? true;
    final haptics = prefs.getBool(kHapticFeedbackEnabledKey) ?? true;
    return SensorySettings(
      soundEffectsEnabled: sound,
      hapticFeedbackEnabled: haptics,
    );
  }

  /// Toggles sound effects ON/OFF and persists to [SharedPreferences].
  Future<void> toggleSoundEffects() async {
    final updated = !state.soundEffectsEnabled;
    state = state.copyWith(soundEffectsEnabled: updated);
    await _prefs?.setBool(kSoundEffectsEnabledKey, updated);
  }

  /// Sets sound effects state explicitly and persists to [SharedPreferences].
  Future<void> setSoundEffectsEnabled(bool enabled) async {
    if (state.soundEffectsEnabled == enabled) return;
    state = state.copyWith(soundEffectsEnabled: enabled);
    await _prefs?.setBool(kSoundEffectsEnabledKey, enabled);
  }

  /// Toggles tactile haptic feedback ON/OFF and persists to [SharedPreferences].
  Future<void> toggleHapticFeedback() async {
    final updated = !state.hapticFeedbackEnabled;
    state = state.copyWith(hapticFeedbackEnabled: updated);
    await _prefs?.setBool(kHapticFeedbackEnabledKey, updated);
  }

  /// Sets tactile haptic feedback state explicitly and persists to [SharedPreferences].
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    if (state.hapticFeedbackEnabled == enabled) return;
    state = state.copyWith(hapticFeedbackEnabled: enabled);
    await _prefs?.setBool(kHapticFeedbackEnabledKey, enabled);
  }
}

/// Provider managing active operator sensory settings.
final sensorySettingsProvider =
    StateNotifierProvider<SensorySettingsNotifier, SensorySettings>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SensorySettingsNotifier(prefs);
  } catch (_) {
    return SensorySettingsNotifier();
  }
});
