import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../engine/engine.dart';

/// A single exercise adaptation entry presenting Kenneth Miller 5-variable progression
/// and competency tier metrics.
class MillerAdaptationItem {
  final String exerciseId;
  final String exerciseName;
  final MovementPattern pattern;
  final MillerVariables variables;
  final int competencyLevel;
  final DateTime lastPerformed;

  const MillerAdaptationItem({
    required this.exerciseId,
    required this.exerciseName,
    required this.pattern,
    required this.variables,
    required this.competencyLevel,
    required this.lastPerformed,
  });

  /// Formatted competency tier string (e.g. "TIER 02").
  String get tierLabel => 'TIER 0$competencyLevel';

  /// Mastery classification title based on competency level.
  ///
  /// SBEE's `ExerciseProgression.competencyLevel` only ever produces 1, 2,
  /// or 3 (Beginner/Intermediate/Advanced -- monotonic, derived from
  /// completed-set counts in `SbeeEngine`). There is no 4-6 to classify.
  String get masteryTitle {
    switch (competencyLevel) {
      case 1:
        return 'NOVICE';
      case 2:
        return 'PROFICIENT';
      case 3:
      default:
        return 'ADVANCED';
    }
  }

  /// True if any variable has been progressed beyond its baseline (level 1).
  bool get hasAdvancedVariables =>
      variables.load > 1 ||
      variables.bodyPosition > 1 ||
      variables.rom > 1 ||
      variables.height > 1 ||
      variables.tempo > 1;
}

/// Represents an historical adaptation or promotion event recorded in the training ledger.
class PromotionEvent {
  final String exerciseName;
  final String variableDelta;
  final String description;
  final DateTime timestamp;

  const PromotionEvent({
    required this.exerciseName,
    required this.variableDelta,
    required this.description,
    required this.timestamp,
  });
}

/// Aggregated state for the Kenneth Miller Adaptation History Ledger.
class AdaptationLedgerState {
  final List<MillerAdaptationItem> adaptations;
  final List<PromotionEvent> recentPromotions;

  const AdaptationLedgerState({
    required this.adaptations,
    required this.recentPromotions,
  });

  bool get isEmpty => adaptations.isEmpty;

  /// Total Miller-variable upgrades across every tracked exercise (each
  /// level above baseline counts as one upgrade). Derived from
  /// [adaptations] rather than stored separately, so it can never drift
  /// from the items it summarizes.
  int get totalVariablesUpgraded => adaptations.fold(
    0,
    (sum, item) =>
        sum +
        (item.variables.load - 1) +
        (item.variables.bodyPosition - 1) +
        (item.variables.rom - 1) +
        (item.variables.height - 1) +
        (item.variables.tempo - 1),
  );

  /// The highest competency tier among all tracked exercises, or 1 (the
  /// baseline tier) if there are none.
  int get highestCompetencyTier => adaptations.isEmpty
      ? 1
      : adaptations
            .map((a) => a.competencyLevel)
            .reduce((a, b) => a > b ? a : b);
}

/// Service that coordinates with [ProgressionRepository] and [SessionRepository]
/// to construct the Kenneth Miller Adaptation History Ledger.
class AdaptationLedgerService {
  final ProgressionRepository _progressionRepository;
  final SessionRepository _sessionRepository;

  const AdaptationLedgerService(
    this._progressionRepository,
    this._sessionRepository,
  );

