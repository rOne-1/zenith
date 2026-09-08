import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import 'bootstrap_catalog.dart';
import 'database_provider.dart';

/// Primary SBEE Engine provider initialized with Drift repositories and
/// the baseline exercise graph.
final sbeeEngineProvider = Provider<SbeeEngine>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final progressionRepo = ref.watch(progressionRepositoryProvider);
  return SbeeEngine(
    sessionRepository: sessionRepo,
    progressionRepository: progressionRepo,
    exerciseGraph: baselineExerciseGraph,
  );
});

/// Startup probe provider that inspects persistence for any active,
/// incomplete session left over from a previous run or unexpected termination.
final activeSessionResumeProvider = FutureProvider<SessionStreamManager?>((
  ref,
) async {
  final engine = ref.watch(sbeeEngineProvider);
  return engine.resumeActiveSession();
});

/// High-level service wrapping [SbeeEngine] operations for presentation layers.
class SbeeService {
  final SbeeEngine _engine;
  final Ref _ref;

  const SbeeService(this._engine, this._ref);

  /// Generates the next periodized workout session according to SBEE principles.
  Future<WorkoutSession> generateNextWorkout({
    String userId = 'zenith_operator',
    DateTime? currentTime,
    Set<Equipment> availableEquipment = const {Equipment.bodyweight},
    FemaleProfile? femaleProfile,
    bool hasJointPain = false,
  }) {
    return _engine.generateNextWorkout(
      userId: userId,
      currentTime: currentTime ?? DateTime.now(),
      availableEquipment: availableEquipment,
      femaleProfile: femaleProfile,
      hasJointPain: hasJointPain,
    );
  }

  /// Instantiates an active [SessionStreamManager] with incremental persistence.
  SessionStreamManager createWorkoutSession({required WorkoutSession session}) {
    return _engine.createWorkoutSession(session: session);
  }

  /// Checks if an active session can be resumed.
  Future<SessionStreamManager?> resumeActiveSession() {
    return _engine.resumeActiveSession();
  }

  /// Explicitly discards an incomplete active session from persistence.
  Future<void> discardActiveSession() async {
    await _engine.discardActiveSession();
    _ref.invalidate(activeSessionResumeProvider);
  }
}

/// Provider for the high-level [SbeeService].
final sbeeServiceProvider = Provider<SbeeService>((ref) {
  final engine = ref.watch(sbeeEngineProvider);
  return SbeeService(engine, ref);
});
