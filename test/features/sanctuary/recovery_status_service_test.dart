import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/core/widgets/pixel_countdown_bar.dart';
import 'package:zenith/features/sanctuary/services/recovery_status_service.dart';
import 'package:zenith/features/sanctuary/widgets/pattern_recovery_grid.dart';

void main() {
  group('RecoveryStatusService Unit Tests', () {
    late SbeeDatabase database;
    late DriftSessionRepository sessionRepo;
    late DriftProgressionRepository progressionRepo;
    late SbeeEngine engine;
    late RecoveryStatusService service;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      sessionRepo = DriftSessionRepository(database);
      progressionRepo = DriftProgressionRepository(database);
      engine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: expandedExerciseGraph,
      );
      service = RecoveryStatusService(sessionRepo, engine);
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
        expect(statuses[pattern]?.statusChipLabel, equals('FRESH'));
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

    test(
      'unlogged set with a high targetRpe does not trigger 48h lock',
      () async {
        // A freshly generated session's sets carry a targetRpe before the
        // athlete has actually performed them (reportedRpe stays null until
        // logged). SBEE's own SafetyRules.isMovementLocked only ever counts
        // an actually-reported RPE -- an unlogged prescription must never be
        // treated as taxing, no matter how high its targetRpe is.
        final now = DateTime(2026, 9, 9, 12, 0);
        final setTime = now.subtract(const Duration(hours: 1));

        final session = WorkoutSession(
          id: 'unlogged_heavy_session',
          startTime: setTime,
          isCompleted: false,
          sets: [
            WorkoutSet(
              id: 'set_unlogged',
              sessionId: 'unlogged_heavy_session',
              exerciseId: 'standard_pushup',
              movementPattern: MovementPattern.pushing,
              setNumber: 1,
              reps: 10,
              targetRpe: 9,
              reportedRpe: null,
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
        expect(pushing.taxingSetsIn48Hours, equals(0));
      },
    );

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
            body: SingleChildScrollView(child: PatternRecoveryGrid()),
          ),
        ),
      );
    }

    testWidgets('renders all 5 movement pattern lines and fresh chips', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('NEUROMUSCULAR RECOVERY RADAR'), findsOneWidget);
      expect(find.text('48H PROTOCOL'), findsOneWidget);

      // Verify all 5 pattern line names
      expect(find.text('PUSH LINE'), findsOneWidget);
      expect(find.text('PULL LINE'), findsOneWidget);
      expect(find.text('BEND & LIFT LINE'), findsOneWidget);
      expect(find.text('SINGLE LEG LINE'), findsOneWidget);
      expect(find.text('ROTATION LINE'), findsOneWidget);

      // 5 fresh chips
      expect(find.text('FRESH'), findsNWidgets(5));

      // A fresh/ready pattern renders its bar in the district's green
      // token, not the old hardcoded cyan literal (0xFF2EE6D6) -- cyan is
      // reserved as an accent elsewhere, never a bar-fill color.
      final colors = ZenithDistrictColors.fallback;
      final bars = tester.widgetList<PixelCountdownBar>(
        find.byType(PixelCountdownBar),
      );
      expect(bars, isNotEmpty);
      for (final bar in bars) {
        expect(bar.activeColor, colors.foliageVibrant);
        expect(bar.activeColor, isNot(const Color(0xFF2EE6D6)));
      }
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
          overrides: [recoveryStatusProvider.overrideWith((ref) => statuses)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('48H LOCK // 26H REMAINING'), findsOneWidget);
      expect(find.text('FRESH'), findsNWidgets(4));
    });

    testWidgets(
      'renders without RenderFlex overflow at a narrow mobile viewport',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Longest line name ("BEND & LIFT LINE"/"SINGLE LEG LINE") paired
        // with the longest realistic status chip text, at the narrowest
        // supported width — the exact combination that risks overflow.
        final statuses = {
          MovementPattern.pushing: const PatternRecoveryStatus(
            pattern: MovementPattern.pushing,
            isFresh: true,
            remainingLockDuration: Duration.zero,
          ),
          MovementPattern.pulling: const PatternRecoveryStatus(
            pattern: MovementPattern.pulling,
            isFresh: true,
            remainingLockDuration: Duration.zero,
          ),
          MovementPattern.bendAndLift: const PatternRecoveryStatus(
            pattern: MovementPattern.bendAndLift,
            isFresh: false,
            remainingLockDuration: Duration(hours: 47, minutes: 59),
          ),
          MovementPattern.singleLeg: const PatternRecoveryStatus(
            pattern: MovementPattern.singleLeg,
            isFresh: false,
            remainingLockDuration: Duration(hours: 47, minutes: 59),
          ),
          MovementPattern.rotation: const PatternRecoveryStatus(
            pattern: MovementPattern.rotation,
            isFresh: true,
            remainingLockDuration: Duration.zero,
          ),
        };

        await tester.pumpWidget(
          createTestWidget(
            overrides: [recoveryStatusProvider.overrideWith((ref) => statuses)],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