  /// Resolves the comprehensive adaptation state across all tracked exercises.
  Future<AdaptationLedgerState> getLedgerState({DateTime? currentTime}) async {
    final now = currentTime ?? DateTime.now();
    final lookbackStart = now.subtract(const Duration(days: 30));

    // Independent reads -- run concurrently rather than one after the other.
    final results = await Future.wait([
      _progressionRepository.getAllProgressions(),
      _sessionRepository.getSessionsInDateRange(lookbackStart, now),
    ]);
    final progressions = results[0] as List<ExerciseProgression>;
    final recentSessions = results[1] as List<WorkoutSession>;

    // Built once and reused for every lookup below, instead of re-scanning
    // both catalogs (ExerciseGraph.findById is a linear scan) per item.
    final exerciseById = <String, Exercise>{
      for (final e in baselineExerciseGraph.exercises) e.id: e,
      for (final e in expandedExerciseGraph.exercises) e.id: e,
    };

    final List<MillerAdaptationItem> items = [];

    if (progressions.isNotEmpty) {
      for (final prog in progressions) {
        final exercise = exerciseById[prog.exerciseId];

        // An unresolvable id means the progression repository and the
        // current catalog have drifted (e.g. a removed/renamed exercise) --
        // a data-integrity mismatch, not a display nicety. Fall back to the
        // raw id verbatim (as `active_session_controller.dart`'s own
        // exercise-name fallback already does), rather than fabricating a
        // plausible-looking title-cased name that would hide the mismatch.
        // `movementPattern` has no "unknown" value to fall back to instead
        // (SBEE's own closed enum), so this entry unavoidably renders under
        // an arbitrary pattern -- the visibly-raw id is what actually
        // surfaces the mismatch.
        final name = exercise?.name ?? prog.exerciseId;
        final pattern = exercise?.movementPattern ?? MovementPattern.pushing;

        items.add(
          MillerAdaptationItem(
            exerciseId: prog.exerciseId,
            exerciseName: name,
            pattern: pattern,
            variables: prog.variables,
            competencyLevel: prog.competencyLevel,
            lastPerformed: prog.lastPerformed,
          ),
        );
      }
    } else {
      // Provide one starter entry per movement pattern for initial discovery
      // -- the same tier-1 roots `baselineExerciseGraph` itself starts each
      // pattern's progression chain from (see bootstrap_catalog.dart).
      const discoveryExercises = [
        standardPushup,
        doorframeRow,
        hipHinge,
        airSquat,
        deadBug,
      ];

      for (final exercise in discoveryExercises) {
        items.add(
          MillerAdaptationItem(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            pattern: exercise.movementPattern,
            variables: const MillerVariables(),
            competencyLevel: 1,
            lastPerformed: DateTime.now(),
          ),
        );
      }
    }

    // Inspect recent completed sessions for genuine promotion events.
    //
    // SBEE only ever changes an exercise's prescribed variables *between*
    // sessions (generateNextWorkout prescribes a whole session at once from
    // the exercise's current ExerciseProgression; logSetPerformance only
    // updates that progression for the exercise's *next* appearance). So a
    // promotion can't be detected from a single set's reported RPE -- it
    // has to be read off a real increase between two sessions' persisted
    // `WorkoutSet.variables` snapshots for the same exercise. This avoids
    // re-deriving SBEE's RPE threshold (which would also need the
    // female-adjusted target to match SBEE exactly -- see
    // ActiveSessionController's `_diffAutoregulationAction`) by reading
    // what SBEE actually prescribed instead of guessing from RPE.
    //
    // Known limitation: an exercise's very first appearance inside the
    // lookback window has no earlier snapshot to compare against, so a
    // promotion whose "before" session falls just outside the window can be
    // missed. Accepted for this history ledger rather than adding
    // per-exercise boundary queries.
    final recentPromotions = <PromotionEvent>[];

    final Map<String, List<MapEntry<DateTime, MillerVariables>>>
    exerciseSnapshots = {};
    for (final session in recentSessions.where((s) => s.isCompleted)) {
      final seenExercises = <String>{};
      for (final set in session.sets) {
        if (set.reportedRpe == null) continue;
        if (!seenExercises.add(set.exerciseId)) continue;
        exerciseSnapshots
            .putIfAbsent(set.exerciseId, () => [])
            .add(MapEntry(session.startTime, set.variables));
      }
    }

    for (final entry in exerciseSnapshots.entries) {
      final snapshots = entry.value..sort((a, b) => a.key.compareTo(b.key));
      for (var i = 1; i < snapshots.length; i++) {
        final before = snapshots[i - 1].value;
        final after = snapshots[i].value;
        if (millerVariablesIncreased(before, after)) {
          final exName = exerciseById[entry.key]?.name ?? entry.key;
          recentPromotions.add(
            PromotionEvent(
              exerciseName: exName,
              variableDelta: _describeVariableIncrease(before, after),
              description:
                  'Miller variables advanced following logged performance.',
              // The earlier session's performance is what earned the
              // upgrade reflected in the later one.
              timestamp: snapshots[i - 1].key,
            ),
          );
        }
      }
    }

    recentPromotions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return AdaptationLedgerState(
      adaptations: items,
      recentPromotions: recentPromotions.take(5).toList(),
    );
  }
}

/// Names the specific Miller variable(s) that increased, e.g. "LOAD L1→L2".
String _describeVariableIncrease(
  MillerVariables before,
  MillerVariables after,
) {
  final parts = <String>[];
  if (after.load > before.load) {
    parts.add('LOAD L${before.load}→L${after.load}');
  }
  if (after.bodyPosition > before.bodyPosition) {
    parts.add('POSITION L${before.bodyPosition}→L${after.bodyPosition}');
  }
  if (after.rom > before.rom) {
    parts.add('ROM L${before.rom}→L${after.rom}');
  }
  if (after.height > before.height) {
    parts.add('HEIGHT L${before.height}→L${after.height}');
  }
  if (after.tempo > before.tempo) {
    parts.add('TEMPO L${before.tempo}→L${after.tempo}');
  }
  return parts.join(' // ');
}

/// Provider for [AdaptationLedgerService].
final adaptationLedgerServiceProvider = Provider<AdaptationLedgerService>((
  ref,
) {
  final progressionRepo = ref.watch(progressionRepositoryProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return AdaptationLedgerService(progressionRepo, sessionRepo);
});

/// Async provider yielding the latest [AdaptationLedgerState].
final adaptationLedgerProvider = FutureProvider<AdaptationLedgerState>((
  ref,
) async {
  final service = ref.watch(adaptationLedgerServiceProvider);
  return service.getLedgerState();
});
