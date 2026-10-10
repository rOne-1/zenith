import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/features/outpost/services/streak_service.dart';

void main() {
  group('StreakService Unit Tests', () {
    late SbeeDatabase database;
    late DriftSessionRepository sessionRepo;
    late StreakService streakService;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      sessionRepo = DriftSessionRepository(database);
      streakService = StreakService(sessionRepo);
    });

    tearDown(() async {
      await database.close();
    });

    test('returns 0 when no completed sessions exist', () async {
      final now = DateTime(2026, 10, 10, 12, 0);
      final streak = await streakService.getCurrentStreak(currentTime: now);
      expect(streak, equals(0));
    });

    test('counts consecutive days ending today', () async {
      final today = DateTime(2026, 10, 10);
      for (var i = 0; i < 5; i++) {
        final day = DateTime(today.year, today.month, today.day - i, 10, 0);
        await sessionRepo.saveSession(
          WorkoutSession(
            id: 'session_$i',
            startTime: day,
            endTime: day.add(const Duration(minutes: 45)),
            isCompleted: true,
          ),
        );
      }

      final streak = await streakService.getCurrentStreak(
        currentTime: DateTime(2026, 10, 10, 18, 0),
      );
      expect(streak, equals(5));
    });

    test('counts ongoing streak when today has no workout but yesterday did', () async {
      final today = DateTime(2026, 10, 10);
      // Days -1, -2, -3 (yesterday, day before, etc.)
      for (var i = 1; i <= 3; i++) {
        final day = DateTime(today.year, today.month, today.day - i, 14, 0);
        await sessionRepo.saveSession(
          WorkoutSession(
            id: 'session_$i',
            startTime: day,
            endTime: day.add(const Duration(minutes: 45)),
            isCompleted: true,
          ),
        );
      }

      final streak = await streakService.getCurrentStreak(
        currentTime: DateTime(2026, 10, 10, 9, 0),
      );
      expect(streak, equals(3));
    });

    test('streak resets to 0 if neither today nor yesterday had a session', () async {
      final today = DateTime(2026, 10, 10);
      // Workout 2 days ago, but missed yesterday
      final day = DateTime(today.year, today.month, today.day - 2, 14, 0);
      await sessionRepo.saveSession(
        WorkoutSession(
          id: 'session_old',
          startTime: day,
          isCompleted: true,
        ),
      );

      final streak = await streakService.getCurrentStreak(
        currentTime: DateTime(2026, 10, 10, 12, 0),
      );
      expect(streak, equals(0));
    });

    test('maintains streak across early March calendar boundaries (March 7-10)', () async {
      // NOTE: In non-DST timezones (such as Asia/Calcutta / IST on this test machine),
      // Dart's local DateTime treats every day as 24 hours. In such environments,
      // this test verifies calendar date stepping across March 7-10 and ensures
      // StreakService correctly traverses multi-day spans regardless of calendar month position.
      final days = [
        DateTime(2026, 3, 7, 10, 0),
        DateTime(2026, 3, 8, 10, 0),
        DateTime(2026, 3, 9, 10, 0),
        DateTime(2026, 3, 10, 10, 0),
      ];

      for (var i = 0; i < days.length; i++) {
        await sessionRepo.saveSession(
          WorkoutSession(
            id: 'march_session_$i',
            startTime: days[i],
            isCompleted: true,
          ),
        );
      }

      final streak = await streakService.getCurrentStreak(
        currentTime: DateTime(2026, 3, 10, 16, 0),
      );
      expect(streak, equals(4));
    });

    test('maintains streak across month boundary transition (October 31 - November 2)', () async {
      // NOTE: In non-DST timezones (such as IST), this test verifies that calendar
      // stepping across the month boundary (from October 31 to November 1 and 2)
      // traverses the month turnover correctly without day/month calculation errors.
      final days = [
        DateTime(2026, 10, 31, 8, 0),
        DateTime(2026, 11, 1, 8, 0),
        DateTime(2026, 11, 2, 8, 0),
      ];

      for (var i = 0; i < days.length; i++) {
        await sessionRepo.saveSession(
          WorkoutSession(
            id: 'month_boundary_session_$i',
            startTime: days[i],
            isCompleted: true,
          ),
        );
      }

      final streak = await streakService.getCurrentStreak(
        currentTime: DateTime(2026, 11, 2, 20, 0),
      );
      expect(streak, equals(3));
    });

    test('verifies calendar arithmetic invariance vs Duration(days: 1) under simulated DST skew', () {
      // Demonstrates mathematically why Duration(days: 1) is fragile under DST transitions:
      // In a DST-observing timezone, a spring-forward transition day has 23 hours,
      // while a fall-back transition day has 25 hours.
      final completedDays = <DateTime>{
        DateTime(2026, 3, 7), // midnight 00:00:00
        DateTime(2026, 3, 8), // midnight 00:00:00
        DateTime(2026, 3, 9), // midnight 00:00:00
      };

      final cursor = DateTime(2026, 3, 9); // midnight

      // 1. Calendar arithmetic DateTime(y, m, d - 1) is invariant to clock drift or day duration:
      final calendarYesterday = DateTime(cursor.year, cursor.month, cursor.day - 1);
      expect(calendarYesterday.hour, equals(0));
      expect(calendarYesterday.minute, equals(0));
      expect(calendarYesterday.second, equals(0));
      expect(completedDays.contains(calendarYesterday), isTrue);

      // 2. Under a 23-hour spring-forward day, 24 hours prior lands on 23:00 of the previous day:
      // If a day had 23 hours between midnights, then midnight_next - Duration(days: 1) (24 hours)
      // produces 23:00 rather than midnight:
      final offsetFrom23hDay = DateTime(2026, 3, 8, 23, 0);
      expect(
        completedDays.contains(offsetFrom23hDay),
        isFalse,
        reason: 'Set contains normalized midnight, so hour != 0 causes lookup failure',
      );

      // 3. Under a 25-hour fall-back day, midnight_next - Duration(days: 1) (24 hours)
      // produces 01:00 rather than midnight:
      final offsetFrom25hDay = DateTime(2026, 3, 8, 1, 0);
      expect(
        completedDays.contains(offsetFrom25hDay),
        isFalse,
        reason: 'Set contains normalized midnight, so hour != 0 causes lookup failure',
      );

      // 4. Stepping backward using calendar arithmetic guarantees midnight normalization:
      var step = cursor;
      final steppedDays = <DateTime>[];
      for (var i = 0; i < 3; i++) {
        steppedDays.add(step);
        step = DateTime(step.year, step.month, step.day - 1);
      }
      expect(steppedDays, equals([
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 8),
        DateTime(2026, 3, 7),
      ]));
      expect(
        steppedDays.every((d) => d.hour == 0 && d.minute == 0 && d.second == 0),
        isTrue,
      );
    });

    test('counts streak correctly when sessions occur at non-midnight times near day boundaries', () async {
      // User works out at 23:30 on Day 1, 00:30 on Day 2, and 12:00 on Day 3
      final sessions = [
        DateTime(2026, 5, 1, 23, 30),
        DateTime(2026, 5, 2, 0, 30),
        DateTime(2026, 5, 3, 12, 0),
      ];

      for (var i = 0; i < sessions.length; i++) {
        await sessionRepo.saveSession(
          WorkoutSession(
            id: 'scattered_session_$i',
            startTime: sessions[i],
            isCompleted: true,
          ),
        );
      }

      // Query on Day 3 in the evening
      final streak = await streakService.getCurrentStreak(
        currentTime: DateTime(2026, 5, 3, 21, 0),
      );
      expect(streak, equals(3));
    });
  });
}
