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

  /// Mastery classification title based on competency level (T1 to T6).
  String get masteryTitle {
    switch (competencyLevel) {
      case 1:
        return 'NOVICE';
      case 2:
        return 'PROFICIENT';
      case 3:
        return 'ADVANCED';
      case 4:
        return 'EXPERT';
      case 5:
        return 'MASTER';
      case 6:
      default:
        return 'ZENITH';
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
  final int totalVariablesUpgraded;
  final int highestCompetencyTier;

  const AdaptationLedgerState({
    required this.adaptations,
    required this.recentPromotions,
    required this.totalVariablesUpgraded,
    required this.highestCompetencyTier,
  });

  bool get isEmpty => adaptations.isEmpty;
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
    final progressions = await _progressionRepository.getAllProgressions();

    final List<MillerAdaptationItem> items = [];
    int totalUpgrades = 0;
    int maxTier = 1;

    if (progressions.isNotEmpty) {
      for (final prog in progressions) {
        final exercise = expandedExerciseGraph.findById(prog.exerciseId) ??
            baselineExerciseGraph.findById(prog.exerciseId);

        final name = exercise?.name ??
            prog.exerciseId
                .split('_')
                .map((w) =>
                    w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
                .join(' ');
        final pattern = exercise?.movementPattern ?? MovementPattern.pushing;

        if (prog.competencyLevel > maxTier) {
          maxTier = prog.competencyLevel;
        }

        // Count non-baseline variables (each level above 1 is an upgrade)
        totalUpgrades += (prog.variables.load - 1);
        totalUpgrades += (prog.variables.bodyPosition - 1);
        totalUpgrades += (prog.variables.rom - 1);
        totalUpgrades += (prog.variables.height - 1);
        totalUpgrades += (prog.variables.tempo - 1);

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
      // Provide standard baseline entries for initial discovery
      final baselineExercises = [
        'standard_pushup',
        'bodyweight_squat',
        'inverted_row',
        'plank',
        'glute_bridge',
      ];

      for (final id in baselineExercises) {
        final exercise = expandedExerciseGraph.findById(id) ??
            baselineExerciseGraph.findById(id);
        if (exercise != null) {
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
    }

    // Inspect recent completed sessions for promotion/adaptation events
    final recentPromotions = <PromotionEvent>[];
    final now = currentTime ?? DateTime.now();
    final lookbackStart = now.subtract(const Duration(days: 30));
    final recentSessions = await _sessionRepository.getSessionsInDateRange(
      lookbackStart,
      now,
    );

    for (final session in recentSessions.where((s) => s.isCompleted)) {
      for (final set in session.sets) {
        final rpe = set.reportedRpe;
        if (rpe != null && rpe <= 6) {
          // Autoregulation candidate
          final ex = expandedExerciseGraph.findById(set.exerciseId) ??
              baselineExerciseGraph.findById(set.exerciseId);
          final exName = ex?.name ?? set.exerciseId;
          recentPromotions.add(
            PromotionEvent(
              exerciseName: exName,
              variableDelta: 'LOAD L${set.variables.load} // RPE $rpe',
              description: 'Exceeded target capacity (RPE $rpe <= 6). Variable upgrade eligible.',
              timestamp: set.timestamp,
            ),
          );
        }
      }
    }

    return AdaptationLedgerState(
      adaptations: items,
      recentPromotions: recentPromotions.take(5).toList(),
      totalVariablesUpgraded: totalUpgrades,
      highestCompetencyTier: maxTier,
    );
  }
}

/// Provider for [AdaptationLedgerService].
final adaptationLedgerServiceProvider =
    Provider<AdaptationLedgerService>((ref) {
  final progressionRepo = ref.watch(progressionRepositoryProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return AdaptationLedgerService(progressionRepo, sessionRepo);
});

/// Async provider yielding the latest [AdaptationLedgerState].
final adaptationLedgerProvider =
    FutureProvider<AdaptationLedgerState>((ref) async {
  final service = ref.watch(adaptationLedgerServiceProvider);
  return service.getLedgerState();
});
