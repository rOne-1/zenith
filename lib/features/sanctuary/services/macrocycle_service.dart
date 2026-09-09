import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../engine/engine.dart';

/// The periodization phase of a 5-week macrocycle.
enum MacrocyclePhase {
  /// Weeks 1–3: Progressive volume building and technical adaptation.
  accumulation,

  /// Week 4: High-intensity stimulus and capacity testing.
  overload,

  /// Week 5: Scheduled volume reduction (-50%) for systemic CNS restoration.
  deload,
}

/// Represents the current progression state within the 5-week deload periodization block.
class MacrocycleState {
  /// 1-based macrocycle iteration number (e.g. Cycle 1, Cycle 2).
  final int cycleNumber;

  /// Current week within the active 5-week cycle (1 to 5).
  final int weekInCycle;

  /// Active periodization phase for this week.
  final MacrocyclePhase phase;

  /// Timestamp marking the start of the current 5-week cycle.
  final DateTime cycleStartDate;

  /// Timestamp marking the start of the current 7-day week.
  final DateTime currentWeekStartDate;

  /// Timestamp marking the end of the current 7-day week.
  final DateTime currentWeekEndDate;

  /// Count of completed workout sessions during the current week.
  final int completedSessionsInWeek;

  /// Total repetitions performed during the current week.
  final int totalRepsInWeek;

  /// Cumulative load volume (tonnage approximation: reps * Miller load level) in current week.
  final int totalTonnageInWeek;

  /// Total workout sets completed in current week.
  final int completedSetsInWeek;

  const MacrocycleState({
    required this.cycleNumber,
    required this.weekInCycle,
    required this.phase,
    required this.cycleStartDate,
    required this.currentWeekStartDate,
    required this.currentWeekEndDate,
    this.completedSessionsInWeek = 0,
    this.totalRepsInWeek = 0,
    this.totalTonnageInWeek = 0,
    this.completedSetsInWeek = 0,
  });

  /// True if currently in the scheduled recovery deload phase (Week 5).
  bool get isDeload => phase == MacrocyclePhase.deload;

  /// English label for the active phase.
  String get phaseName {
    switch (phase) {
      case MacrocyclePhase.accumulation:
        return 'ACCUMULATION';
      case MacrocyclePhase.overload:
        return 'PEAK OVERLOAD';
      case MacrocyclePhase.deload:
        return 'REST & DELOAD';
    }
  }

  /// Recommended exertion RPE target for the current periodization phase.
  String get targetRpeGuidance {
    switch (phase) {
      case MacrocyclePhase.accumulation:
        return 'RPE 6.0 – 7.5';
      case MacrocyclePhase.overload:
        return 'RPE 8.0 – 9.0';
      case MacrocyclePhase.deload:
        return 'RPE 5.0 – 6.0';
    }
  }

  /// Educational restorative and biomechanical guidance for the operator.
  String get restorativeGuidance {
    switch (phase) {
      case MacrocyclePhase.accumulation:
        return 'Focus on technical mastery, consistent tempo, and progressive volume. Keep exertion controlled to prepare joints and connective tissue.';
      case MacrocyclePhase.overload:
        return 'Maximum systemic adaptation phase. Push intensity and test movement milestones before scheduled recovery. Ensure adequate sleep and protein intake.';
      case MacrocyclePhase.deload:
        return 'Strategic deload protocol. Volume is dialed back to allow central nervous system reset and muscle tendon remodeling. Prioritize mobility and restoration.';
    }
  }

  /// ASCII / Neo-Pixel stepped meter string (e.g. "[█ █ █ ░ ░] WEEK 3/5").
  String get steppedMeterText {
    final buffer = StringBuffer('[');
    for (int i = 1; i <= 5; i++) {
      if (i < weekInCycle) {
        buffer.write(' █');
      } else if (i == weekInCycle) {
        buffer.write(' █');
      } else {
        buffer.write(' ░');
      }
    }
    buffer.write(' ] WEEK $weekInCycle/5');
    return buffer.toString();
  }

