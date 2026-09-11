import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../engine/engine.dart';
import '../../armory/models/user_profile.dart';
import '../../armory/providers/user_profile_provider.dart';

/// Clock provider allowing deterministic time injection in tests and preview caching.
final currentClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now(),
);

/// Service that maintains a stable, day-level cached candidate workout preview.
///
/// **Design Invariant**:
/// - Caches the candidate [WorkoutSession] keyed by calendar day (`year, month, day`)
///   and [UserProfile] equipment & physiology configuration.
/// - Navigating between tabs or screens never randomly re-shuffles or regenerates
///   the candidate workout for the day.
/// - Invalidation triggers:
///   1. Calendar day rollover.
///   2. Modification of equipment inventory or physiology toggles in Armory.
///   3. Explicit session completion or discard.
class WorkoutPreviewService {
  final SbeeService _sbeeService;

  WorkoutSession? _cachedSession;
  DateTime? _cachedDay;
  UserProfile? _cachedProfile;

  WorkoutPreviewService(this._sbeeService);

  WorkoutSession? get cachedSession => _cachedSession;
  DateTime? get cachedDay => _cachedDay;

  /// Validates if the current cache is fresh for the given [profile] and [currentTime].
  bool isCacheValid({required UserProfile profile, DateTime? currentTime}) {
    if (_cachedSession == null || _cachedDay == null) return false;

    final targetTime = currentTime ?? DateTime.now();
    final targetDay = DateTime(
      targetTime.year,
      targetTime.month,
      targetTime.day,
    );

    if (!_cachedDay!.isAtSameMomentAs(targetDay)) return false;
    // UserProfile's own == already does structural equipment/joint-pain/
    // femaleProfile comparison (including FemaleProfile field-by-field,
    // since that SBEE class has no == of its own) -- comparing the whole
    // profile here instead of three separately-cached fields means this
    // can't drift out of sync with what UserProfile itself considers equal.
    if (_cachedProfile != profile) return false;

    return true;
  }

  /// Returns the cached candidate session if valid; otherwise generates a new one.
  Future<WorkoutSession> getOrGeneratePreview({
    required UserProfile profile,
    DateTime? currentTime,
    bool forceRefresh = false,
  }) async {
    final now = currentTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!forceRefresh && isCacheValid(profile: profile, currentTime: now)) {
      return _cachedSession!;
    }

    final session = await _sbeeService.generateNextWorkout(
      currentTime: now,
      availableEquipment: profile.availableEquipment,
      femaleProfile: profile.femaleProfile,
      hasJointPain: profile.hasJointPain,
    );

    _cachedSession = session;
    _cachedDay = today;
    _cachedProfile = profile;

    return session;
  }

  /// Explicitly clears the cached candidate workout.
  void invalidateCache() {
    _cachedSession = null;
    _cachedDay = null;
    _cachedProfile = null;
  }
}

/// Provider for the [WorkoutPreviewService] instance.
final workoutPreviewServiceProvider = Provider<WorkoutPreviewService>((ref) {
  final sbeeService = ref.watch(sbeeServiceProvider);
  return WorkoutPreviewService(sbeeService);
});

/// AsyncNotifier managing the active candidate workout preview.
class WorkoutPreviewNotifier extends AsyncNotifier<WorkoutSession?> {
  @override
  Future<WorkoutSession?> build() async {
    final profile = ref.watch(userProfileProvider);
    final service = ref.watch(workoutPreviewServiceProvider);
    final clock = ref.watch(currentClockProvider);
    final now = clock();

    return service.getOrGeneratePreview(profile: profile, currentTime: now);
  }

  /// Forces re-generation of the candidate workout preview.
  Future<WorkoutSession?> refreshPreview({DateTime? currentTime}) async {
    final service = ref.read(workoutPreviewServiceProvider);
    final profile = ref.read(userProfileProvider);
    final clock = ref.read(currentClockProvider);
    final now = currentTime ?? clock();

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return service.getOrGeneratePreview(
        profile: profile,
        currentTime: now,
        forceRefresh: true,
      );
    });
    return state.value;
  }

  /// Invalidates the cache and forces a fresh query.
  void invalidate() {
    final service = ref.read(workoutPreviewServiceProvider);
    service.invalidateCache();
    ref.invalidateSelf();
  }
}

/// Primary Riverpod provider for the candidate workout preview.
final workoutPreviewProvider =
    AsyncNotifierProvider<WorkoutPreviewNotifier, WorkoutSession?>(
      WorkoutPreviewNotifier.new,
    );
