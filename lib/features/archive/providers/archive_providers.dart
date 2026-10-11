import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../core/storage/preferences_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/theme/district_registry.dart';
import '../../../engine/database_provider.dart';
import '../../../engine/sbee_service.dart';
import '../../armory/providers/user_profile_provider.dart';
import '../../expedition/controllers/active_session_controller.dart';
import '../../expedition/services/workout_preview_service.dart';
import '../../outpost/services/streak_service.dart';
import '../../sanctuary/services/adaptation_ledger_service.dart';
import '../../sanctuary/services/macrocycle_service.dart';
import '../../sanctuary/services/recovery_status_service.dart';
import '../models/zenith_archive_bundle.dart';
import '../services/archive_export_service.dart';
import '../services/archive_file_bridge.dart';
import '../services/archive_restore_service.dart';
import '../services/archive_validator.dart';

/// Exception thrown when a restore operation is attempted while a live workout is in-flight.
class ActiveSessionInProgressException implements Exception {
  final String message;
  const ActiveSessionInProgressException([
    this.message =
        'SESSION IN PROGRESS: Conclude or discard current expedition before restoring data.',
  ]);

  @override
  String toString() => 'ActiveSessionInProgressException: $message';
}

/// Provider for the archive schema and entity validator.
final archiveValidatorProvider = Provider<ArchiveValidator>((ref) {
  return const ArchiveValidator();
});

/// Provider for the cross-platform file save, share, and pick bridge.
final archiveFileBridgeProvider = Provider<ArchiveFileBridge>((ref) {
  return const ArchiveFileBridge();
});

/// Provider for the decoupled data archive export service.
final archiveExportServiceProvider = Provider<ArchiveExportService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final db = ref.watch(sbeeDatabaseProvider);
  return ArchiveExportService(
    prefs: prefs,
    secureStorage: secureStorage,
    db: db,
    appVersion: '0.9.0',
  );
});

/// Provider for the two-phase atomic database restore service.
final archiveRestoreServiceProvider = Provider<ArchiveRestoreService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final db = ref.watch(sbeeDatabaseProvider);
  return ArchiveRestoreService(
    prefs: prefs,
    secureStorage: secureStorage,
    db: db,
  );
});

/// Coordinator executing data restoration with in-flight workout lockouts
/// and systematic shell invalidation across persistent tab screens.
class ArchiveRestoreCoordinator {
  final Ref _ref;

  ArchiveRestoreCoordinator(this._ref);

  /// Whether an active or interrupted workout session is currently in flight.
  bool get isSessionInProgress {
    final resumeManager = _ref.read(activeSessionResumeProvider).valueOrNull;
    if (resumeManager != null) return true;

    final controllerState = _ref.read(activeSessionControllerProvider);
    return controllerState.hasActiveSession &&
        controllerState.fsmState != SessionState.completed;
  }

  /// Restores athlete data from [bundle], enforcing the in-flight workout lockout
  /// and systematically invalidating all Riverpod shell providers post-restore.
  Future<void> restore(ZenithArchiveBundle bundle) async {
    if (isSessionInProgress) {
      throw const ActiveSessionInProgressException();
    }

    final restoreService = _ref.read(archiveRestoreServiceProvider);
    await restoreService.restoreArchiveBundle(bundle);

    // Coordinated shell invalidation across the persistent IndexedStack
    _ref.invalidate(userProfileProvider);
    _ref.read(workoutPreviewProvider.notifier).invalidate();
    _ref.invalidate(activeSessionResumeProvider);
    _ref.invalidate(currentStreakProvider);
    _ref.invalidate(macrocycleProvider);
    _ref.invalidate(recoveryStatusProvider);
    _ref.invalidate(adaptationLedgerProvider);
    _ref.invalidate(isIntermediateStatusProvider);
    _ref.invalidate(themeControllerProvider);
  }
}

/// Provider exposing the [ArchiveRestoreCoordinator].
final archiveRestoreCoordinatorProvider =
    Provider<ArchiveRestoreCoordinator>((ref) {
  return ArchiveRestoreCoordinator(ref);
});
