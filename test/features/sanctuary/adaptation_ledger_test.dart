import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/features/sanctuary/services/adaptation_ledger_service.dart';
import 'package:zenith/features/sanctuary/widgets/adaptation_ledger_card.dart';

void main() {
  group('AdaptationLedgerService Unit Tests', () {
    late SbeeDatabase database;
    late DriftProgressionRepository progressionRepo;
    late DriftSessionRepository sessionRepo;
    late AdaptationLedgerService service;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      progressionRepo = DriftProgressionRepository(database);
      sessionRepo = DriftSessionRepository(database);
      service = AdaptationLedgerService(progressionRepo, sessionRepo);
    });

    tearDown(() async {
      await database.close();
    });

    test('provides baseline exercises when no user progressions are recorded', () async {
      final state = await service.getLedgerState();

      expect(state.adaptations.isNotEmpty, isTrue);
      expect(state.highestCompetencyTier, equals(1));
      expect(state.totalVariablesUpgraded, equals(0));

      final pushup = state.adaptations.firstWhere((a) => a.exerciseId == 'standard_pushup');
      expect(pushup.competencyLevel, equals(1));
      expect(pushup.variables.load, equals(1));
      expect(pushup.variables.bodyPosition, equals(1));
      expect(pushup.variables.rom, equals(1));
      expect(pushup.variables.height, equals(1));
      expect(pushup.variables.tempo, equals(1));
      expect(pushup.tierLabel, equals('TIER 01'));
      expect(pushup.masteryTitle, equals('NOVICE'));
    });

    test('reads stored progressions, calculates upgraded variables and highest tier', () async {
      final now = DateTime(2026, 9, 8, 14, 0);

      await progressionRepo.saveProgression(
        ExerciseProgression(
          exerciseId: 'standard_pushup',
          variables: const MillerVariables(
            load: 3,
            bodyPosition: 2,
            rom: 1,
            height: 1,
            tempo: 1,
          ),
          competencyLevel: 2,
          lastPerformed: now,
        ),
      );

      await progressionRepo.saveProgression(
        ExerciseProgression(
          exerciseId: 'squat',
          variables: const MillerVariables(
            load: 4,
            bodyPosition: 1,
            rom: 3,
            height: 1,
            tempo: 2,
          ),
          competencyLevel: 3,
          lastPerformed: now,
        ),
      );

      final state = await service.getLedgerState(currentTime: now);

      expect(state.highestCompetencyTier, equals(3));
      // Upgrades:
      // standard_pushup: (3-1) + (2-1) = 3
      // squat: (4-1) + (3-1) + (2-1) = 3 + 2 + 1 = 6
      // Total: 9
      expect(state.totalVariablesUpgraded, equals(9));

      final squatItem = state.adaptations.firstWhere((a) => a.exerciseId == 'squat');
      expect(squatItem.competencyLevel, equals(3));
      expect(squatItem.tierLabel, equals('TIER 03'));
      expect(squatItem.masteryTitle, equals('ADVANCED'));
      expect(squatItem.hasAdvancedVariables, isTrue);
    });

    test('detects autoregulation promotion events from recent completed sessions', () async {
      final now = DateTime(2026, 9, 8, 14, 0);

      await sessionRepo.saveSession(WorkoutSession(
        id: 'promo_session',
        startTime: now.subtract(const Duration(days: 2)),
        isCompleted: true,
        sets: [
          WorkoutSet(
            id: 'p_set_1',
            sessionId: 'promo_session',
            exerciseId: 'standard_pushup',
            movementPattern: MovementPattern.pushing,
            setNumber: 1,
            reps: 12,
            targetRpe: 7,
            reportedRpe: 5, // <= 6 -> promotion trigger
            variables: const MillerVariables(load: 2),
            timestamp: now.subtract(const Duration(days: 2)),
          ),
        ],
      ));

      final state = await service.getLedgerState(currentTime: now);

      expect(state.recentPromotions.isNotEmpty, isTrue);
      final promo = state.recentPromotions.first;
      expect(promo.exerciseName.toUpperCase(), contains('PUSH'));
      expect(promo.variableDelta, contains('RPE 5'));
    });
  });

  group('AdaptationLedgerCard Widget Tests', () {
    testWidgets('renders ledger title, variable meters, and promotions callout',
        (tester) async {
      final now = DateTime(2026, 9, 8, 14, 0);

      final testState = AdaptationLedgerState(
        adaptations: [
          MillerAdaptationItem(
            exerciseId: 'standard_pushup',
            exerciseName: 'Standard Pushup',
            pattern: MovementPattern.pushing,
            variables: const MillerVariables(load: 2, rom: 3),
            competencyLevel: 2,
            lastPerformed: now,
          ),
        ],
        recentPromotions: [
          PromotionEvent(
            exerciseName: 'Standard Pushup',
            variableDelta: 'LOAD L2 // RPE 5',
            description: 'Capacity exceeded. Upgraded load.',
            timestamp: now,
          ),
        ],
        totalVariablesUpgraded: 3,
        highestCompetencyTier: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adaptationLedgerProvider.overrideWith((ref) => Future.value(testState)),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: const [ZenithDistrictColors.fallback],
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: AdaptationLedgerCard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and tier badge
      expect(find.text('KENNETH MILLER ADAPTATION LEDGER'), findsOneWidget);
      expect(find.text('MAX TIER 02'), findsOneWidget);

      // Verify recent promotions callout
      expect(find.text('>> RECENT AUTOREGULATION PROMOTIONS'), findsOneWidget);
      expect(find.text('LOAD L2 // RPE 5'), findsOneWidget);

      // Verify exercise card (appears in both promotion feed and adaptation tile)
      expect(find.text('STANDARD PUSHUP'), findsNWidgets(2));
      expect(find.text('TIER 02 // PROFICIENT'), findsOneWidget);

      // Verify 5 variable meters
      expect(find.text('LOAD L2'), findsOneWidget);
      expect(find.text('POS L1'), findsOneWidget);
      expect(find.text('ROM L3'), findsOneWidget);
      expect(find.text('ELEV L1'), findsOneWidget);
      expect(find.text('TEMPO'), findsOneWidget);
    });

    testWidgets(
      'renders without RenderFlex overflow at a narrow mobile viewport with a long exercise name',
      (tester) async {
        final now = DateTime(2026, 9, 8, 14, 0);

        // Deliberately long, realistic catalog-style exercise name — the
        // actual overflow risk vector for the exercise-title row.
        final testState = AdaptationLedgerState(
          adaptations: [
            MillerAdaptationItem(
              exerciseId: 'assisted_single_leg_romanian_deadlift',
              exerciseName:
                  'Assisted Single-Leg Romanian Deadlift With Band Anchor',
              pattern: MovementPattern.bendAndLift,
              variables: const MillerVariables(load: 4, rom: 5, tempo: 2),
              competencyLevel: 3,
              lastPerformed: now,
            ),
          ],
          recentPromotions: const [],
          totalVariablesUpgraded: 8,
          highestCompetencyTier: 3,
        );

        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              adaptationLedgerProvider.overrideWith(
                (ref) => Future.value(testState),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData.dark().copyWith(
                extensions: const [ZenithDistrictColors.fallback],
              ),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: AdaptationLedgerCard(),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
