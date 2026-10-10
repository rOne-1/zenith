import 'package:flutter/foundation.dart';
import 'package:sbee/sbee.dart';

/// Self-declared training experience, captured during onboarding. Distinct
/// from SBEE's own automatic "Intermediate" status (earned via session
/// count + elapsed days, see `isIntermediateStatusProvider`) -- this is
/// what the athlete says about themselves on day one, before the engine has
/// any performance history to earn status from.
///
/// Only ever narrows the exercise pool, never widens it beyond what SBEE's
/// own earned-status system already allows: declaring `beginner` forces a
/// tighter tier cap up front; `intermediate`/`advanced` defer entirely to
/// SBEE's existing automatic behavior rather than granting an early unlock
/// self-report alone shouldn't be able to buy.
enum ExperienceLevel { beginner, intermediate, advanced }

/// Immutable user configuration capturing equipment inventory and physiological adaptations.
///
/// **Invariants**:
/// - `availableEquipment` ALWAYS contains [Equipment.bodyweight]. This ensures that minimal
///   calisthenic progressions and postural balance rules never fail.
@immutable
class UserProfile {
  final Set<Equipment> availableEquipment;
  final bool hasJointPain;
  final FemaleProfile? femaleProfile;
  final ExperienceLevel? experienceLevel;

  UserProfile({
    Set<Equipment> availableEquipment = const {Equipment.bodyweight},
    this.hasJointPain = false,
    this.femaleProfile,
    this.experienceLevel,
  }) : availableEquipment = Set.unmodifiable({
         ...availableEquipment,
         Equipment.bodyweight,
       });

  /// Default baseline profile for a new Zenith operator.
  static final UserProfile baseline = UserProfile();

  /// Whether cycle-based endocrine autoregulation is active.
  bool get hasCycleAutoregulation => femaleProfile != null;

  /// The difficulty-tier cap SBEE's generator should use in place of its
  /// own automatic beginner cap, or null to defer entirely to SBEE's
  /// existing behavior. Only a self-declared beginner narrows the band.
  int? get maxDifficultyTierOverride =>
      experienceLevel == ExperienceLevel.beginner ? 2 : null;

  /// Returns a new instance with updated properties.
  ///
  /// Note: [availableEquipment] will always retain [Equipment.bodyweight].
  UserProfile copyWith({
    Set<Equipment>? availableEquipment,
    bool? hasJointPain,
    FemaleProfile? Function()? femaleProfile,
    ExperienceLevel? Function()? experienceLevel,
  }) {
    return UserProfile(
      availableEquipment: availableEquipment ?? this.availableEquipment,
      hasJointPain: hasJointPain ?? this.hasJointPain,
      femaleProfile: femaleProfile != null
          ? femaleProfile()
          : this.femaleProfile,
      experienceLevel: experienceLevel != null
          ? experienceLevel()
          : this.experienceLevel,
    );
  }

