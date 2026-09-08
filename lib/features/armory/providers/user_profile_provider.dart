import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/district_registry.dart';
import '../models/user_profile.dart';

/// Storage key for persisting the user's armory profile.
const String kUserProfileStorageKey = 'zenith_user_profile';

/// StateNotifier that manages user inventory and physiological adaptation settings.
class UserProfileNotifier extends StateNotifier<UserProfile> {
  final SharedPreferences _prefs;

  UserProfileNotifier(this._prefs) : super(_loadInitialProfile(_prefs));

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

  Future<void> _persist(UserProfile profile) async {
    state = profile;
    final jsonString = jsonEncode(profile.toJson());
    await _prefs.setString(kUserProfileStorageKey, jsonString);
  }

  /// Toggles an equipment piece in the user's inventory.
  ///
  /// **Safety Invariant**: [Equipment.bodyweight] can NEVER be removed.
  Future<void> toggleEquipment(Equipment equipment) async {
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

  /// Directly updates the menstrual cycle day if cycle autoregulation is enabled.
  Future<void> setCycleDay(int cycleDay) async {
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
      return UserProfileNotifier(prefs);
    });
