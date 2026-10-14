import 'package:flutter/foundation.dart';

/// Storage keys for persisting sensory operator settings in SharedPreferences.
const String kSoundEffectsEnabledKey = 'zenith_sound_effects_enabled';
const String kHapticFeedbackEnabledKey = 'zenith_haptic_feedback_enabled';

/// Immutable model representing operator sound and tactile sensory preferences.
@immutable
class SensorySettings {
  /// Whether 16-bit neo-pixel workout chimes, countdown ticks, and fanfare are enabled.
  final bool soundEffectsEnabled;

  /// Whether synchronized tactile vibration pulses during workout cues are enabled.
  final bool hapticFeedbackEnabled;

  const SensorySettings({
    this.soundEffectsEnabled = true,
    this.hapticFeedbackEnabled = true,
  });

  /// Default baseline sensory configuration (both sound and haptics enabled).
  static const SensorySettings baseline = SensorySettings();

  /// Creates a copy of [SensorySettings] with optionally replaced fields.
  SensorySettings copyWith({
    bool? soundEffectsEnabled,
    bool? hapticFeedbackEnabled,
  }) {
    return SensorySettings(
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorySettings &&
          runtimeType == other.runtimeType &&
          soundEffectsEnabled == other.soundEffectsEnabled &&
          hapticFeedbackEnabled == other.hapticFeedbackEnabled;

  @override
  int get hashCode => Object.hash(soundEffectsEnabled, hapticFeedbackEnabled);

  @override
  String toString() =>
      'SensorySettings(soundEffectsEnabled: $soundEffectsEnabled, hapticFeedbackEnabled: $hapticFeedbackEnabled)';
}
