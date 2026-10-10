import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/storage/storage.dart';
import 'package:zenith/features/armory/armory.dart';

void main() {
  group('UserProfile Split Serialization', () {
    test('toNonSensitiveJson contains only equipment and experience level', () {
      final profile = UserProfile(
        availableEquipment: {Equipment.bodyweight, Equipment.pullUpBar},
        hasJointPain: true,
        femaleProfile: const FemaleProfile(
          userStatus: 'Trained_Female',
          cycleDay: 14,
          hasKneeDiscomfort: false,
          age: 29,
          hasJointPain: true,
        ),
        experienceLevel: ExperienceLevel.intermediate,
      );

      final nonSensitive = profile.toNonSensitiveJson();
      expect(nonSensitive.containsKey('availableEquipment'), isTrue);
      expect(nonSensitive.containsKey('experienceLevel'), isTrue);
      expect(nonSensitive.containsKey('hasJointPain'), isFalse);
      expect(nonSensitive.containsKey('femaleProfile'), isFalse);

      final equipmentList = nonSensitive['availableEquipment'] as List;
      expect(equipmentList, contains('pullUpBar'));
      expect(equipmentList, contains('bodyweight'));
      expect(nonSensitive['experienceLevel'], equals('intermediate'));
    });

    test('toSensitiveJson contains only joint pain and female profile telemetry', () {
      final profile = UserProfile(
        availableEquipment: {Equipment.bodyweight, Equipment.bands},
        hasJointPain: true,
        femaleProfile: const FemaleProfile(
          userStatus: 'Untrained_Female',
          cycleDay: 21,
          hasKneeDiscomfort: true,
          age: 32,
          hasJointPain: true,
        ),
        experienceLevel: ExperienceLevel.advanced,
      );

      final sensitive = profile.toSensitiveJson();
      expect(sensitive.containsKey('hasJointPain'), isTrue);
      expect(sensitive.containsKey('femaleProfile'), isTrue);
      expect(sensitive.containsKey('availableEquipment'), isFalse);
      expect(sensitive.containsKey('experienceLevel'), isFalse);

      expect(sensitive['hasJointPain'], isTrue);
      final femaleMap = sensitive['femaleProfile'] as Map<String, dynamic>;
      expect(femaleMap['cycleDay'], equals(21));
      expect(femaleMap['age'], equals(32));
      expect(femaleMap['hasKneeDiscomfort'], isTrue);
    });

    test('mergeSensitiveJson and fromSplitJson accurately reconstruct profile', () {
      final nonSensitive = {
        'availableEquipment': ['bodyweight', 'suspension'],
        'experienceLevel': 'beginner',
      };
      final sensitive = {
        'hasJointPain': true,
        'femaleProfile': {
          'userStatus': 'Untrained_Female',
          'cycleDay': 5,
          'hasKneeDiscomfort': false,
          'age': 27,
          'hasJointPain': true,
        },
      };

      final reconstructed = UserProfile.fromSplitJson(
        nonSensitive: nonSensitive,
        sensitive: sensitive,
      );

      expect(reconstructed.availableEquipment, contains(Equipment.suspension));
      expect(reconstructed.availableEquipment, contains(Equipment.bodyweight));
      expect(reconstructed.experienceLevel, equals(ExperienceLevel.beginner));
      expect(reconstructed.hasJointPain, isTrue);
      expect(reconstructed.femaleProfile, isNotNull);
      expect(reconstructed.femaleProfile!.cycleDay, equals(5));
      expect(reconstructed.femaleProfile!.age, equals(27));
    });
  });

  group('UserProfileNotifier Split Persistence & Secure Storage', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Persisting profile stores non-sensitive in SharedPreferences and sensitive in SecureStorage', () async {
      final secureStorage = AesGcmSecureStorage(prefs);
      final notifier = UserProfileNotifier(prefs, secureStorage);

      // Modify equipment and sensitive health indicators
      await notifier.toggleEquipment(Equipment.pullUpBar);
      await notifier.toggleCycleAutoregulation(cycleDay: 12, age: 31);
      await notifier.toggleJointProtection();
      await notifier.setExperienceLevel(ExperienceLevel.intermediate);

      // 1. Verify unencrypted SharedPreferences contains ONLY non-sensitive data
      final rawPrefs = prefs.getString(kUserProfileStorageKey);
      expect(rawPrefs, isNotNull);
      final decodedPrefs = jsonDecode(rawPrefs!) as Map<String, dynamic>;

      expect(decodedPrefs.containsKey('availableEquipment'), isTrue);
      expect(decodedPrefs.containsKey('experienceLevel'), isTrue);
      // STRICT REQUIREMENT: sensitive keys are NOT in plaintext SharedPreferences
      expect(decodedPrefs.containsKey('femaleProfile'), isFalse);
      expect(decodedPrefs.containsKey('hasJointPain'), isFalse);
      expect(rawPrefs, isNot(contains('Untrained_Female')));
      expect(rawPrefs, isNot(contains('cycleDay')));

      // 2. Verify SecureStorage contains sensitive data
      final rawSecure = await secureStorage.read(kSensitiveHealthStorageKey);
      expect(rawSecure, isNotNull);
      final decodedSecure = jsonDecode(rawSecure!) as Map<String, dynamic>;
      expect(decodedSecure['hasJointPain'], isTrue);
      expect(decodedSecure['femaleProfile']['cycleDay'], equals(12));
      expect(decodedSecure['femaleProfile']['age'], equals(31));
    });

    test('Transparent migration from legacy plaintext profile in SharedPreferences', () async {
      // Seed legacy plaintext profile with sensitive health data
      final legacyProfile = {
        'availableEquipment': ['bodyweight', 'towel'],
        'hasJointPain': true,
        'femaleProfile': {
          'userStatus': 'Untrained_Female',
          'cycleDay': 18,
          'hasKneeDiscomfort': true,
          'age': 30,
          'hasJointPain': true,
        },
        'experienceLevel': 'beginner',
      };
      await prefs.setString(kUserProfileStorageKey, jsonEncode(legacyProfile));

      final secureStorage = AesGcmSecureStorage(prefs);
      final notifier = UserProfileNotifier(prefs, secureStorage);

      // Initial synchronous state loads legacy settings without lag
      expect(notifier.state.hasJointPain, isTrue);
      expect(notifier.state.femaleProfile, isNotNull);
      expect(notifier.state.femaleProfile!.cycleDay, equals(18));
      expect(notifier.state.availableEquipment, contains(Equipment.towel));

      // Wait for migration to complete
      await notifier.initialized;

      // Sensitive telemetry must now be encrypted in SecureStorage
      final encryptedRaw = await secureStorage.read(kSensitiveHealthStorageKey);
      expect(encryptedRaw, isNotNull);
      final decodedEncrypted = jsonDecode(encryptedRaw!) as Map<String, dynamic>;
      expect(decodedEncrypted['hasJointPain'], isTrue);
      expect(decodedEncrypted['femaleProfile']['cycleDay'], equals(18));

      // Plaintext SharedPreferences must now be STRIPPED of sensitive keys
      final migratedPrefsRaw = prefs.getString(kUserProfileStorageKey)!;
      final migratedPrefs = jsonDecode(migratedPrefsRaw) as Map<String, dynamic>;
      expect(migratedPrefs.containsKey('femaleProfile'), isFalse);
      expect(migratedPrefs.containsKey('hasJointPain'), isFalse);
      expect(migratedPrefsRaw, isNot(contains('Untrained_Female')));
      expect(migratedPrefsRaw, isNot(contains('cycleDay')));

      // Equipment and experience level must remain intact
      expect(migratedPrefs['experienceLevel'], equals('beginner'));
      final eqList = migratedPrefs['availableEquipment'] as List;
      expect(eqList, contains('towel'));
    });

    test('App restart: second UserProfileNotifier instance hydrates sensitive data from SecureStorage', () async {
      final secureStorage = AesGcmSecureStorage(prefs);

      // Operator sets profile on launch 1
      final notifier1 = UserProfileNotifier(prefs, secureStorage);
      await notifier1.toggleEquipment(Equipment.bands);
      await notifier1.toggleCycleAutoregulation(cycleDay: 7, age: 25);
      await notifier1.toggleJointProtection();
      await notifier1.setExperienceLevel(ExperienceLevel.advanced);

      // Simulate app restart: launch 2 with fresh notifier
      final notifier2 = UserProfileNotifier(prefs, secureStorage);

      // Synchronous cold start loads non-sensitive settings immediately
      expect(notifier2.state.availableEquipment, contains(Equipment.bands));
      expect(notifier2.state.experienceLevel, equals(ExperienceLevel.advanced));

      // Await hydration of encrypted store
      await notifier2.initialized;

      // Sensitive health indicators are restored accurately
      expect(notifier2.state.hasJointPain, isTrue);
      expect(notifier2.state.femaleProfile, isNotNull);
      expect(notifier2.state.femaleProfile!.cycleDay, equals(7));
      expect(notifier2.state.femaleProfile!.age, equals(25));
    });

    test('UserProfileNotifier works seamlessly with InMemorySecureStorage', () async {
      final inMemoryStorage = InMemorySecureStorage();
      final notifier = UserProfileNotifier(prefs, inMemoryStorage);

      await notifier.toggleCycleAutoregulation(cycleDay: 10, age: 28);
      await notifier.initialized;

      expect(notifier.state.hasCycleAutoregulation, isTrue);
      expect(await inMemoryStorage.containsKey(kSensitiveHealthStorageKey), isTrue);

      final reloaded = UserProfileNotifier(prefs, inMemoryStorage);
      await reloaded.initialized;

      expect(reloaded.state.femaleProfile!.cycleDay, equals(10));
    });

    test('Concurrency safety: mutations during in-flight hydration do not overwrite or wipe sensitive data (BUG-1)', () async {
      // 1. Seed existing non-sensitive profile in SharedPreferences
      final nonSensitiveProfile = {
        'availableEquipment': ['bodyweight'],
        'experienceLevel': 'intermediate',
      };
      await prefs.setString(kUserProfileStorageKey, jsonEncode(nonSensitiveProfile));

      // 2. Seed sensitive health data in secure storage
      final sensitiveHealthData = {
        'hasJointPain': true,
        'femaleProfile': {
          'userStatus': 'Trained_Female',
          'cycleDay': 14,
          'hasKneeDiscomfort': false,
          'age': 29,
          'hasJointPain': true,
        },
      };

      final underlyingStorage = InMemorySecureStorage();
      await underlyingStorage.write(
        kSensitiveHealthStorageKey,
        jsonEncode(sensitiveHealthData),
      );

      final delayedStorage = _DelayedSecureStorage(
        underlyingStorage,
        delay: const Duration(milliseconds: 30),
      );

      // 3. Instantiate notifier - at construction, state only has non-sensitive data
      final notifier = UserProfileNotifier(prefs, delayedStorage);
      expect(notifier.state.femaleProfile, isNull);

      // 4. Immediately trigger a mutation while hydration is still in flight
      final mutationFuture = notifier.toggleEquipment(Equipment.pullUpBar);

      // 5. Await both the mutation and the initialization
      await mutationFuture;
      await notifier.initialized;

      // 6. Verify that sensitive health data was NOT wiped or overwritten with null
      expect(notifier.state.hasJointPain, isTrue);
      expect(notifier.state.femaleProfile, isNotNull);
      expect(notifier.state.femaleProfile!.cycleDay, equals(14));
      expect(notifier.state.femaleProfile!.age, equals(29));
      expect(notifier.state.availableEquipment, contains(Equipment.pullUpBar));

      // 7. Verify data-at-rest in secure storage retains the full sensitive telemetry
      final rawSecure = await underlyingStorage.read(kSensitiveHealthStorageKey);
      expect(rawSecure, isNotNull);
      final decodedSecure = jsonDecode(rawSecure!) as Map<String, dynamic>;
      expect(decodedSecure['hasJointPain'], isTrue);
      expect(decodedSecure['femaleProfile']['cycleDay'], equals(14));
    });
  });
}

class _DelayedSecureStorage implements SecureStorage {
  final SecureStorage _delegate;
  final Duration delay;

  _DelayedSecureStorage(this._delegate, {required this.delay});

  @override
  Future<String?> read(String key) async {
    await Future.delayed(delay);
    return _delegate.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    await Future.delayed(delay);
    return _delegate.write(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await Future.delayed(delay);
    return _delegate.delete(key);
  }

  @override
  Future<bool> containsKey(String key) async {
    await Future.delayed(delay);
    return _delegate.containsKey(key);
  }
}