  /// Serializes the profile to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'availableEquipment': availableEquipment.map((e) => e.name).toList(),
      'hasJointPain': hasJointPain,
      'femaleProfile': femaleProfile != null
          ? {
              'userStatus': femaleProfile!.userStatus,
              'cycleDay': femaleProfile!.cycleDay,
              'hasKneeDiscomfort': femaleProfile!.hasKneeDiscomfort,
              'age': femaleProfile!.age,
              'hasJointPain': femaleProfile!.hasJointPain,
            }
          : null,
      'experienceLevel': experienceLevel?.name,
    };
  }

  /// Serializes only non-sensitive configuration (equipment, experience level)
  /// safe for unencrypted storage in SharedPreferences.
  Map<String, dynamic> toNonSensitiveJson() {
    return {
      'availableEquipment': availableEquipment.map((e) => e.name).toList(),
      'experienceLevel': experienceLevel?.name,
    };
  }

  /// Serializes sensitive physiological telemetry (cycle tracking, joint discomfort)
  /// requiring encryption at rest via SecureStorage.
  Map<String, dynamic> toSensitiveJson() {
    return {
      'hasJointPain': hasJointPain,
      'femaleProfile': femaleProfile != null
          ? {
              'userStatus': femaleProfile!.userStatus,
              'cycleDay': femaleProfile!.cycleDay,
              'hasKneeDiscomfort': femaleProfile!.hasKneeDiscomfort,
              'age': femaleProfile!.age,
              'hasJointPain': femaleProfile!.hasJointPain,
            }
          : null,
    };
  }

  /// Merges sensitive physiological telemetry from a decrypted JSON map.
  UserProfile mergeSensitiveJson(Map<String, dynamic> json) {
    FemaleProfile? femaleProf;
    final rawFemale = json['femaleProfile'] as Map<String, dynamic>?;
    if (rawFemale != null) {
      femaleProf = FemaleProfile(
        userStatus: rawFemale['userStatus'] as String? ?? 'Untrained_Female',
        cycleDay: rawFemale['cycleDay'] as int? ?? 1,
        hasKneeDiscomfort: rawFemale['hasKneeDiscomfort'] as bool? ?? false,
        age: rawFemale['age'] as int? ?? 28,
        hasJointPain: rawFemale['hasJointPain'] as bool? ?? false,
      );
    }

    final hasFpKey = json.containsKey('femaleProfile');
    return copyWith(
      hasJointPain: json.containsKey('hasJointPain')
          ? (json['hasJointPain'] as bool? ?? false)
          : hasJointPain,
      femaleProfile: hasFpKey ? () => femaleProf : null,
    );
  }

  /// Deserializes a profile composed from separate non-sensitive and sensitive JSON maps.
  factory UserProfile.fromSplitJson({
    required Map<String, dynamic> nonSensitive,
    Map<String, dynamic>? sensitive,
  }) {
    final base = UserProfile.fromJson(nonSensitive);
    if (sensitive != null && sensitive.isNotEmpty) {
      return base.mergeSensitiveJson(sensitive);
    }
    return base;
  }

  /// Deserializes profile data from a JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawEquipment = json['availableEquipment'] as List<dynamic>? ?? [];
    final parsedEquipment = <Equipment>{};

    for (final item in rawEquipment) {
      if (item is String) {
        for (final val in Equipment.values) {
          if (val.name == item) {
            parsedEquipment.add(val);
            break;
          }
        }
      }
    }

    FemaleProfile? femaleProf;
    final rawFemale = json['femaleProfile'] as Map<String, dynamic>?;
    if (rawFemale != null) {
      femaleProf = FemaleProfile(
        userStatus: rawFemale['userStatus'] as String? ?? 'Untrained_Female',
        cycleDay: rawFemale['cycleDay'] as int? ?? 1,
        hasKneeDiscomfort: rawFemale['hasKneeDiscomfort'] as bool? ?? false,
        age: rawFemale['age'] as int? ?? 28,
        hasJointPain: rawFemale['hasJointPain'] as bool? ?? false,
      );
    }

    ExperienceLevel? parsedExperienceLevel;
    final rawExperienceLevel = json['experienceLevel'] as String?;
    if (rawExperienceLevel != null) {
      for (final level in ExperienceLevel.values) {
        if (level.name == rawExperienceLevel) {
          parsedExperienceLevel = level;
          break;
        }
      }
    }

    return UserProfile(
      availableEquipment: parsedEquipment,
      hasJointPain: json['hasJointPain'] as bool? ?? false,
      femaleProfile: femaleProf,
      experienceLevel: parsedExperienceLevel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          setEquals(availableEquipment, other.availableEquipment) &&
          hasJointPain == other.hasJointPain &&
          experienceLevel == other.experienceLevel &&
          _equalFemaleProfiles(femaleProfile, other.femaleProfile);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(availableEquipment),
    hasJointPain,
    experienceLevel,
    femaleProfile?.cycleDay,
    femaleProfile?.userStatus,
  );

  static bool _equalFemaleProfiles(FemaleProfile? a, FemaleProfile? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.userStatus == b.userStatus &&
        a.cycleDay == b.cycleDay &&
        a.hasKneeDiscomfort == b.hasKneeDiscomfort &&
        a.age == b.age &&
        a.hasJointPain == b.hasJointPain;
  }

  @override
  String toString() {
    return 'UserProfile(equipment: ${availableEquipment.map((e) => e.name).toSet()}, '
        'jointPain: $hasJointPain, cycleAutoreg: ${femaleProfile != null}, '
        'experienceLevel: $experienceLevel)';
  }
}
