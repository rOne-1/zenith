import 'package:flutter/foundation.dart';
import 'package:sbee/sbee.dart';

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

  UserProfile({
    Set<Equipment> availableEquipment = const {Equipment.bodyweight},
    this.hasJointPain = false,
    this.femaleProfile,
  }) : availableEquipment = Set.unmodifiable({
         ...availableEquipment,
         Equipment.bodyweight,
       });

  /// Default baseline profile for a new Zenith operator.
  static final UserProfile baseline = UserProfile();

  /// Whether cycle-based endocrine autoregulation is active.
  bool get hasCycleAutoregulation => femaleProfile != null;

  /// Returns a new instance with updated properties.
  ///
  /// Note: [availableEquipment] will always retain [Equipment.bodyweight].
  UserProfile copyWith({
    Set<Equipment>? availableEquipment,
    bool? hasJointPain,
    FemaleProfile? Function()? femaleProfile,
  }) {
    return UserProfile(
      availableEquipment: availableEquipment ?? this.availableEquipment,
      hasJointPain: hasJointPain ?? this.hasJointPain,
      femaleProfile: femaleProfile != null
          ? femaleProfile()
          : this.femaleProfile,
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
    };
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

    return UserProfile(
      availableEquipment: parsedEquipment,
      hasJointPain: json['hasJointPain'] as bool? ?? false,
      femaleProfile: femaleProf,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          setEquals(availableEquipment, other.availableEquipment) &&
          hasJointPain == other.hasJointPain &&
          _equalFemaleProfiles(femaleProfile, other.femaleProfile);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(availableEquipment),
    hasJointPain,
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
        'jointPain: $hasJointPain, cycleAutoreg: ${femaleProfile != null})';
  }
}
