import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/sanctuary/services/recovery_status_service.dart';
import 'package:zenith/features/sanctuary/widgets/pattern_recovery_grid.dart';

void main() {
  group('RecoveryStatusService Unit Tests', () {
    late SbeeDatabase database;
    late DriftSessionRepository sessionRepo;
    late RecoveryStatusService service;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      sessionRepo = DriftSessionRepository(database);
      service = RecoveryStatusService(sessionRepo);
    });

    tearDown(() async {
      await database.close();
    });

    test('all 5 patterns are fresh when no workout history exists', () async {
      final statuses = await service.getAllPatternStatuses();

      expect(statuses.length, equals(5));
      for (final pattern in MovementPattern.values) {
        expect(statuses[pattern]?.isFresh, isTrue);
        expect(statuses[pattern]?.remainingLockDuration, equals(Duration.zero));
        expect(statuses[pattern]?.recoveryProgress, equals(1.0));
        expect(statuses[pattern]?.statusChipLabel, equals('FRESH // 回復済'));
      }
    });

    test('sub-threshold sets (RPE < 8) do not trigger 48h lock', () async {
      final now = DateTime(2026, 9, 9, 12, 0);
      final setTime = now.subtract(const Duration(hours: 10));

      final session = WorkoutSession(
        id: 'sub_taxing_session',
        startTime: setTime,
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'set_1',
            sessionId: 'sub_taxing_session',
            exerciseId: 'standard_pushup',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            reportedRpe: 7,
            variables: const MillerVariables(
              load: 1,
              bodyPosition: 1,
              rom: 1,
              height: 1,
              tempo: 1,
            ),
            timestamp: setTime,
            restDuration: const Duration(seconds: 60),
          ),
        ],
      );
      await sessionRepo.saveSession(session);

      final statuses = await service.getAllPatternStatuses(currentTime: now);
      final pushing = statuses[MovementPattern.pushing]!;

      expect(pushing.isFresh, isTrue);
      expect(pushing.remainingLockDuration, equals(Duration.zero));
      expect(pushing.totalSetsIn48Hours, equals(1));
      expect(pushing.taxingSetsIn48Hours, equals(0));
    });

    test('taxing set (RPE >= 8) imposes 48h cooldown lock', () async {
      final now = DateTime(2026, 9, 9, 12, 0);
      final setTime = now.subtract(const Duration(hours: 12));

      final session = WorkoutSession(
        id: 'taxing_session',
        startTime: setTime,
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'set_taxing',
            sessionId: 'taxing_session',
            exerciseId: 'standard_pushup',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 8,
            reportedRpe: 9,
            variables: const MillerVariables(
              load: 1,
              bodyPosition: 1,
              rom: 1,
              height: 1,
              tempo: 1,
            ),
            timestamp: setTime,
            restDuration: const Duration(seconds: 60),
          ),
        ],
      );
      await sessionRepo.saveSession(session);

      final statuses = await service.getAllPatternStatuses(currentTime: now);
      final pushing = statuses[MovementPattern.pushing]!;

      expect(pushing.isFresh, isFalse);
      expect(pushing.remainingLockDuration.inHours, equals(36));
      expect(pushing.statusChipLabel, equals('48H LOCK // 36H REMAINING'));
      expect(pushing.recoveryProgress, closeTo(0.25, 0.01));

      // Other patterns remain fresh
      expect(statuses[MovementPattern.pulling]!.isFresh, isTrue);
    });

    test('expired lock (> 48h) marks pattern fresh again', () async {
      final now = DateTime(2026, 9, 9, 12, 0);
      final setTime = now.subtract(const Duration(hours: 50));

      final session = WorkoutSession(
        id: 'old_session',
        startTime: setTime,
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'set_old',
            sessionId: 'old_session',
            exerciseId: 'standard_pushup',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 8,
            reportedRpe: 10,
            variables: const MillerVariables(
              load: 1,
              bodyPosition: 1,
              rom: 1,
              height: 1,
              tempo: 1,
            ),
            timestamp: setTime,
            restDuration: const Duration(seconds: 60),
          ),
        ],
      );
      await sessionRepo.saveSession(session);

      final statuses = await service.getAllPatternStatuses(currentTime: now);
      final pushing = statuses[MovementPattern.pushing]!;

      expect(pushing.isFresh, isTrue);
      expect(pushing.remainingLockDuration, equals(Duration.zero));
    });
  });

  group('PatternRecoveryGrid Widget Tests', () {
    late SbeeDatabase database;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    Widget createTestWidget({List<Override> overrides = const []}) {
      return ProviderScope(
        overrides: [
          sbeeDatabaseProvider.overrideWithValue(database),
          ...overrides,
        ],
        child: MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: PatternRecoveryGrid(),
            ),
          ),
        ),
      );
    }

    testWidgets('renders all 5 movement pattern lines and fresh chips', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('NEUROMUSCULAR RECOVERY RADAR // 回復状況'), findsOneWidget);
      expect(find.text('48H PROTOCOL'), findsOneWidget);

      // Verify all 5 pattern line names
      expect(find.text('PUSH LINE'), findsOneWidget);
      expect(find.text('PULL LINE'), findsOneWidget);
      expect(find.text('BEND & LIFT LINE'), findsOneWidget);
      expect(find.text('SINGLE LEG LINE'), findsOneWidget);
      expect(find.text('ROTATION LINE'), findsOneWidget);

      // 5 fresh chips
      expect(find.text('FRESH // 回復済'), findsNWidgets(5));
    });

    testWidgets('renders 48H LOCK chip when a pattern is cooling down', (
      tester,
    ) async {
      final statuses = {
        MovementPattern.pushing: const PatternRecoveryStatus(
          pattern: MovementPattern.pushing,
          isFresh: false,
          remainingLockDuration: Duration(hours: 26, minutes: 30),
          totalSetsIn48Hours: 3,
          taxingSetsIn48Hours: 2,
        ),
        MovementPattern.pulling: const PatternRecoveryStatus(
          pattern: MovementPattern.pulling,
          isFresh: true,
          remainingLockDuration: Duration.zero,
        ),
        MovementPattern.bendAndLift: const PatternRecoveryStatus(
          pattern: MovementPattern.bendAndLift,
          isFresh: true,
          remainingLockDuration: Duration.zero,
        ),
        MovementPattern.singleLeg: const PatternRecoveryStatus(
          pattern: MovementPattern.singleLeg,
          isFresh: true,
          remainingLockDuration: Duration.zero,
        ),
        MovementPattern.rotation: const PatternRecoveryStatus(
          pattern: MovementPattern.rotation,
          isFresh: true,
          remainingLockDuration: Duration.zero,
        ),
      };

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            recoveryStatusProvider.overrideWith((ref) => statuses),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('48H LOCK // 26H REMAINING'), findsOneWidget);
      expect(find.text('FRESH // 回復済'), findsNWidgets(4));
    });
  });
}
