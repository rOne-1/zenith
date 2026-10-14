import 'audio_cue.dart';

/// Abstract service contract for low-latency workout audio cues.
abstract interface class AudioService {
  /// Initializes the audio engine, configuring ambient session mixing.
  Future<void> initialize();

  /// Plays the specified [cue], respecting debouncing and error isolation.
  Future<void> playCue(AudioCue cue);

  /// Pre-decodes and caches all audio assets into memory buffers for <15ms latency.
  Future<void> preloadAll();

  /// Unlocks web browser AudioContext upon user gesture.
  void unlockWebAudio();

  /// Disposes audio players and releases platform audio channels.
  void dispose();
}
