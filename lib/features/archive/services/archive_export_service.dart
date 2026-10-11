import 'dart:convert';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/secure_storage_provider.dart';
import '../../armory/providers/user_profile_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/zenith_archive_bundle.dart';

/// Service responsible for constructing cryptographic, decoupled, zero-telemetry
/// JSON export bundles from local SQLite and split secure storage.
class ArchiveExportService {
  final SharedPreferences prefs;
  final SecureStorage secureStorage;
  final SbeeDatabase db;
  final String appVersion;

  ArchiveExportService({
    required this.prefs,
    required this.secureStorage,
    required this.db,
    this.appVersion = '0.9.0',
  });

  /// Compiles a fully decoupled [ZenithArchiveBundle] and returns it as a formatted JSON string.
  ///
  /// Sensitive health telemetry is decrypted in-memory; zero raw `zenith_sec_*` ciphertext
  /// envelopes or hardware keystore bindings are included in the bundle.
  Future<String> exportArchiveJson({bool pretty = true}) async {
    final bundle = await createArchiveBundle();
    return bundle.toExportJsonString(pretty: pretty);
  }

  /// Constructs the strongly typed [ZenithArchiveBundle] with verified SHA-256 checksum.
  Future<ZenithArchiveBundle> createArchiveBundle() async {
    // 1. Read non-sensitive profile from SharedPreferences
    Map<String, dynamic> nonSensitiveMap = {};
    final rawProfile = prefs.getString(kUserProfileStorageKey);
    if (rawProfile != null) {
      try {
        final decoded = jsonDecode(rawProfile);
        if (decoded is Map<String, dynamic>) {
          nonSensitiveMap = decoded;
        }
      } catch (_) {}
    }

    // 2. Decrypt sensitive health telemetry in memory (Decoupled from hardware keystore)
    Map<String, dynamic>? sensitiveMap;
    final decryptedHealth = await secureStorage.read(kSensitiveHealthStorageKey);
    if (decryptedHealth != null) {
      try {
        final decoded = jsonDecode(decryptedHealth);
        if (decoded is Map<String, dynamic>) {
          sensitiveMap = decoded;
        }
      } catch (_) {}
    }

    final profileBundle = ArchiveProfileBundle(
      nonSensitive: nonSensitiveMap,
      sensitive: sensitiveMap,
    );

    // 3. Read preferences and onboarding state
    final activeDistrict = prefs.getString('zenith_active_district_id');
    final onboardingDone = hasCompletedOnboarding(prefs);

    final preferencesBundle = ArchivePreferencesBundle(
      activeDistrictId: activeDistrict,
      hasCompletedOnboarding: onboardingDone,
    );

    // 4. Query all 4 Drift database tables
    final sessions = await db.select(db.driftWorkoutSessions).get();
    final sets = await db.select(db.driftWorkoutSets).get();
    final progressions = await db.select(db.driftExerciseProgressions).get();
    final statusAchieved = await db.select(db.driftStatusAchieved).get();

    final databaseBundle = ArchiveDatabaseBundle(
      workoutSessions: sessions.map((s) => s.toJson()).toList(),
      workoutSets: sets.map((s) => s.toJson()).toList(),
      exerciseProgressions: progressions.map((p) => p.toJson()).toList(),
      statusAchieved: statusAchieved.map((a) => a.toJson()).toList(),
    );

    // 5. Construct provisional bundle to compute canonical SHA-256 digest
    final now = DateTime.now().toUtc();
    final provisionalBundle = ZenithArchiveBundle(
      schema: kArchiveSchema,
      version: kArchiveVersion,
      exportedAt: now,
      appVersion: appVersion,
      checksum: '',
      profile: profileBundle,
      preferences: preferencesBundle,
      database: databaseBundle,
    );

    final checksum = await ZenithArchiveBundle.computeChecksum(
      provisionalBundle.toJson(),
    );

    return ZenithArchiveBundle(
      schema: kArchiveSchema,
      version: kArchiveVersion,
      exportedAt: now,
      appVersion: appVersion,
      checksum: checksum,
      profile: profileBundle,
      preferences: preferencesBundle,
      database: databaseBundle,
    );
  }
}
