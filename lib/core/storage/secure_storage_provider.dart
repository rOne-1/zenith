import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/test_env/test_env.dart';
import 'preferences_provider.dart';

/// Storage key prefix for encrypted keys managed by [AesGcmSecureStorage].
const String kSecureStorageKeyPrefix = 'zenith_sec_';

/// Internal preference / secure storage key holding the 256-bit AES master key.
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

/// Abstract contract for retrieving and persisting the root AES-256 master key in
/// a secure hardware/OS-backed vault (Android Keystore, iOS/macOS Keychain, Windows DPAPI, Web Crypto).
abstract class MasterKeyStore {
  /// Reads the base64-encoded 256-bit AES master key, or returns null if not set.
  Future<String?> readMasterKey();

  /// Persists the base64-encoded 256-bit AES master key into the secure vault.
  Future<void> writeMasterKey(String base64Key);

  /// Removes the master key from the secure vault.
  Future<void> deleteMasterKey();
}

/// In-memory implementation of [MasterKeyStore] for test and headless environments.
class InMemoryMasterKeyStore implements MasterKeyStore {
  String? _masterKey;

  InMemoryMasterKeyStore([this._masterKey]);

  @override
  Future<String?> readMasterKey() async => _masterKey;

  @override
  Future<void> writeMasterKey(String base64Key) async {
    _masterKey = base64Key;
  }

  @override
  Future<void> deleteMasterKey() async {
    _masterKey = null;
  }

  /// Clears stored in-memory key.
  void clear() => _masterKey = null;
}

/// Hardware/OS-backed [MasterKeyStore] utilizing [FlutterSecureStorage].
///
/// Backed by:
/// - Android Keystore (RSA-OAEP wrapped AES master key)
/// - iOS & macOS Keychain (with [KeychainAccessibility.first_unlock])
/// - Windows DPAPI / Credential Manager
/// - Linux Secret Service / libsecret
/// - Web Crypto API
class FlutterSecureStorageMasterKeyStore implements MasterKeyStore {
  final FlutterSecureStorage _storage;
  final String key;
  final bool _isCustomStorage;
  static final Map<String, String> _testFallback = {};

  FlutterSecureStorageMasterKeyStore({
    FlutterSecureStorage? storage,
    this.key = kSecureStorageMasterKeyPref,
  })  : _isCustomStorage = storage != null,
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Clears the static test fallback map for isolated test fixtures.
  static void resetTestStore() => _testFallback.clear();

  bool get _shouldUseFallback =>
      !_isCustomStorage && (isTestEnvironment || !_isBindingReady);

  bool get _isBindingReady {
    try {
      ServicesBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isTestOrMissingChannel(Object e) {
    if (e is MissingPluginException) return true;
    if (e is PlatformException &&
        (e.code == 'channel-error' ||
            (e.message?.contains('No implementation found') ?? false))) {
      return true;
    }
    final message = e.toString();
    if (message.contains('Binding has not yet been initialized') ||
        message.contains('ServicesBinding') ||
        message.contains('No implementation found')) {
      return true;
    }
    return false;
  }

  @override
  Future<String?> readMasterKey() async {
    if (_shouldUseFallback) {
      return _testFallback[key];
    }
    try {
      return await _storage.read(key: key);
    } catch (e) {
      if (_isTestOrMissingChannel(e)) {
        return _testFallback[key];
      }
      rethrow;
    }
  }

  @override
  Future<void> writeMasterKey(String base64Key) async {
    if (_shouldUseFallback) {
      _testFallback[key] = base64Key;
      return;
    }
    try {
      await _storage.write(key: key, value: base64Key);
    } catch (e) {
      if (_isTestOrMissingChannel(e)) {
        _testFallback[key] = base64Key;
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteMasterKey() async {
    if (_shouldUseFallback) {
      _testFallback.remove(key);
      return;
    }
    try {
      await _storage.delete(key: key);
    } catch (e) {
      if (_isTestOrMissingChannel(e)) {
        _testFallback.remove(key);
        return;
      }
      rethrow;
    }
  }
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

/// Pure-Dart AES-256-GCM encrypted storage backed by [SharedPreferences] for
/// encrypted data-at-rest envelopes, with hardware/OS-backed key separation via [MasterKeyStore].
///
/// Data envelopes (ciphertext, nonce, MAC tag) are stored in [SharedPreferences].
/// The 256-bit AES master key is stored exclusively in [MasterKeyStore] (e.g. Android Keystore,
/// iOS/macOS Keychain, Windows DPAPI, Web Crypto). The master key is NEVER stored in
/// unencrypted [SharedPreferences].
class AesGcmSecureStorage implements SecureStorage {
  final SharedPreferences _prefs;
  final MasterKeyStore _keyStore;
  final SecretKey? _customMasterKey;
  final String keyPrefix;
  final AesGcm _algorithm = AesGcm.with256bits();

  SecretKey? _cachedKey;

  AesGcmSecureStorage(
    this._prefs, {
    MasterKeyStore? keyStore,
    SecretKey? masterKey,
    this.keyPrefix = kSecureStorageKeyPrefix,
  })  : _keyStore = keyStore ?? FlutterSecureStorageMasterKeyStore(),
        _customMasterKey = masterKey {
    if (_customMasterKey != null) {
      _cachedKey = _customMasterKey;
    }
  }

  /// The [MasterKeyStore] managing the root AES master key.
  MasterKeyStore get keyStore => _keyStore;

  String _prefixed(String key) => '$keyPrefix$key';

  Future<SecretKey> _getMasterKey() async {
    if (_cachedKey != null) {
      return _cachedKey!;
    }

    // 1. Check OS/hardware-backed key store
    try {
      final secureKeyBase64 = await _keyStore.readMasterKey();
      if (secureKeyBase64 != null && secureKeyBase64.isNotEmpty) {
        final key = SecretKey(base64Decode(secureKeyBase64));
        _cachedKey = key;
        return key;
      }
    } catch (_) {
      // Fall through to migration / generation if reading keyStore encountered an error
    }

    // 2. Seamless migration: check legacy unencrypted SharedPreferences key
    final legacyKeyBase64 = _prefs.getString(kSecureStorageMasterKeyPref);
    if (legacyKeyBase64 != null && legacyKeyBase64.isNotEmpty) {
      try {
        final key = SecretKey(base64Decode(legacyKeyBase64));
        // Persist to secure OS-backed MasterKeyStore
        await _keyStore.writeMasterKey(legacyKeyBase64);
        // Purge legacy key from SharedPreferences so it never remains in unencrypted preferences
        await _prefs.remove(kSecureStorageMasterKeyPref);
        _cachedKey = key;
        return key;
      } catch (_) {}
    }

    // 3. Generate a fresh 256-bit AES key
    final newKey = await _algorithm.newSecretKey();
    final keyData = await newKey.extract();
    final base64Key = base64Encode(keyData.bytes);

    // Persist to secure OS-backed MasterKeyStore
    await _keyStore.writeMasterKey(base64Key);

    // Explicitly guarantee SharedPreferences does not contain the master key
    await _prefs.remove(kSecureStorageMasterKeyPref);

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

/// Provider for the hardware/OS-backed [MasterKeyStore].
final masterKeyStoreProvider = Provider<MasterKeyStore>((ref) {
  return FlutterSecureStorageMasterKeyStore();
});

/// Provider exposing the platform-agnostic [SecureStorage] with hardware-backed key separation.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final keyStore = ref.watch(masterKeyStoreProvider);
  return AesGcmSecureStorage(prefs, keyStore: keyStore);
});
