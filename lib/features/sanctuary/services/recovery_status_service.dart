import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../engine/engine.dart';

/// 48-hour physiological recovery window required after taxing sets (RPE >= 8).
const Duration kPatternRecoveryLockDuration = Duration(hours: 48);

/// Minimum reported RPE threshold triggering the 48-hour recovery lock.
const int kTaxingRpeThreshold = 8;

/// Physiological recovery status for an individual ACE IFT movement pattern.
class PatternRecoveryStatus {
  final MovementPattern pattern;
  final bool isFresh;
  final Duration remainingLockDuration;
  final DateTime? lastTaxingSetTimestamp;
  final int totalSetsIn48Hours;
  final int taxingSetsIn48Hours;

  const PatternRecoveryStatus({
    required this.pattern,
    required this.isFresh,
    required this.remainingLockDuration,
    this.lastTaxingSetTimestamp,
    this.totalSetsIn48Hours = 0,
    this.taxingSetsIn48Hours = 0,
  });

  /// Fraction of recovery completed from 0.0 (just finished taxing set) to 1.0 (fully fresh).
  double get recoveryProgress {
    if (isFresh || remainingLockDuration == Duration.zero) return 1.0;
    final remainingMs = remainingLockDuration.inMilliseconds;
    final totalMs = kPatternRecoveryLockDuration.inMilliseconds;
    final elapsedMs = totalMs - remainingMs;
    return (elapsedMs / totalMs).clamp(0.0, 1.0);
  }

  /// Compact operator string (e.g., "26H REMAINING" or "FRESH").
  String get statusChipLabel {
    if (isFresh) {
      return 'FRESH // 回復済';
    }
    final hours = remainingLockDuration.inHours;
    final minutes = remainingLockDuration.inMinutes % 60;
    if (hours > 0) {
      return '48H LOCK // ${hours}H REMAINING';
    }
    return '48H LOCK // ${minutes}M REMAINING';
  }
}

/// Service that evaluates neuromuscular cooldown clocks and 48-hour pattern locks
/// based on historical set exertion data.
class RecoveryStatusService {
  final SessionRepository _sessionRepository;

  const RecoveryStatusService(this._sessionRepository);

  /// Calculates recovery status across all 5 ACE IFT movement patterns.
  Future<Map<MovementPattern, PatternRecoveryStatus>> getAllPatternStatuses({
    DateTime? currentTime,
  }) async {
    final now = currentTime ?? DateTime.now();
    final windowStart = now.subtract(kPatternRecoveryLockDuration);

    final statuses = <MovementPattern, PatternRecoveryStatus>{};

    for (final pattern in MovementPattern.values) {
      final sets = await _sessionRepository.getSetsForMovementPattern(
        pattern,
        windowStart,
      );

      DateTime? latestTaxingTimestamp;
      int taxingCount = 0;

      for (final set in sets) {
        final rpe = set.reportedRpe ?? set.targetRpe;
        if (rpe >= kTaxingRpeThreshold) {
          taxingCount++;
          if (latestTaxingTimestamp == null ||
              set.timestamp.isAfter(latestTaxingTimestamp)) {
            latestTaxingTimestamp = set.timestamp;
          }
        }
      }

      if (latestTaxingTimestamp == null) {
        statuses[pattern] = PatternRecoveryStatus(
          pattern: pattern,
          isFresh: true,
          remainingLockDuration: Duration.zero,
          totalSetsIn48Hours: sets.length,
          taxingSetsIn48Hours: 0,
        );
      } else {
        final lockExpiry = latestTaxingTimestamp.add(kPatternRecoveryLockDuration);
        final remaining = lockExpiry.difference(now);

        if (remaining > Duration.zero) {
          statuses[pattern] = PatternRecoveryStatus(
            pattern: pattern,
            isFresh: false,
            remainingLockDuration: remaining,
            lastTaxingSetTimestamp: latestTaxingTimestamp,
            totalSetsIn48Hours: sets.length,
            taxingSetsIn48Hours: taxingCount,
          );
        } else {
          statuses[pattern] = PatternRecoveryStatus(
            pattern: pattern,
            isFresh: true,
            remainingLockDuration: Duration.zero,
            lastTaxingSetTimestamp: latestTaxingTimestamp,
            totalSetsIn48Hours: sets.length,
            taxingSetsIn48Hours: taxingCount,
          );
        }
      }
    }

    return statuses;
  }
}

/// Primary Riverpod provider for the [RecoveryStatusService].
final recoveryStatusServiceProvider = Provider<RecoveryStatusService>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return RecoveryStatusService(sessionRepo);
});

/// Reactive provider yielding recovery status for all 5 patterns.
final recoveryStatusProvider =
    FutureProvider<Map<MovementPattern, PatternRecoveryStatus>>((ref) async {
  final service = ref.watch(recoveryStatusServiceProvider);
  return service.getAllPatternStatuses();
});
