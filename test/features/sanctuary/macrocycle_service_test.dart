import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/sanctuary/services/macrocycle_service.dart';
import 'package:zenith/features/sanctuary/widgets/macrocycle_progress_card.dart';

/// Always reports a deload week active, regardless of the actual session
/// history -- used to prove MacrocycleService asks the engine for this
/// decision rather than independently re-deriving it.
class _AlwaysDeloadEngine extends SbeeEngine {
  _AlwaysDeloadEngine({
    required super.sessionRepository,
    required super.progressionRepository,
    required super.exerciseGraph,
  });

  @override
  Future<bool> isDeloadActive({required DateTime currentTime}) async => true;
}

void main() {
  group('MacrocycleService Unit Tests', () {
    late SbeeDatabase database;
    late DriftSessionRepository sessionRepo;
    late DriftProgressionRepository progressionRepo;
    late SbeeEngine engine;
    late MacrocycleService service;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      sessionRepo = DriftSessionRepository(database);
      progressionRepo = DriftProgressionRepository(database);
      engine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: expandedExerciseGraph,
      );
      service = MacrocycleService(sessionRepo, engine);
    });

    tearDown(() async {
      await database.close();
    });

    test('initializes at Cycle 1, Week 1 Accumulation when no session history exists', () async {
      final now = DateTime(2026, 9, 1, 10, 0);
      final status = await service.getMacrocycleStatus(currentTime: now);

      expect(status.cycleNumber, equals(1));
      expect(status.weekInCycle, equals(1));
      expect(status.phase, equals(MacrocyclePhase.accumulation));
      expect(status.isDeload, isFalse);
      expect(status.phaseName, equals('ACCUMULATION'));
      expect(status.steppedMeterText, equals('[ █ ░ ░ ░ ░ ] WEEK 1/5'));
      expect(status.completedSessionsInWeek, equals(0));
      expect(status.totalRepsInWeek, equals(0));
      expect(status.totalTonnageInWeek, equals(0));
      expect(status.cycleProgress, equals(0.2));
    });

    test('progresses across accumulation, overload, and deload phases based on elapsed days', () async {
      final programStart = DateTime(2026, 9, 1, 10, 0);

      // Save an initial completed session at programStart
      await sessionRepo.saveSession(WorkoutSession(
        id: 'session_init',
        startTime: programStart,
        isCompleted: true,
      ));

      // 10 days later: Week 2 (Accumulation)
      final statusW2 = await service.getMacrocycleStatus(
        currentTime: programStart.add(const Duration(days: 10)),
      );
      expect(statusW2.cycleNumber, equals(1));
      expect(statusW2.weekInCycle, equals(2));
      expect(statusW2.phase, equals(MacrocyclePhase.accumulation));
      expect(statusW2.steppedMeterText, equals('[ █ █ ░ ░ ░ ] WEEK 2/5'));

      // 21 days later: Week 4 (Peak Overload)
      final statusW4 = await service.getMacrocycleStatus(
        currentTime: programStart.add(const Duration(days: 21)),
      );
      expect(statusW4.cycleNumber, equals(1));
      expect(statusW4.weekInCycle, equals(4));
      expect(statusW4.phase, equals(MacrocyclePhase.overload));
      expect(statusW4.phaseName, equals('PEAK OVERLOAD'));
      expect(statusW4.steppedMeterText, equals('[ █ █ █ █ ░ ] WEEK 4/5'));

      // 28 days later: Week 5 (Rest & Deload)
      final statusW5 = await service.getMacrocycleStatus(
        currentTime: programStart.add(const Duration(days: 28)),
      );
      expect(statusW5.cycleNumber, equals(1));
      expect(statusW5.weekInCycle, equals(5));
      expect(statusW5.phase, equals(MacrocyclePhase.deload));
      expect(statusW5.isDeload, isTrue);
      expect(statusW5.phaseName, equals('REST & DELOAD'));
      expect(statusW5.steppedMeterText, equals('[ █ █ █ █ █ ] WEEK 5/5'));
      expect(statusW5.cycleProgress, equals(1.0));

      // 35 days later: Cycle 2, Week 1 (Accumulation reset)
      final statusC2W1 = await service.getMacrocycleStatus(
        currentTime: programStart.add(const Duration(days: 35)),
      );
      expect(statusC2W1.cycleNumber, equals(2));
      expect(statusC2W1.weekInCycle, equals(1));
      expect(statusC2W1.phase, equals(MacrocyclePhase.accumulation));
      expect(statusC2W1.steppedMeterText, equals('[ █ ░ ░ ░ ░ ] WEEK 1/5'));
    });

    test(
      'phase reflects SbeeEngine.isDeloadActive directly, not a re-derived formula',
      () async {
        final fakeEngine = _AlwaysDeloadEngine(
          sessionRepository: sessionRepo,
          progressionRepository: progressionRepo,
          exerciseGraph: expandedExerciseGraph,
        );
        final serviceWithFakeEngine = MacrocycleService(sessionRepo, fakeEngine);

        // Week 1 -- local weekInCycle arithmetic alone would say
        // accumulation. The engine says deload, so the service must too.
        final now = DateTime(2026, 9, 1, 10, 0);
        final status =
            await serviceWithFakeEngine.getMacrocycleStatus(currentTime: now);

        expect(status.weekInCycle, equals(1));
        expect(status.phase, equals(MacrocyclePhase.deload));
        expect(status.isDeload, isTrue);
      },
    );

    test('computes weekly training volume and load volume accurately', () async {
      final programStart = DateTime(2026, 9, 1, 9, 0);

      // Session 1 on day 1 (Week 1)
      await sessionRepo.saveSession(WorkoutSession(
        id: 's1',
        startTime: programStart,
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 's1_set1',
            sessionId: 's1',
            exerciseId: 'standard_pushup',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 10,
            targetRpe: 7,
            reportedRpe: 7,
            variables: const MillerVariables(load: 2),
            timestamp: programStart,
          ),
          WorkoutSet(
            id: 's1_set2',
            sessionId: 's1',
            exerciseId: 'standard_pushup',
            movementPattern: MovementPattern.pushing,
            setNumber: 2,
            reps: 12,
            targetRpe: 7,
            reportedRpe: 7,
            variables: const MillerVariables(load: 2),
            timestamp: programStart.add(const Duration(minutes: 5)),
          ),
        ],
      ));

      // Session 2 on day 3 (Week 1)
      final s2Time = programStart.add(const Duration(days: 2));
      await sessionRepo.saveSession(WorkoutSession(
        id: 's2',
        startTime: s2Time,
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 's2_set1',
            sessionId: 's2',
            exerciseId: 'squat',
            movementPattern: MovementPattern.bendAndLift,
            setNumber: 1,
            reps: 15,
            targetRpe: 8,
            reportedRpe: 8,
            variables: const MillerVariables(load: 3),
            timestamp: s2Time,
          ),
        ],
      ));

      // Session 3 on day 10 (Week 2 - should not affect Week 1 metrics)
      final s3Time = programStart.add(const Duration(days: 9));
      await sessionRepo.saveSession(WorkoutSession(
        id: 's3',
        startTime: s3Time,
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 's3_set1',
            sessionId: 's3',
            exerciseId: 'pullup',
            movementPattern: MovementPattern.pulling,
            setNumber: 1,
            reps: 5,
            targetRpe: 8,
            reportedRpe: 8,
            variables: const MillerVariables(load: 4),
            timestamp: s3Time,
          ),
        ],
      ));

      // Query Week 1 (Day 4)
      final week1Status = await service.getMacrocycleStatus(
        currentTime: programStart.add(const Duration(days: 3)),
      );

      expect(week1Status.weekInCycle, equals(1));
      expect(week1Status.completedSessionsInWeek, equals(2));
      expect(week1Status.completedSetsInWeek, equals(3));
      // Reps: 10 + 12 + 15 = 37
      expect(week1Status.totalRepsInWeek, equals(37));
      // Tonnage: (10*2) + (12*2) + (15*3) = 20 + 24 + 45 = 89
      expect(week1Status.totalTonnageInWeek, equals(89));

      // Query Week 2 (Day 10)
      final week2Status = await service.getMacrocycleStatus(
        currentTime: programStart.add(const Duration(days: 9, hours: 2)),
      );

      expect(week2Status.weekInCycle, equals(2));
      expect(week2Status.completedSessionsInWeek, equals(1));
      expect(week2Status.completedSetsInWeek, equals(1));
      expect(week2Status.totalRepsInWeek, equals(5));
      // Tonnage: 5 * 4 = 20
      expect(week2Status.totalTonnageInWeek, equals(20));
    });
  });

  group('MacrocycleProgressCard Widget Tests', () {
    late SbeeDatabase database;
    late DriftSessionRepository sessionRepo;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      sessionRepo = DriftSessionRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('renders header, 5-week step blocks, phase chip, and volume telemetry',
        (tester) async {
      final now = DateTime(2026, 9, 10, 12, 0);
      final programStart = now.subtract(const Duration(days: 22)); // Week 4 (Overload)

      await sessionRepo.saveSession(WorkoutSession(
        id: 'initial_session',
        startTime: programStart,
        isCompleted: true,
      ));

      await sessionRepo.saveSession(WorkoutSession(
        id: 'current_week_session',
        startTime: now.subtract(const Duration(days: 1)),
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'cw_set1',
            sessionId: 'current_week_session',
            exerciseId: 'pushup',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 20,
            targetRpe: 9,
            reportedRpe: 9,
            variables: const MillerVariables(load: 3),
            timestamp: now.subtract(const Duration(days: 1)),
          ),
        ],
      ));

      final progressionRepo = DriftProgressionRepository(database);
      final engine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: expandedExerciseGraph,
      );
      final testMacrocycle =
          await MacrocycleService(sessionRepo, engine).getMacrocycleStatus(
        currentTime: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            macrocycleProvider.overrideWith((ref) => Future.value(testMacrocycle)),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: const [ZenithDistrictColors.fallback],
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: MacrocycleProgressCard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and cycle indicator
      expect(find.text('DELOAD MACROCYCLE TRACKER'), findsOneWidget);
      expect(find.text('CYCLE 01'), findsOneWidget);

      // Verify 5 step tags
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W2'), findsOneWidget);
      expect(find.text('W3'), findsOneWidget);
      expect(find.text('PEAK'), findsOneWidget);
      expect(find.text('DELOAD'), findsOneWidget);

      // Verify phase chip
      expect(find.text('PEAK OVERLOAD'), findsOneWidget);

      // Verify guidance header
      expect(find.text('>> RESTORATIVE GUIDANCE'), findsOneWidget);

      // Verify telemetry grid labels
      expect(find.text('WEEK SESSIONS'), findsOneWidget);
      expect(find.text('WEEK REPS'), findsOneWidget);
      expect(find.text('LOAD VOLUME'), findsOneWidget);

      // Verify telemetry values
      expect(find.text('1'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('60'), findsOneWidget); // 20 reps * load 3 = 60 LV
    });
  });
}
