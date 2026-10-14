import 'audio_cue.dart';
import 'audio_service.dart';

/// Test double and silent fallback audio service implementation.
class NoOpAudioService implements AudioService {
  const NoOpAudioService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> playCue(AudioCue cue) async {}

  @override
  Future<void> preloadAll() async {}

  @override
  void unlockWebAudio() {}

  @override
  void dispose() {}
}
