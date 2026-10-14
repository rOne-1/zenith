import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_cue.dart';
import 'audio_service.dart';

/// Production multiplatform implementation of [AudioService] backed by [audioplayers].
class PlatformAudioService implements AudioService {
  final Map<AudioCue, AudioPlayer> _players = <AudioCue, AudioPlayer>{};
  final Map<AudioCue, DateTime> _lastPlayed = <AudioCue, DateTime>{};
  bool _initialized = false;
  bool _webAudioUnlocked = false;

  static const Duration _debounceThreshold = Duration(milliseconds: 80);

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    } catch (_) {
      // Non-mobile platforms or headless environments absorb safely.
    }

    for (final cue in AudioCue.values) {
      try {
        final player = AudioPlayer(playerId: 'zenith_${cue.name}');
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        _players[cue] = player;
      } catch (_) {
        // Platform player creation failure is absorbed safely.
      }
    }
  }

  @override
  Future<void> preloadAll() async {
    if (!_initialized) {
      await initialize();
    }
    for (final entry in _players.entries) {
      try {
        await entry.value.setSource(AssetSource(entry.key.assetPath));
      } catch (_) {
        // Pre-decoding failures (e.g. assets not yet on disk or web autoplay) fail silently.
      }
    }
  }

  @override
  Future<void> playCue(AudioCue cue) async {
    if (!_initialized) {
      await initialize();
    }

    final now = DateTime.now();
    final last = _lastPlayed[cue];
    if (last != null && now.difference(last) < _debounceThreshold) {
      return;
    }
    _lastPlayed[cue] = now;

    final player = _players[cue];
    if (player == null) return;

    try {
      await player.stop();
      await player.play(AssetSource(cue.assetPath));
    } catch (_) {
      // Autoplay policy rejections or device playback errors fail silently.
    }
  }

  @override
  void unlockWebAudio() {
    if (!kIsWeb || _webAudioUnlocked) return;
    _webAudioUnlocked = true;
    for (final player in _players.values) {
      try {
        player.setVolume(1.0).catchError((_) {});
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      try {
        player.dispose();
      } catch (_) {}
    }
    _players.clear();
    _lastPlayed.clear();
    _initialized = false;
  }
}
