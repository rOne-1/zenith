import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../engine/engine.dart';
import '../../armory/providers/user_profile_provider.dart';
import '../../outpost/services/streak_service.dart';
import '../../sanctuary/services/macrocycle_service.dart';
import '../services/workout_preview_service.dart';

/// Decision output of the Kenneth Miller autoregulation evaluation.
enum AutoregulationAction {
  increment,
  regress,
  maintain,
}

/// Represents an adaptation adjustment outcome recorded for a logged set.
@immutable
class MillerAdaptationRecord {
  final String exerciseId;
  final String exerciseName;
  final int reps;
  final int reportedRpe;
  final int targetRpe;
  final MillerVariables variables;
  final AutoregulationAction action;
  final String adaptationSummary;

  const MillerAdaptationRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.reps,
    required this.reportedRpe,
    required this.targetRpe,
    required this.variables,
    required this.action,
    required this.adaptationSummary,
  });
}

/// Comprehensive state snapshot of the active expedition workout session.
@immutable
class ActiveSessionState {
  final WorkoutSession? session;
  final SessionState fsmState;
  final int currentSetIndex;
  final int currentRepsInput;
  final int? selectedRpe;
  final Duration restRemaining;
  final Duration totalRest;
  final List<MillerAdaptationRecord> adaptations;
  final bool isFinalizing;
  final String? errorMessage;

  const ActiveSessionState({
    this.session,
    this.fsmState = SessionState.warmUp,
    this.currentSetIndex = 0,
    this.currentRepsInput = 0,
    this.selectedRpe,
    this.restRemaining = Duration.zero,
    this.totalRest = Duration.zero,
    this.adaptations = const [],
    this.isFinalizing = false,
    this.errorMessage,
  });

  static const ActiveSessionState initial = ActiveSessionState();

  bool get hasActiveSession => session != null;
  int get totalSets => session?.sets.length ?? 0;
  bool get isLastSet => session != null && currentSetIndex >= session!.sets.length - 1;

  WorkoutSet? get currentSet {
    if (session == null || currentSetIndex >= session!.sets.length) return null;
    return session!.sets[currentSetIndex];
  }

  WorkoutSet? get nextSet {
    if (session == null || currentSetIndex + 1 >= session!.sets.length) return null;
    return session!.sets[currentSetIndex + 1];
  }

  int get completedSetsCount {
    if (session == null) return 0;
    return session!.sets.where((s) => s.reportedRpe != null).length;
  }

  int get totalRepsCompleted {
    if (session == null) return 0;
    var sum = 0;
    for (final s in session!.sets) {
      if (s.reportedRpe != null) {
        sum += s.reps;
      }
    }
    return sum;
  }

  double get averageRpe {
    if (session == null) return 0.0;
    final reported = session!.sets.where((s) => s.reportedRpe != null).toList();
    if (reported.isEmpty) return 0.0;
    final total = reported.fold<int>(0, (sum, s) => sum + s.reportedRpe!);
    return total / reported.length;
  }

