import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/test_env/test_env.dart';
import 'audio_service.dart';
import 'no_op_audio_service.dart';
import 'platform_audio_service.dart';

/// Global Riverpod provider exposing the active [AudioService].
///
/// In test environments (`isTestEnvironment == true`), automatically injects
/// [NoOpAudioService] to shield headless CI test runners from `MissingPluginException`.
final audioServiceProvider = Provider<AudioService>((ref) {
  if (isTestEnvironment) {
    return const NoOpAudioService();
  }

  final service = PlatformAudioService();
  service.initialize().catchError((_) {});
  ref.onDispose(service.dispose);
  return service;
});
