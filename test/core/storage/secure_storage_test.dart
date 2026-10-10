import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/storage/storage.dart';

void main() {
  group('AesGcmSecureStorage Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
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
