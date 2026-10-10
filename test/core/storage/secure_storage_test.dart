import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/storage/storage.dart';

void main() {
  group('AesGcmSecureStorage Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      FlutterSecureStorageMasterKeyStore.resetTestStore();
    });

    test('Round-trip encryption and decryption restores exact string value', () async {
      final storage = AesGcmSecureStorage(prefs);
      const testKey = 'health_telemetry';
      const clearText = '{"cycleDay": 14, "hasJointPain": true, "userStatus": "Athlete"}';

      await storage.write(testKey, clearText);
      expect(await storage.containsKey(testKey), isTrue);

      final decrypted = await storage.read(testKey);
      expect(decrypted, equals(clearText));
    });

    test('Ciphertext isolation: plaintext never appears in SharedPreferences', () async {
      final storage = AesGcmSecureStorage(prefs);
      const testKey = 'secret_data';
      const sensitiveString = 'ConfidentialEndocrineMarker98765';

      await storage.write(testKey, sensitiveString);

      // Verify pref key is prefixed
      final storedRaw = prefs.getString('$kSecureStorageKeyPrefix$testKey');
      expect(storedRaw, isNotNull);

      // Verify the sensitive string does NOT appear anywhere in SharedPreferences
      expect(storedRaw, isNot(contains(sensitiveString)));

      // Verify envelope structure
      final envelope = jsonDecode(storedRaw!) as Map<String, dynamic>;
      expect(envelope['v'], equals(1));
      expect(envelope['cipher'], isNotNull);
      expect(envelope['nonce'], isNotNull);
      expect(envelope['mac'], isNotNull);
    });

    test('Tampered ciphertext or MAC tag throws SecureStorageAuthException', () async {
      final storage = AesGcmSecureStorage(prefs);
      const testKey = 'tamper_test';
      await storage.write(testKey, 'tamper-proof-data');

      final rawPrefKey = '$kSecureStorageKeyPrefix$testKey';
      final storedRaw = prefs.getString(rawPrefKey)!;
      final envelope = jsonDecode(storedRaw) as Map<String, dynamic>;

      // Tamper with the ciphertext by flipping bytes
      final cipherBytes = base64Decode(envelope['cipher'] as String);
      cipherBytes[0] ^= 0xFF;
      envelope['cipher'] = base64Encode(cipherBytes);
      await prefs.setString(rawPrefKey, jsonEncode(envelope));

      expect(
        () => storage.read(testKey),
        throwsA(isA<SecureStorageAuthException>()),
      );
    });

    test('Data encrypted with Key A cannot be decrypted by Key B', () async {
      final algorithm = AesGcm.with256bits();
      final keyA = await algorithm.newSecretKey();
      final keyB = await algorithm.newSecretKey();

      final storageA = AesGcmSecureStorage(prefs, masterKey: keyA);
      final storageB = AesGcmSecureStorage(prefs, masterKey: keyB);

      const testKey = 'isolated_key';
      await storageA.write(testKey, 'encrypted-with-key-A');

      expect(
        () => storageB.read(testKey),
        throwsA(isA<SecureStorageAuthException>()),
      );
    });

    test('delete removes entry and containsKey reports false', () async {
      final storage = AesGcmSecureStorage(prefs);
      const testKey = 'temporary_key';

      await storage.write(testKey, 'val');
      expect(await storage.containsKey(testKey), isTrue);

      await storage.delete(testKey);
      expect(await storage.containsKey(testKey), isFalse);
      expect(await storage.read(testKey), isNull);
    });

    test('Reading nonexistent key returns null without exception', () async {
      final storage = AesGcmSecureStorage(prefs);
      expect(await storage.read('non_existent'), isNull);
    });
  });

  group('SEC-1 Hardware-Backed Key Separation Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      FlutterSecureStorageMasterKeyStore.resetTestStore();
    });

    test('Hardware-backed key isolation: master key is written to MasterKeyStore and NEVER to SharedPreferences', () async {
      final keyStore = InMemoryMasterKeyStore();
      final storage = AesGcmSecureStorage(prefs, keyStore: keyStore);
      const testKey = 'patient_dna_marker';
      const testValue = 'ATCGCGATCGATCGAT';

      await storage.write(testKey, testValue);

      // Verify data is persisted in SharedPreferences envelope
      expect(prefs.containsKey('$kSecureStorageKeyPrefix$testKey'), isTrue);

      // STRICT SEC-1: SharedPreferences must NEVER contain the master key
      expect(prefs.getString(kSecureStorageMasterKeyPref), isNull);
      expect(prefs.containsKey(kSecureStorageMasterKeyPref), isFalse);
      expect(prefs.getKeys().contains(kSecureStorageMasterKeyPref), isFalse);

      // Master key is stored in the vault
      final vaultedKeyBase64 = await keyStore.readMasterKey();
      expect(vaultedKeyBase64, isNotNull);
      final keyBytes = base64Decode(vaultedKeyBase64!);
      expect(keyBytes.length, equals(32)); // 256-bit AES key

      // Decryption round-trip succeeds with the vaulted key
      final decrypted = await storage.read(testKey);
      expect(decrypted, equals(testValue));
    });

    test('Seamless legacy migration: legacy master key in SharedPreferences is migrated to MasterKeyStore and purged from SharedPreferences', () async {
      // 1. Generate legacy 256-bit AES master key
      final algorithm = AesGcm.with256bits();
      final legacyKey = await algorithm.newSecretKey();
      final legacyKeyBytes = await legacyKey.extract();
      final legacyBase64Key = base64Encode(legacyKeyBytes.bytes);

      // 2. Pre-populate legacy key and pre-encrypted payload into SharedPreferences
      await prefs.setString(kSecureStorageMasterKeyPref, legacyBase64Key);

      const secretText = 'LegacySecretDataBeforeV064Migration';
      final secretBox = await algorithm.encrypt(
        utf8.encode(secretText),
        secretKey: legacyKey,
      );
      final envelope = {
        'v': 1,
        'cipher': base64Encode(secretBox.cipherText),
        'nonce': base64Encode(secretBox.nonce),
        'mac': base64Encode(secretBox.mac.bytes),
      };
      await prefs.setString('${kSecureStorageKeyPrefix}legacy_payload', jsonEncode(envelope));

      // 3. Mount fresh vault without pre-existing key
      final keyStore = InMemoryMasterKeyStore();
      expect(await keyStore.readMasterKey(), isNull);

      final storage = AesGcmSecureStorage(prefs, keyStore: keyStore);

      // 4. Read payload: should transparently decrypt and trigger migration
      final decrypted = await storage.read('legacy_payload');
      expect(decrypted, equals(secretText));

      // 5. Verify migration: key now exists in MasterKeyStore
      expect(await keyStore.readMasterKey(), equals(legacyBase64Key));

      // 6. Verify purge: legacy key is completely wiped from SharedPreferences
      expect(prefs.getString(kSecureStorageMasterKeyPref), isNull);
      expect(prefs.containsKey(kSecureStorageMasterKeyPref), isFalse);

      // 7. Verify subsequent writes continue to use the migrated key and keep SharedPreferences clean
      await storage.write('post_migration_key', 'PostMigrationValue');
      expect(prefs.containsKey(kSecureStorageMasterKeyPref), isFalse);
      expect(await storage.read('post_migration_key'), equals('PostMigrationValue'));
    });

    test('Wiping MasterKeyStore prevents decryption of existing ciphertext (zero key leakage)', () async {
      final keyStore = InMemoryMasterKeyStore();
      final storage1 = AesGcmSecureStorage(prefs, keyStore: keyStore);
      await storage1.write('ephemeral_token', 'SuperSecretToken');

      // Purge master key from vault
      await keyStore.deleteMasterKey();

      // Create new storage instance with the wiped vault
      final storage2 = AesGcmSecureStorage(prefs, keyStore: keyStore);

      // Reading should now fail with auth exception because a new key will be generated
      expect(
        () => storage2.read('ephemeral_token'),
        throwsA(isA<SecureStorageAuthException>()),
      );
    });

    test('FlutterSecureStorageMasterKeyStore headless fallback works safely in tests without channel hanging', () async {
      final keyStore = FlutterSecureStorageMasterKeyStore();
      const sampleKey = 'sampleBase64MasterKey1234567890==';

      expect(await keyStore.readMasterKey(), isNull);
      await keyStore.writeMasterKey(sampleKey);
      expect(await keyStore.readMasterKey(), equals(sampleKey));

      await keyStore.deleteMasterKey();
      expect(await keyStore.readMasterKey(), isNull);
    });

    test('Transient keystore read error throws SecureStorageException and never overwrites master key (CRIT-1)', () async {
      final throwingKeyStore = _FailingMasterKeyStore();
      final storage = AesGcmSecureStorage(prefs, keyStore: throwingKeyStore);

      expect(
        () => storage.write('critical_key', 'critical_val'),
        throwsA(
          isA<SecureStorageException>().having(
            (e) => e.message,
            'message',
            contains('Failed to read master key from secure vault'),
          ),
        ),
      );

      // Verify writeMasterKey was NEVER called (no key overwrite)
      expect(throwingKeyStore.writeCalls, equals(0));

      // Verify SharedPreferences does NOT contain any generated master key
      expect(prefs.containsKey(kSecureStorageMasterKeyPref), isFalse);
    });

    test('Transient keystore read error during read() preserves existing ciphertext and throws SecureStorageException', () async {
      const testKey = 'existing_patient_data';
      await prefs.setString(
        '$kSecureStorageKeyPrefix$testKey',
        jsonEncode({'v': 1, 'cipher': 'dGVzdA==', 'nonce': 'dGVzdA==', 'mac': 'dGVzdA=='}),
      );

      final failingKeyStore = _FailingMasterKeyStore();
      final storage = AesGcmSecureStorage(prefs, keyStore: failingKeyStore);

      expect(
        () => storage.read(testKey),
        throwsA(
          isA<SecureStorageException>().having(
            (e) => e.message,
            'message',
            contains('Failed to read master key from secure vault'),
          ),
        ),
      );

      expect(failingKeyStore.writeCalls, equals(0));
      expect(prefs.containsKey(kSecureStorageMasterKeyPref), isFalse);
    });

    test('Riverpod Provider integration: secureStorageProvider uses masterKeyStoreProvider', () async {
      final testKeyStore = InMemoryMasterKeyStore();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          masterKeyStoreProvider.overrideWithValue(testKeyStore),
        ],
      );
      addTearDown(container.dispose);

      final storage = container.read(secureStorageProvider);
      await storage.write('provider_key', 'provider_value');

      expect(await storage.read('provider_key'), equals('provider_value'));
      expect(await testKeyStore.readMasterKey(), isNotNull);
      expect(prefs.containsKey(kSecureStorageMasterKeyPref), isFalse);
    });
  });

  group('InMemorySecureStorage Unit Tests', () {
    test('Basic CRUD operations work in memory', () async {
      final storage = InMemorySecureStorage();
      expect(await storage.read('foo'), isNull);
      expect(await storage.containsKey('foo'), isFalse);

      await storage.write('foo', 'bar');
      expect(await storage.read('foo'), equals('bar'));
      expect(await storage.containsKey('foo'), isTrue);

      await storage.delete('foo');
      expect(await storage.read('foo'), isNull);
      expect(await storage.containsKey('foo'), isFalse);
    });
  });
}

class _FailingMasterKeyStore implements MasterKeyStore {
  int writeCalls = 0;

  @override
  Future<String?> readMasterKey() async {
    throw Exception('Keystore daemon busy / device locked');
  }

  @override
  Future<void> writeMasterKey(String base64Key) async {
    writeCalls++;
  }

  @override
  Future<void> deleteMasterKey() async {}
}
