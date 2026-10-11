import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/storage/secure_storage_provider.dart';
import 'package:zenith/features/archive/models/zenith_archive_bundle.dart';
import 'package:zenith/features/archive/services/archive_restore_service.dart';
import 'package:zenith/features/armory/providers/user_profile_provider.dart';
import 'package:zenith/features/onboarding/providers/onboarding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Archive Two-Phase Atomic Rollback Tests (Guardrail 3)', () {
    test('transaction failure reverts SharedPreferences and SecureStorage to snapshot', () async {
      final db = SbeeDatabase(NativeDatabase.memory());

      // 1. Establish pre-restore baseline state
      const initialProfile = '{"availableEquipment":["bodyweight"],"experienceLevel":"beginner"}';
      const initialDistrict = 'district_01_railside_outskirts';
      const initialOnboarding = true;
      const initialSensitive = '{"hasJointPain":false,"femaleProfile":{"cycleDay":10,"age":26}}';

      SharedPreferences.setMockInitialValues({
        kUserProfileStorageKey: initialProfile,
        'zenith_active_district_id': initialDistrict,
        kHasCompletedOnboardingKey: initialOnboarding,
      });

      final prefs = await SharedPreferences.getInstance();
      final keyStore = InMemoryMasterKeyStore();
      final secureStorage = AesGcmSecureStorage(prefs, keyStore: keyStore);
      await secureStorage.write(kSensitiveHealthStorageKey, initialSensitive);

      // Verify baseline state
      expect(prefs.getString(kUserProfileStorageKey), equals(initialProfile));
      expect(prefs.getString('zenith_active_district_id'), equals(initialDistrict));
      expect(prefs.getBool(kHasCompletedOnboardingKey), equals(initialOnboarding));
      expect(await secureStorage.read(kSensitiveHealthStorageKey), equals(initialSensitive));

      // 2. Prepare an archive bundle with malformed DB rows that violate DB constraints
      // (e.g. workout set with non-existent foreign key session, or closing DB before transaction)
      final now = DateTime.utc(2026, 10, 11, 10, 0, 0);
      final malformedBundle = ZenithArchiveBundle(
        schema: kArchiveSchema,
        version: kArchiveVersion,
        exportedAt: now,
        appVersion: '0.9.0',
        checksum: 'mock-checksum',
        profile: const ArchiveProfileBundle(
          nonSensitive: {
            'availableEquipment': ['bodyweight', 'pullUpBar', 'dipStation'],
            'experienceLevel': 'advanced',
          },
          sensitive: {
            'hasJointPain': true,
            'femaleProfile': {'cycleDay': 28, 'age': 35},
          },
        ),
        preferences: const ArchivePreferencesBundle(
          activeDistrictId: 'district_02_neon_alleys',
          hasCompletedOnboarding: false,
        ),
        database: const ArchiveDatabaseBundle(
          workoutSessions: [],
          workoutSets: [
            // Violates NOT NULL on required columns or foreign key constraints
            {
              'id': 'invalid-set',
              'sessionId': 'non-existent-session-id',
              'exerciseId': 'pushup_standard',
              'movementPattern': 2,
              'setNumber': 1,
              'reps': 10,
              'targetRpe': 8,
              'loadVal': 0,
              'bodyPosition': 1,
              'rom': 1,
              'height': 0,
              'tempo': 1,
              // Intentionally missing timestamp to trigger DB constraint failure
            },
          ],
        ),
      );

      final restoreService = ArchiveRestoreService(
        prefs: prefs,
        secureStorage: secureStorage,
        db: db,
      );

      // 3. Attempt restore and verify it throws ArchiveRestoreException
      expect(
        () => restoreService.restoreArchiveBundle(malformedBundle),
        throwsA(isA<ArchiveRestoreException>()),
      );

      // 4. Assert that SharedPreferences and SecureStorage were completely rolled back!
      expect(prefs.getString(kUserProfileStorageKey), equals(initialProfile));
      expect(prefs.getString('zenith_active_district_id'), equals(initialDistrict));
      expect(prefs.getBool(kHasCompletedOnboardingKey), equals(initialOnboarding));
      expect(await secureStorage.read(kSensitiveHealthStorageKey), equals(initialSensitive));

      await db.close();
    });
  });
}
