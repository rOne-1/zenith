import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_provider.dart';

/// Storage key prefix for encrypted keys managed by [AesGcmSecureStorage].
const String kSecureStorageKeyPrefix = 'zenith_sec_';

/// Internal preference key holding the 256-bit AES master key.
const String kSecureStorageMasterKeyPref = 'zenith_sec_master_key_v1';

/// Exception thrown when secure storage operations fail.
class SecureStorageException implements Exception {
  final String message;
  const SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}

/// Exception thrown when cryptographic authentication or MAC verification fails.
class SecureStorageAuthException extends SecureStorageException {
  const SecureStorageAuthException(super.message);

  @override
  String toString() => 'SecureStorageAuthException: $message';
}

/// Abstract contract for key-value encrypted storage.
abstract class SecureStorage {
  /// Reads and decrypts the value stored at [key], or null if absent.
  Future<String?> read(String key);

  /// Encrypts and persists [value] at [key].
  Future<void> write(String key, String value);

  /// Removes the stored value at [key].
  Future<void> delete(String key);

  /// Checks whether [key] exists in storage.
  Future<bool> containsKey(String key);
}

/// In-memory implementation of [SecureStorage] for fast testing without encryption.
class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _data;

  InMemorySecureStorage([Map<String, String>? initialData])
      : _data = initialData != null ? Map.from(initialData) : {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  /// Clears all stored in-memory keys.
  void clear() => _data.clear();
}

/// Pure-Dart AES-256-GCM encrypted storage backed by [SharedPreferences].
///
/// Ensures zero native OS keychain dependencies or IPC hangs across web, desktop,
/// and headless test environments (`flutter test`).
class AesGcmSecureStorage implements SecureStorage {
  final SharedPreferences _prefs;
  final SecretKey? _customMasterKey;
  final String keyPrefix;
  final AesGcm _algorithm = AesGcm.with256bits();

  SecretKey? _cachedKey;

  AesGcmSecureStorage(
    this._prefs, {
    SecretKey? masterKey,
    this.keyPrefix = kSecureStorageKeyPrefix,
  }) : _customMasterKey = masterKey {
    if (_customMasterKey != null) {
      _cachedKey = _customMasterKey;
    } else {
      final existingKey = _prefs.getString(kSecureStorageMasterKeyPref);
      if (existingKey != null) {
        try {
          _cachedKey = SecretKey(base64Decode(existingKey));
        } catch (_) {}
      }
    }
  }

  String _prefixed(String key) => '$keyPrefix$key';

  Future<SecretKey> _getMasterKey() async {
    if (_cachedKey != null) {
      return _cachedKey!;
    }
    final existing = _prefs.getString(kSecureStorageMasterKeyPref);
    if (existing != null) {
      try {
        final key = SecretKey(base64Decode(existing));
        _cachedKey = key;
        return key;
      } catch (_) {}
    }

    final newKey = await _algorithm.newSecretKey();
    final keyData = await newKey.extract();
    await _prefs.setString(
      kSecureStorageMasterKeyPref,
      base64Encode(keyData.bytes),
    );
    _cachedKey = newKey;
    return newKey;
  }

  @override
  Future<String?> read(String key) async {
    final rawEnvelope = _prefs.getString(_prefixed(key));
    if (rawEnvelope == null) return null;

    try {
      final decoded = jsonDecode(rawEnvelope) as Map<String, dynamic>;
      final version = decoded['v'] as int?;
      if (version != 1) {
        throw SecureStorageException('Unsupported payload version: $version');
      }

      final cipherText = base64Decode(decoded['cipher'] as String);
      final nonce = base64Decode(decoded['nonce'] as String);
      final macBytes = base64Decode(decoded['mac'] as String);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final keyObj = await _getMasterKey();
      final clearBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: keyObj,
      );

      return utf8.decode(clearBytes);
    } on SecretBoxAuthenticationError {
      throw SecureStorageAuthException(
        'Integrity verification failed for key "$key". Data may be tampered or master key altered.',
      );
    } on SecureStorageException {
      rethrow;
    } catch (e) {
      throw SecureStorageException(
        'Failed to read or decrypt key "$key": $e',
      );
    }
  }

  @override
  Future<void> write(String key, String value) async {
    final keyObj = await _getMasterKey();
    final clearBytes = utf8.encode(value);

    final secretBox = await _algorithm.encrypt(
      clearBytes,
      secretKey: keyObj,
    );

    final envelope = <String, dynamic>{
      'v': 1,
      'cipher': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    await _prefs.setString(_prefixed(key), jsonEncode(envelope));
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(_prefixed(key));
  }

  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(_prefixed(key));
  }
}

/// Provider exposing the platform-agnostic, zero-hang [SecureStorage].
final secureStorageProvider = Provider<SecureStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AesGcmSecureStorage(prefs);
});