  /// Progress fraction through the 5-week cycle (from 0.2 at Week 1 to 1.0 at Week 5).
  double get cycleProgress => (weekInCycle / 5.0).clamp(0.0, 1.0);
}

/// Service that evaluates the user\'s macrocycle position and weekly training volume
/// against a 5-week block periodization model (3 Weeks Accumulation, 1 Week Overload, 1 Week Deload).
class MacrocycleService {
  final SessionRepository _sessionRepository;

  const MacrocycleService(this._sessionRepository);

  /// Resolves the current [MacrocycleState] given the user\'s session history.
  Future<MacrocycleState> getMacrocycleStatus({DateTime? currentTime}) async {
    final now = currentTime ?? DateTime.now();
    final earliestSessionStart =
        await _sessionRepository.getEarliestCompletedSessionStart();

    final DateTime programStart;
    final int cycleNumber;
    final int weekInCycle;
    final DateTime cycleStartDate;
    final DateTime currentWeekStartDate;
    final DateTime currentWeekEndDate;

    if (earliestSessionStart == null) {
      // Baseline state when no completed sessions exist yet
      programStart = DateTime(now.year, now.month, now.day);
      cycleNumber = 1;
      weekInCycle = 1;
      cycleStartDate = programStart;
      currentWeekStartDate = programStart;
      currentWeekEndDate = currentWeekStartDate.add(const Duration(days: 7));
    } else {
      programStart = earliestSessionStart;
      final differenceInDays = now.difference(programStart).inDays;

      if (differenceInDays < 0) {
        cycleNumber = 1;
        weekInCycle = 1;
        cycleStartDate = programStart;
        currentWeekStartDate = programStart;
        currentWeekEndDate = currentWeekStartDate.add(const Duration(days: 7));
      } else {
        final totalWeeksElapsed = differenceInDays ~/ 7;
        cycleNumber = (totalWeeksElapsed ~/ 5) + 1;
        weekInCycle = (totalWeeksElapsed % 5) + 1;

        final cycleStartDays = (cycleNumber - 1) * 35;
        cycleStartDate = programStart.add(Duration(days: cycleStartDays));

        final weekStartDays = (weekInCycle - 1) * 7;
        currentWeekStartDate = cycleStartDate.add(Duration(days: weekStartDays));
        currentWeekEndDate = currentWeekStartDate.add(const Duration(days: 7));
      }
    }

    final MacrocyclePhase phase;
    if (weekInCycle <= 3) {
      phase = MacrocyclePhase.accumulation;
    } else if (weekInCycle == 4) {
      phase = MacrocyclePhase.overload;
    } else {
      phase = MacrocyclePhase.deload;
    }

    // Query weekly training volume
    final weeklySessions = await _sessionRepository.getSessionsInDateRange(
      currentWeekStartDate,
      currentWeekEndDate,
    );

    final completedSessions =
        weeklySessions.where((s) => s.isCompleted).toList();
    final completedSessionsCount = completedSessions.length;

    int totalReps = 0;
    int totalTonnage = 0;
    int totalCompletedSets = 0;

    for (final session in completedSessions) {
      for (final set in session.sets) {
        if (set.reportedRpe != null) {
          totalCompletedSets++;
          totalReps += set.reps;
          totalTonnage += (set.reps * set.variables.load);
        }
      }
    }

    return MacrocycleState(
      cycleNumber: cycleNumber,
      weekInCycle: weekInCycle,
      phase: phase,
      cycleStartDate: cycleStartDate,
      currentWeekStartDate: currentWeekStartDate,
      currentWeekEndDate: currentWeekEndDate,
      completedSessionsInWeek: completedSessionsCount,
      totalRepsInWeek: totalReps,
      totalTonnageInWeek: totalTonnage,
      completedSetsInWeek: totalCompletedSets,
    );
  }
}

/// Provider for [MacrocycleService].
final macrocycleServiceProvider = Provider<MacrocycleService>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return MacrocycleService(sessionRepo);
});

/// Async provider yielding the latest [MacrocycleState].
final macrocycleProvider = FutureProvider<MacrocycleState>((ref) async {
  final service = ref.watch(macrocycleServiceProvider);
  return service.getMacrocycleStatus();
});
