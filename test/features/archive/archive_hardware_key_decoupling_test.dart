import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:sbee/src/data/drift/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/storage/secure_storage_provider.dart';
import 'package:zenith/features/archive/services/archive_export_service.dart';
import 'package:zenith/features/archive/services/archive_restore_service.dart';
import 'package:zenith/features/armory/providers/user_profile_provider.dart';
import 'package:zenith/features/onboarding/providers/onboarding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Archive Hardware Key Decoupling Tests (SEC-1)', () {
    late SbeeDatabase db;

    setUp(() {
      db = SbeeDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('export decrypts sensitive health data in memory with zero raw ciphertext envelopes', () async {
      SharedPreferences.setMockInitialValues({
        kUserProfileStorageKey: jsonEncode({
          'availableEquipment': ['bodyweight', 'pullUpBar'],
          'experienceLevel': 'intermediate',
        }),
        'zenith_active_district_id': 'district_02_neon_alleys',
        kHasCompletedOnboardingKey: true,
      });

      final prefs = await SharedPreferences.getInstance();
      final keyStore = InMemoryMasterKeyStore();
      final secureStorage = AesGcmSecureStorage(prefs, keyStore: keyStore);

      // Store sensitive health telemetry encrypted under keyStore
      final sensitiveTelemetry = {
        'hasJointPain': true,
        'femaleProfile': {
          'userStatus': 'Untrained_Female',
          'cycleDay': 21,
          'hasKneeDiscomfort': true,
          'age': 32,
          'hasJointPain': true,
        },
      };
      await secureStorage.write(
        kSensitiveHealthStorageKey,
        jsonEncode(sensitiveTelemetry),
      );

      // Verify that SharedPreferences raw envelope starts with zenith_sec_
      expect(prefs.containsKey('zenith_sec_$kSensitiveHealthStorageKey'), isTrue);
      final rawCipherEnvelope = prefs.getString('zenith_sec_$kSensitiveHealthStorageKey')!;
      expect(rawCipherEnvelope, contains('cipher'));
      expect(rawCipherEnvelope, contains('nonce'));

      // Populate database with 1 session
      final now = DateTime.utc(2026, 10, 11, 10, 0, 0);
      await db.into(db.driftWorkoutSessions).insert(
        DriftWorkoutSessionsCompanion.insert(
          id: 'session-alpha',
          startTime: now,
          isCompleted: const Value(true),
        ),
      );

      final exportService = ArchiveExportService(
        prefs: prefs,
        secureStorage: secureStorage,
        db: db,
        appVersion: '0.9.0',
      );

      final jsonExportString = await exportService.exportArchiveJson();

      // Assert zero hardware keys or raw ciphertext envelopes in export bundle
      expect(jsonExportString, isNot(contains(kSecureStorageKeyPrefix)));
      expect(jsonExportString, isNot(contains(kSecureStorageMasterKeyPref)));
      expect(jsonExportString, isNot(contains('cipher')));
      expect(jsonExportString, isNot(contains('nonce')));
      expect(jsonExportString, isNot(contains('mac')));

      // Assert decrypted health data is present in plaintext JSON
      final decoded = jsonDecode(jsonExportString) as Map<String, dynamic>;
      final profile = decoded['profile'] as Map<String, dynamic>;
      final sensitive = profile['sensitive'] as Map<String, dynamic>;
      expect(sensitive['hasJointPain'], isTrue);
      expect(sensitive['femaleProfile']['cycleDay'], equals(21));
      expect(sensitive['femaleProfile']['age'], equals(32));
    });

    test('restore re-encrypts sensitive telemetry under a fresh MasterKeyStore', () async {
      // 1. Setup Source Device A
      SharedPreferences.setMockInitialValues({
        kUserProfileStorageKey: jsonEncode({
          'availableEquipment': ['bodyweight'],
          'experienceLevel': 'beginner',
        }),
      });
      final prefsA = await SharedPreferences.getInstance();
      final keyStoreA = InMemoryMasterKeyStore();
      final secureStorageA = AesGcmSecureStorage(prefsA, keyStore: keyStoreA);

      await secureStorageA.write(
        kSensitiveHealthStorageKey,
        jsonEncode({
          'hasJointPain': false,
          'femaleProfile': {
            'userStatus': 'Untrained_Female',
            'cycleDay': 12,
            'hasKneeDiscomfort': false,
            'age': 25,
            'hasJointPain': false,
          },
        }),
      );

      final exportService = ArchiveExportService(
        prefs: prefsA,
        secureStorage: secureStorageA,
        db: db,
        appVersion: '0.9.0',
      );
      final bundle = await exportService.createArchiveBundle();

      // 2. Setup Destination Device B with a completely distinct MasterKeyStore
      final newDb = SbeeDatabase(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({});
      final prefsB = await SharedPreferences.getInstance();
      final keyStoreB = InMemoryMasterKeyStore(); // Fresh distinct key vault
      final secureStorageB = AesGcmSecureStorage(prefsB, keyStore: keyStoreB);

      final restoreService = ArchiveRestoreService(
        prefs: prefsB,
        secureStorage: secureStorageB,
        db: newDb,
      );

      // Execute restore on Device B
      await restoreService.restoreArchiveBundle(bundle);

      // Device B can read and decrypt the restored health profile cleanly under its own keyStoreB
      final decryptedOnB = await secureStorageB.read(kSensitiveHealthStorageKey);
      expect(decryptedOnB, isNotNull);
      final decodedHealthB = jsonDecode(decryptedOnB!) as Map<String, dynamic>;
      expect(decodedHealthB['femaleProfile']['cycleDay'], equals(12));
      expect(decodedHealthB['femaleProfile']['age'], equals(25));

      // KeyStore A and KeyStore B must have different master keys
      final masterKeyA = await keyStoreA.readMasterKey();
      final masterKeyB = await keyStoreB.readMasterKey();
      expect(masterKeyA, isNotNull);
      expect(masterKeyB, isNotNull);
      expect(masterKeyA, isNot(equals(masterKeyB)));

      await newDb.close();
    });
  });
}
