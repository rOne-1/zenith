import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/sanctuary/sanctuary.dart';

void main() {
  group('SanctuaryScreen Widget Integration Tests', () {
    late SbeeDatabase database;
    late DriftSessionRepository sessionRepo;
    late DriftProgressionRepository progressionRepo;

    setUp(() {
      database = SbeeDatabase(NativeDatabase.memory());
      sessionRepo = DriftSessionRepository(database);
      progressionRepo = DriftProgressionRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('renders all sanctuary components: recovery radar, macrocycle, adaptation ledger',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime(2026, 9, 8, 12, 0);

      // Seed an initial completed workout session
      await sessionRepo.saveSession(
        WorkoutSession(
          id: 'test_session_1',
          startTime: now.subtract(const Duration(days: 10)),
          isCompleted: true,
          sets: [
            WorkoutSet(
              id: 'ts1_s1',
              sessionId: 'test_session_1',
              exerciseId: 'standard_pushup',
              movementPattern: MovementPattern.pushing,
              setNumber: 1,
              reps: 10,
              targetRpe: 7,
              reportedRpe: 7,
              variables: const MillerVariables(load: 2),
              timestamp: now.subtract(const Duration(days: 10)),
            ),
          ],
        ),
      );

      // Seed an exercise progression
      await progressionRepo.saveProgression(
        ExerciseProgression(
          exerciseId: 'standard_pushup',
          variables: const MillerVariables(load: 2, rom: 2),
          competencyLevel: 2,
          lastPerformed: now.subtract(const Duration(days: 10)),
        ),
      );

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            sbeeDatabaseProvider.overrideWithValue(database),
            sessionRepositoryProvider.overrideWithValue(sessionRepo),
            progressionRepositoryProvider.overrideWithValue(progressionRepo),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: const [ZenithDistrictColors.fallback],
            ),
            home: const SanctuaryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Allow asynchronous database providers to resolve
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // 1. Header & Supercompensation Banner
      expect(find.text('SANCTUARY // 聖域'), findsOneWidget);
      expect(find.text('REST & PHYSIOLOGICAL ADAPTATION CHAMBER'), findsOneWidget);
      expect(find.text('STATUS: NOMINAL'), findsOneWidget);
      expect(find.text('NEUROMUSCULAR SUPERCOMPENSATION // 超回復'), findsOneWidget);

      // 2. Pattern Recovery Radar
      expect(find.text('NEUROMUSCULAR RECOVERY RADAR // 回復状況'), findsOneWidget);
      expect(find.text('48H PROTOCOL'), findsOneWidget);

      // 3. Deload Macrocycle Tracker
      expect(find.text('DELOAD MACROCYCLE TRACKER // 周期管理'), findsOneWidget);
      expect(find.text('>> RESTORATIVE GUIDANCE // 指針'), findsOneWidget);

      // 4. Kenneth Miller Adaptation Ledger
      expect(find.text('KENNETH MILLER ADAPTATION LEDGER // 変数進捗'), findsOneWidget);

      // 5. District Environment Telemetry
      expect(find.text('DISTRICT ATMOSPHERE // 地区環境テレメトリー'), findsOneWidget);
    });

    testWidgets(
      'renders without RenderFlex overflow at a narrow mobile viewport',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final now = DateTime(2026, 9, 8, 12, 0);

        await sessionRepo.saveSession(
          WorkoutSession(
            id: 'test_session_1',
            startTime: now.subtract(const Duration(days: 10)),
            isCompleted: true,
            sets: [
              WorkoutSet(
                id: 'ts1_s1',
                sessionId: 'test_session_1',
                exerciseId: 'standard_pushup',
                movementPattern: MovementPattern.pushing,
                setNumber: 1,
                reps: 10,
                targetRpe: 7,
                reportedRpe: 7,
                variables: const MillerVariables(load: 2),
                timestamp: now.subtract(const Duration(days: 10)),
              ),
            ],
          ),
        );

        await progressionRepo.saveProgression(
          ExerciseProgression(
            exerciseId: 'standard_pushup',
            variables: const MillerVariables(load: 2, rom: 2),
            competencyLevel: 2,
            lastPerformed: now.subtract(const Duration(days: 10)),
          ),
        );

        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              sbeeDatabaseProvider.overrideWithValue(database),
              sessionRepositoryProvider.overrideWithValue(sessionRepo),
              progressionRepositoryProvider.overrideWithValue(progressionRepo),
            ],
            child: MaterialApp(
              theme: ThemeData.dark().copyWith(
                extensions: const [ZenithDistrictColors.fallback],
              ),
              home: const SanctuaryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
