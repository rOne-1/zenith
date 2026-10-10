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

    test('maintains streak across simulated DST transition boundaries (calendar arithmetic)', () async {
      // Simulate consecutive days across a month/day boundary that could coincide with DST:
      // Day 1: March 7
      // Day 2: March 8 (23-hour DST spring-forward transition)
      // Day 3: March 9
      // Day 4: March 10
      final days = [
        DateTime(2026, 3, 7, 10, 0),
        DateTime(2026, 3, 8, 10, 0),
        DateTime(2026, 3, 9, 10, 0),
        DateTime(2026, 3, 10, 10, 0),
      ];

      for (var i = 0; i < days.length; i++) {
        await sessionRepo.saveSession(
          WorkoutSession(
            id: 'dst_session_$i',
            startTime: days[i],
            isCompleted: true,
          ),
        );
      }

      // Query on March 10: with calendar arithmetic DateTime(y, m, d - 1),
      // each day's cursor normalizes to midnight without 1-hour drift from Duration(days: 1).
      final streak = await streakService.getCurrentStreak(
        currentTime: DateTime(2026, 3, 10, 16, 0),
      );
      expect(streak, equals(4));
    });

    test('maintains streak across autumn DST fall-back boundary (calendar arithmetic)', () async {
      // Day 1: Oct 31
      // Day 2: Nov 1 (25-hour DST fall-back transition)
      // Day 3: Nov 2
      final days = [
        DateTime(2026, 10, 31, 8, 0),
        DateTime(2026, 11, 1, 8, 0),
        DateTime(2026, 11, 2, 8, 0),
      ];

      for (var i = 0; i < days.length; i++) {
        await sessionRepo.saveSession(
          WorkoutSession(
            id: 'fall_session_$i',
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
  });
}
