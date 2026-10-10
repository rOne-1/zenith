import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/storage.dart';
import '../models/user_profile.dart';

/// Storage key for persisting non-sensitive user profile settings in unencrypted SharedPreferences.
const String kUserProfileStorageKey = 'zenith_user_profile';

/// Storage key for persisting sensitive physiological telemetry in encrypted SecureStorage.
const String kSensitiveHealthStorageKey = 'zenith_secure_health_profile';

/// StateNotifier that manages user inventory and physiological adaptation settings.
class UserProfileNotifier extends StateNotifier<UserProfile> {
  final SharedPreferences _prefs;
  final SecureStorage _secureStorage;
  late final Future<void> _initFuture;
  bool _hasMutated = false;

  /// Completes when asynchronous migration and secure storage hydration finishes.
  Future<void> get initialized => _initFuture;

  UserProfileNotifier(
    this._prefs, [
    SecureStorage? secureStorage,
  ])  : _secureStorage = secureStorage ?? AesGcmSecureStorage(_prefs),
        super(_loadInitialProfile(_prefs)) {
    _initFuture = _hydrateAndMigrate();
  }

  static UserProfile _loadInitialProfile(SharedPreferences prefs) {
    final rawJson = prefs.getString(kUserProfileStorageKey);
    if (rawJson != null) {
      try {
        final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
        return UserProfile.fromJson(decoded);
      } catch (_) {
        // Fall back to baseline on corrupt or invalid JSON
      }
    }
    return UserProfile.baseline;
  }

  Future<void> _hydrateAndMigrate() async {
    try {
      final rawPrefsJson = _prefs.getString(kUserProfileStorageKey);
      Map<String, dynamic>? legacyDecoded;
      bool isLegacy = false;

      if (rawPrefsJson != null) {
        try {
          final decoded = jsonDecode(rawPrefsJson) as Map<String, dynamic>;
          if (decoded.containsKey('femaleProfile') ||
              decoded.containsKey('hasJointPain')) {
            isLegacy = true;
            legacyDecoded = decoded;
          }
        } catch (_) {}
      }

      final hasSecure =
          await _secureStorage.containsKey(kSensitiveHealthStorageKey);

      if (isLegacy && legacyDecoded != null) {
        // Transparent migration:
        // 1. If secure storage has not yet captured sensitive telemetry, write it now.
        if (!hasSecure) {
          final sensitiveData = {
            'hasJointPain': legacyDecoded['hasJointPain'] as bool? ?? false,
            'femaleProfile': legacyDecoded['femaleProfile'],
          };
          await _secureStorage.write(
            kSensitiveHealthStorageKey,
            jsonEncode(sensitiveData),
          );
        } else {
          // Secure storage already exists; hydrate from encrypted store.
          final secureRaw =
              await _secureStorage.read(kSensitiveHealthStorageKey);
          if (secureRaw != null && !_hasMutated) {
            final sensitiveDecoded =
                jsonDecode(secureRaw) as Map<String, dynamic>;
            state = state.mergeSensitiveJson(sensitiveDecoded);
          }
        }

        // 2. Strip sensitive keys from plaintext SharedPreferences.
        final nonSensitive = state.toNonSensitiveJson();
        await _prefs.setString(
          kUserProfileStorageKey,
          jsonEncode(nonSensitive),
        );
      } else if (hasSecure) {
        // Standard hydration: read encrypted sensitive health data.
        final secureRaw =
            await _secureStorage.read(kSensitiveHealthStorageKey);
        if (secureRaw != null && !_hasMutated) {
          final sensitiveDecoded =
              jsonDecode(secureRaw) as Map<String, dynamic>;
          state = state.mergeSensitiveJson(sensitiveDecoded);
        }
      }
    } catch (_) {
      // Gracefully maintain current state on hydration error
    }
  }

  Future<void> _persist(UserProfile profile) async {
    await _initFuture;
    _hasMutated = true;
    state = profile;

    // 1. Non-sensitive settings in SharedPreferences for instantaneous synchronous cold-start
    final nonSensitiveJson = jsonEncode(profile.toNonSensitiveJson());
    await _prefs.setString(kUserProfileStorageKey, nonSensitiveJson);

    // 2. Sensitive health telemetry encrypted at rest via SecureStorage
    final sensitiveJson = jsonEncode(profile.toSensitiveJson());
    await _secureStorage.write(kSensitiveHealthStorageKey, sensitiveJson);
  }

  /// Toggles an equipment piece in the user's inventory.
  ///
  /// **Safety Invariant**: [Equipment.bodyweight] can NEVER be removed.
  Future<void> toggleEquipment(Equipment equipment) async {
    await _initFuture;
    if (equipment == Equipment.bodyweight) {
      // Bodyweight is immutable anchor; no-op.
      return;
    }

    final currentEquipment = Set<Equipment>.from(state.availableEquipment);
    if (currentEquipment.contains(equipment)) {
      currentEquipment.remove(equipment);
    } else {
      currentEquipment.add(equipment);
    }

    final updated = state.copyWith(availableEquipment: currentEquipment);
    await _persist(updated);
  }

  /// Toggles joint protection mode (excluding high-impact plyometrics).
  Future<void> toggleJointProtection() async {
    await _initFuture;
    final newJointPain = !state.hasJointPain;
    FemaleProfile? updatedFemale;
    if (state.femaleProfile != null) {
      final fp = state.femaleProfile!;
      updatedFemale = FemaleProfile(
        userStatus: fp.userStatus,
        cycleDay: fp.cycleDay,
        hasKneeDiscomfort: fp.hasKneeDiscomfort,
        age: fp.age,
        hasJointPain: newJointPain,
      );
    }

    final updated = state.copyWith(
      hasJointPain: newJointPain,
      femaleProfile: () => updatedFemale,
    );
    await _persist(updated);
  }

  /// Toggles cycle-based endocrine autoregulation.
  Future<void> toggleCycleAutoregulation({
    int cycleDay = 1,
    int age = 28,
  }) async {
    await _initFuture;
    if (state.hasCycleAutoregulation) {
      final updated = state.copyWith(femaleProfile: () => null);
      await _persist(updated);
    } else {
      final newProfile = FemaleProfile(
        userStatus: 'Untrained_Female',
        cycleDay: cycleDay,
        hasKneeDiscomfort: false,
        age: age,
        hasJointPain: state.hasJointPain,
      );
      final updated = state.copyWith(femaleProfile: () => newProfile);
      await _persist(updated);
    }
  }

  /// Sets the self-declared training experience level captured at onboarding.
  Future<void> setExperienceLevel(ExperienceLevel level) async {
    await _initFuture;
    final updated = state.copyWith(experienceLevel: () => level);
    await _persist(updated);
  }

  /// Directly updates the menstrual cycle day if cycle autoregulation is enabled.
  Future<void> setCycleDay(int cycleDay) async {
    await _initFuture;
    if (state.femaleProfile == null) return;
    final fp = state.femaleProfile!;
    final updatedFemale = FemaleProfile(
      userStatus: fp.userStatus,
      cycleDay: cycleDay.clamp(1, 35),
      hasKneeDiscomfort: fp.hasKneeDiscomfort,
      age: fp.age,
      hasJointPain: fp.hasJointPain,
    );
    final updated = state.copyWith(femaleProfile: () => updatedFemale);
    await _persist(updated);
  }
}

/// Provider managing the active operator's profile and equipment configuration.
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      final secureStorage = ref.watch(secureStorageProvider);
      return UserProfileNotifier(prefs, secureStorage);
    });
