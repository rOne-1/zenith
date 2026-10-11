import 'dart:convert';
// ignore: implementation_imports
import 'package:sbee/src/data/drift/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/secure_storage_provider.dart';
import '../../armory/providers/user_profile_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/zenith_archive_bundle.dart';

/// Exception thrown when data archive restoration fails.
class ArchiveRestoreException implements Exception {
  final String message;
  const ArchiveRestoreException(this.message);

  @override
  String toString() => 'ArchiveRestoreException: $message';
}

/// Service executing atomic database restoration with Two-Phase Rollback protection
/// and dynamic cryptographic re-encryption under the host device's active MasterKeyStore.
class ArchiveRestoreService {
  final SharedPreferences prefs;
  final SecureStorage secureStorage;
  final SbeeDatabase db;

  ArchiveRestoreService({
    required this.prefs,
    required this.secureStorage,
    required this.db,
  });

  /// Restores athlete data from a validated [ZenithArchiveBundle].
  ///
  /// Executes a Two-Phase Atomic Rollback protocol:
  /// 1. Takes an in-memory snapshot of current preferences and secure storage keys.
  /// 2. Updates SharedPreferences with non-sensitive settings.
  /// 3. Re-encrypts sensitive physiological data under the host's active vault.
  /// 4. Executes an atomic Drift database transaction (cascade delete, batch insert).
  /// 5. If the transaction throws, reverts SharedPreferences and SecureStorage to snapshot.
  Future<void> restoreArchiveBundle(ZenithArchiveBundle bundle) async {
    // Phase 1: Snapshot existing state in memory
    final snapshotProfile = prefs.getString(kUserProfileStorageKey);
    final snapshotDistrict = prefs.getString('zenith_active_district_id');
    final snapshotOnboarding = prefs.getBool(kHasCompletedOnboardingKey);
    final snapshotSensitive = await secureStorage.read(kSensitiveHealthStorageKey);

    try {
      // Phase 2: Update non-sensitive profile & preferences
      await prefs.setString(
        kUserProfileStorageKey,
        jsonEncode(bundle.profile.nonSensitive),
      );

      if (bundle.preferences.activeDistrictId != null) {
        await prefs.setString(
          'zenith_active_district_id',
          bundle.preferences.activeDistrictId!,
        );
      }

      await prefs.setBool(
        kHasCompletedOnboardingKey,
        bundle.preferences.hasCompletedOnboarding,
      );

      // Phase 3: Re-encrypt sensitive telemetry under destination device's MasterKeyStore
      if (bundle.profile.sensitive != null) {
        await secureStorage.write(
          kSensitiveHealthStorageKey,
          jsonEncode(bundle.profile.sensitive!),
        );
      } else {
        await secureStorage.delete(kSensitiveHealthStorageKey);
      }

      // Phase 4: Atomic Drift transactional exchange
      await db.transaction(() async {
        // Cascade-safe deletion of existing records
        await db.delete(db.driftStatusAchieved).go();
        await db.delete(db.driftExerciseProgressions).go();
        await db.delete(db.driftWorkoutSets).go();
        await db.delete(db.driftWorkoutSessions).go();

        // Batch-insert imported records
        await db.batch((batch) {
          if (bundle.database.workoutSessions.isNotEmpty) {
            batch.insertAll(
              db.driftWorkoutSessions,
              bundle.database.workoutSessions
                  .map((m) => DriftWorkoutSession.fromJson(m))
                  .toList(),
            );
          }

          if (bundle.database.workoutSets.isNotEmpty) {
            batch.insertAll(
              db.driftWorkoutSets,
              bundle.database.workoutSets
                  .map((m) => DriftWorkoutSet.fromJson(m))
                  .toList(),
            );
          }

          if (bundle.database.exerciseProgressions.isNotEmpty) {
            batch.insertAll(
              db.driftExerciseProgressions,
              bundle.database.exerciseProgressions
                  .map((m) => DriftExerciseProgression.fromJson(m))
                  .toList(),
            );
          }

          if (bundle.database.statusAchieved.isNotEmpty) {
            batch.insertAll(
              db.driftStatusAchieved,
              bundle.database.statusAchieved
                  .map((m) => DriftStatusAchievedData.fromJson(m))
                  .toList(),
            );
          }
        });
      });
    } catch (e) {
      // Phase 5: Rollback SharedPreferences & SecureStorage on failure
      if (snapshotProfile != null) {
        await prefs.setString(kUserProfileStorageKey, snapshotProfile);
      } else {
        await prefs.remove(kUserProfileStorageKey);
      }

      if (snapshotDistrict != null) {
        await prefs.setString('zenith_active_district_id', snapshotDistrict);
      } else {
        await prefs.remove('zenith_active_district_id');
      }

      if (snapshotOnboarding != null) {
        await prefs.setBool(kHasCompletedOnboardingKey, snapshotOnboarding);
      } else {
        await prefs.remove(kHasCompletedOnboardingKey);
      }

      if (snapshotSensitive != null) {
        await secureStorage.write(
          kSensitiveHealthStorageKey,
          snapshotSensitive,
        );
      } else {
        await secureStorage.delete(kSensitiveHealthStorageKey);
      }

      throw ArchiveRestoreException(
        'Database transaction failed during restore. Local storage reverted to snapshot: $e',
      );
    }
  }
}
