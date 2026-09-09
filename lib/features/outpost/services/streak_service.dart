import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../engine/engine.dart';

/// Computes the user's current training streak -- consecutive calendar days,
/// ending today or yesterday, with at least one completed session.
///
/// "Yesterday" counts as the streak's end so a real, ongoing streak isn't
/// reported as broken just because today's session hasn't happened yet.
class StreakService {
  final SessionRepository _sessionRepository;

  const StreakService(this._sessionRepository);

  /// Bounded lookback window, consistent with SBEE's own Phase 5 guidance
  /// against unbounded full-history scans (see `SBEE/doc/DECISIONS_LOG.md`
  /// §1 Phase 5) -- a streak longer than this is not realistic to expect,
  /// and there is no reason to query further back to detect one.
  static const int lookbackDays = 90;

  Future<int> getCurrentStreak({DateTime? currentTime}) async {
    final now = currentTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: lookbackDays));

    final sessions = await _sessionRepository.getSessionsInDateRange(
      windowStart,
      today.add(const Duration(days: 1)),
    );

    final completedDays = <DateTime>{};
    for (final session in sessions) {
      if (!session.isCompleted) continue;
      completedDays.add(
        DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        ),
      );
    }

    if (completedDays.isEmpty) return 0;

    var cursor = completedDays.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    if (!completedDays.contains(cursor)) return 0;

    var streak = 0;
    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

/// Provider for [StreakService].
final streakServiceProvider = Provider<StreakService>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return StreakService(sessionRepo);
});

/// Provider for the user's current streak (in days).
final currentStreakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(streakServiceProvider);
  return service.getCurrentStreak();
});