  ActiveSessionState copyWith({
    WorkoutSession? session,
    SessionState? fsmState,
    int? currentSetIndex,
    int? currentRepsInput,
    int? Function()? selectedRpe,
    Duration? restRemaining,
    Duration? totalRest,
    List<MillerAdaptationRecord>? adaptations,
    bool? isFinalizing,
    String? Function()? errorMessage,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      fsmState: fsmState ?? this.fsmState,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      currentRepsInput: currentRepsInput ?? this.currentRepsInput,
      selectedRpe: selectedRpe != null ? selectedRpe() : this.selectedRpe,
      restRemaining: restRemaining ?? this.restRemaining,
      totalRest: totalRest ?? this.totalRest,
      adaptations: adaptations ?? this.adaptations,
      isFinalizing: isFinalizing ?? this.isFinalizing,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

/// Controller wrapping SBEE's [SessionStreamManager] and FSM lifecycle.
///
/// Ensures strict state progression:
/// `warmUp` ➔ `activeSet` ➔ `rest` ➔ `coolDown` ➔ `completed`.
class ActiveSessionController extends StateNotifier<ActiveSessionState> {
  final Ref _ref;
  SessionStreamManager? _manager;
  StreamSubscription<SessionProgressState>? _progressSubscription;
  Timer? _restTimer;

  ActiveSessionController(this._ref) : super(ActiveSessionState.initial);

  SessionStreamManager? get currentManager => _manager;

  /// Starts a new active expedition workout session.
  Future<void> startSession(WorkoutSession session) async {
    _cancelTimer();
    await _progressSubscription?.cancel();

    final sessionRepo = _ref.read(sessionRepositoryProvider);
    final manager = SessionStreamManager(sessionRepository: sessionRepo);
    manager.initializeSession(session);

    _manager = manager;
    _attachManager(manager, session);
  }

  /// Adopts an existing [SessionStreamManager] restored after a crash/restart.
  void resumeSession(SessionStreamManager existingManager) {
    _cancelTimer();
    _progressSubscription?.cancel();

    _manager = existingManager;
    final progress = existingManager.currentState;
    final session = progress.session;
    if (session != null) {
      _attachManager(existingManager, session, initialProgress: progress);
    }
  }

  void _attachManager(
    SessionStreamManager manager,
    WorkoutSession session, {
    SessionProgressState? initialProgress,
  }) {
    final progress = initialProgress ?? manager.currentState;
    final initialSet = session.sets.isNotEmpty ? session.sets[progress.currentSetIndex] : null;

    state = ActiveSessionState(
      session: session,
      fsmState: progress.state,
      currentSetIndex: progress.currentSetIndex,
      currentRepsInput: initialSet?.reps ?? 10,
      selectedRpe: initialSet?.targetRpe ?? 8,
    );

    _progressSubscription = manager.progressStream.listen((p) {
      if (!mounted) return;

      var sessionToUse = p.session ?? state.session;
      if (sessionToUse != null && state.session != null) {
        final currentIdx = state.currentSetIndex;
        if (currentIdx < state.session!.sets.length &&
            currentIdx < sessionToUse.sets.length) {
          final localSet = state.session!.sets[currentIdx];
          if (localSet.reportedRpe != null) {
            final sets = List<WorkoutSet>.from(sessionToUse.sets);
            sets[currentIdx] = sets[currentIdx].copyWith(
              reportedRpe: localSet.reportedRpe,
            );
            sessionToUse = sessionToUse.copyWith(sets: sets);
          }
        }
      }

      final curSet = sessionToUse != null && p.currentSetIndex < sessionToUse.sets.length
          ? sessionToUse.sets[p.currentSetIndex]
          : null;

      state = state.copyWith(
        session: sessionToUse,
        fsmState: p.state,
        currentSetIndex: p.currentSetIndex,
        currentRepsInput: curSet?.reps ?? state.currentRepsInput,
      );
    });
  }

  /// Transitions from [SessionState.warmUp] to [SessionState.activeSet].
  void completeWarmUp() {
    _ensureManager();
    _manager!.startWorkout();
    final curSet = state.currentSet;
    state = state.copyWith(
      fsmState: SessionState.activeSet,
      currentRepsInput: curSet?.reps ?? 10,
      selectedRpe: () => curSet?.targetRpe ?? 8,
    );
  }

  /// Updates the planned rep count before completing the active set.
  void updateRepsInput(int newReps) {
    state = state.copyWith(currentRepsInput: newReps.clamp(0, 999));
  }

  /// Logs the active set and transitions to [SessionState.rest] (or [SessionState.coolDown]).
  void completeCurrentSet({int? actualReps}) {
    _ensureManager();
    final set = state.currentSet;
    if (set == null) return;

    final repsToLog = actualReps ?? state.currentRepsInput;
    final rpeToLog = state.selectedRpe ?? set.targetRpe;

    // Log set through SBEE FSM
    _manager!.logCurrentSet(reps: repsToLog, reportedRpe: rpeToLog);

    final isLast = state.isLastSet;
    if (!isLast) {
      // Transition to rest: initiate countdown
      final restDuration = set.restDuration ?? const Duration(seconds: 90);
      _startRestTimer(restDuration);

      final next = state.nextSet;
      state = state.copyWith(
        fsmState: SessionState.rest,
        restRemaining: restDuration,
        totalRest: restDuration,
        selectedRpe: () => rpeToLog,
        currentRepsInput: next?.reps ?? 10,
      );
    } else {
      // Finished all sets: transition to cool down
      state = state.copyWith(
        fsmState: SessionState.coolDown,
        selectedRpe: () => rpeToLog,
      );
    }
  }

  /// Skips the active set and advances the FSM.
  void skipCurrentSet() {
    completeCurrentSet(actualReps: 0);
  }

  /// Records/updates the Borg RPE for the set just logged during rest.
  Future<void> logRpe(int rpeScore) async {
    final clampedRpe = rpeScore.clamp(1, 10);
    state = state.copyWith(selectedRpe: () => clampedRpe);

    if (state.session != null && state.currentSetIndex < state.session!.sets.length) {
      final sets = List<WorkoutSet>.from(state.session!.sets);
      final targetSet = sets[state.currentSetIndex];
      sets[state.currentSetIndex] = targetSet.copyWith(reportedRpe: clampedRpe);

      final updatedSession = state.session!.copyWith(sets: sets);
      state = state.copyWith(session: updatedSession);

      // Persist set modification in background
      final repo = _ref.read(sessionRepositoryProvider);
      await repo.saveSession(updatedSession);
    }
  }

  void _startRestTimer(Duration duration) {
    _cancelTimer();
    state = state.copyWith(
      restRemaining: duration,
      totalRest: duration,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final current = state.restRemaining;
      if (current.inSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(restRemaining: Duration.zero);
      } else {
        state = state.copyWith(
          restRemaining: current - const Duration(seconds: 1),
        );
      }
    });
  }

  /// Adds a duration extension (defaults to 30s) to the active rest countdown.
  void addRestTime([Duration extension = const Duration(seconds: 30)]) {
    final newRemaining = state.restRemaining + extension;
    final newTotal = state.totalRest + extension;
    state = state.copyWith(
      restRemaining: newRemaining,
      totalRest: newTotal,
    );
  }

  /// Concludes the rest phase and starts the next set.
  void completeRest() {
    _cancelTimer();
    _ensureManager();

    _manager!.startNextSet();
    final newIdx = _manager!.currentState.currentSetIndex;
    final curSet = state.session != null && newIdx < state.session!.sets.length
        ? state.session!.sets[newIdx]
        : null;

    state = state.copyWith(
      fsmState: SessionState.activeSet,
      currentSetIndex: newIdx,
      currentRepsInput: curSet?.reps ?? 10,
      selectedRpe: () => curSet?.targetRpe ?? 8,
      restRemaining: Duration.zero,
    );
  }

  /// Concludes the cool down phase and transitions to debrief / [SessionState.completed].
  Future<void> completeCoolDown() async {
    _ensureManager();
    _manager!.finalizeSession();
    await finalizeSession();
  }

  /// Evaluates Kenneth Miller autoregulations, saves finalized session,
  /// and clears cache.
  Future<void> finalizeSession() async {
    if (state.session == null) return;
    state = state.copyWith(isFinalizing: true);

    try {
      final engine = _ref.read(sbeeEngineProvider);
      final profile = _ref.read(userProfileProvider);
      final sessionRepo = _ref.read(sessionRepositoryProvider);

      final session = state.session!;
      final adaptationList = <MillerAdaptationRecord>[];

      // Evaluate Kenneth Miller adjustments for each reported set
      for (final set in session.sets) {
        if (set.reportedRpe == null) continue;

        final newVars = await engine.logSetPerformance(
          exerciseId: set.exerciseId,
          reps: set.reps,
          reportedRpe: set.reportedRpe!,
          targetRpe: set.targetRpe,
          femaleProfile: profile.femaleProfile,
        );

        final action = set.reportedRpe! < (set.targetRpe - 1)
            ? AutoregulationAction.increment
            : (set.reportedRpe! > (set.targetRpe + 1)
                ? AutoregulationAction.regress
                : AutoregulationAction.maintain);

        final exercise = expandedExerciseGraph.findById(set.exerciseId) ??
            baselineExerciseGraph.findById(set.exerciseId);
        final name = exercise?.name ?? set.exerciseId;

        final summary = switch (action) {
          AutoregulationAction.increment =>
            'PROGRESSION: Load/ROM increased. Variables now ($newVars).',
          AutoregulationAction.regress =>
            'REGRESSION: Load buffer applied. Variables adjusted ($newVars).',
          AutoregulationAction.maintain =>
            'MAINTAINED: Optimal stimulus achieved. Mastery locked ($newVars).',
        };

        adaptationList.add(
          MillerAdaptationRecord(
            exerciseId: set.exerciseId,
            exerciseName: name,
            reps: set.reps,
            reportedRpe: set.reportedRpe!,
            targetRpe: set.targetRpe,
            variables: newVars,
            action: action,
            adaptationSummary: summary,
          ),
        );
      }

      // Mark completed and persist
      final completedSession = session.copyWith(
        isCompleted: true,
        endTime: DateTime.now(),
      );
      await sessionRepo.saveSession(completedSession);

      // Invalidate preview cache, active session probe, and the Outpost
      // dashboard's streak/weekly-stats (a completed session just changed
      // both, and neither provider would otherwise ever refresh since
      // OutpostScreen stays alive for the app's lifetime inside the
      // IndexedStack shell).
      _ref.read(workoutPreviewProvider.notifier).invalidate();
      _ref.invalidate(activeSessionResumeProvider);
      _ref.invalidate(currentStreakProvider);
      _ref.invalidate(macrocycleProvider);

      state = state.copyWith(
        session: completedSession,
        fsmState: SessionState.completed,
        adaptations: adaptationList,
        isFinalizing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isFinalizing: false,
        errorMessage: () => 'Error finalizing expedition: $e',
      );
    }
  }

  /// Discards the active workout attempt and resets state.
  Future<void> abortSession() async {
    _cancelTimer();
    _manager = null;
    state = ActiveSessionState.initial;

    final sub = _progressSubscription;
    _progressSubscription = null;
    await sub?.cancel();

    final sbeeService = _ref.read(sbeeServiceProvider);
    await sbeeService.discardActiveSession();

    _ref.read(workoutPreviewProvider.notifier).invalidate();
    _ref.invalidate(activeSessionResumeProvider);
  }

  void _cancelTimer() {
    _restTimer?.cancel();
    _restTimer = null;
  }

  void _ensureManager() {
    if (_manager == null) {
      throw StateError('ActiveSessionController has no active SessionStreamManager.');
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    _progressSubscription?.cancel();
    super.dispose();
  }
}

/// Primary Riverpod provider for the active expedition controller.
final activeSessionControllerProvider =
    StateNotifierProvider<ActiveSessionController, ActiveSessionState>((ref) {
      return ActiveSessionController(ref);
    });
