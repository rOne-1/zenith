import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/features/districts/railside_outskirts/railside_outskirts_theme.dart';
import 'package:zenith/features/expedition/utils/warning_translator.dart';

void main() {
  group('WarningTranslator Unit Tests', () {
    test('translates PosturalWarningReason correctly into reassuring copy', () {
      expect(
        WarningTranslator.translatePosturalWarning(
          PosturalWarningReason.noPullingAvailable,
        ),
        equals(
          'Focusing on pushing movements today. Consider adding pulling gear (bands/bar) to your Armory for balanced posture.',
        ),
      );

      expect(
        WarningTranslator.translatePosturalWarning(
          PosturalWarningReason.historicalDeficit,
        ),
        equals(
          'Prioritizing upper-body pulling volume today to restore shoulder balance.',
        ),
      );

      expect(
        WarningTranslator.translatePosturalWarning(
          PosturalWarningReason.none,
        ),
        isNull,
      );
    });

    test('translates RecoveryReason correctly into reassuring copy', () {
      expect(
        WarningTranslator.translateRecoveryReason(
          RecoveryReason.allMovementPatternsLocked,
        ),
        equals(
          'High-intensity fatigue detected across all patterns. Today is an Active Recovery session (low intensity, restorative movement) to accelerate repair.',
        ),
      );

      expect(
        WarningTranslator.translateRecoveryReason(RecoveryReason.none),
        isNull,
      );
    });

    test('translates detraining state correctly into reassuring copy', () {
      expect(
        WarningTranslator.translateDetraining(isDetrained: true),
        equals(
          'Welcome back. Tempo adjusted to 4-2-1 with joint stabilization focus for safe re-acclimation.',
        ),
      );

      expect(
        WarningTranslator.translateDetraining(isDetrained: false),
        isNull,
      );
    });

    test('extractNotices extracts active notices from session', () {
      final session = WorkoutSession(
        id: 'test_session',
        startTime: DateTime(2026, 9, 8, 10, 0),
        posturalWarningReason: PosturalWarningReason.noPullingAvailable,
        recoveryReason: RecoveryReason.allMovementPatternsLocked,
      );

      final notices = WarningTranslator.extractNotices(
        session: session,
        isDetrained: true,
      );

      expect(notices.length, equals(3));
      expect(
        notices.any((n) => n.type == CoachingNoticeType.detraining),
        isTrue,
      );
      expect(
        notices.any((n) => n.type == CoachingNoticeType.recovery),
        isTrue,
      );
      expect(
        notices.any((n) => n.type == CoachingNoticeType.postural),
        isTrue,
      );
    });

    test(
      'hasCompletedSessionToday detects same-day completed sessions',
      () async {
        final database = SbeeDatabase(NativeDatabase.memory());
        final sessionRepo = DriftSessionRepository(database);

        final now = DateTime(2026, 9, 8, 14, 0);

        // Initially no sessions
        expect(
          await WarningTranslator.hasCompletedSessionToday(
            sessionRepo,
            currentTime: now,
          ),
          isFalse,
        );

        // Incomplete session today should NOT trigger same-day completed advisory
        final incompleteSession = WorkoutSession(
          id: 's_incomplete',
          startTime: DateTime(2026, 9, 8, 9, 0),
          isCompleted: false,
        );
        await sessionRepo.saveSession(incompleteSession);

        expect(
          await WarningTranslator.hasCompletedSessionToday(
            sessionRepo,
            currentTime: now,
          ),
          isFalse,
        );

        // Completed session yesterday should NOT trigger same-day completed advisory
        final yesterdaySession = WorkoutSession(
          id: 's_yesterday',
          startTime: DateTime(2026, 9, 7, 18, 0),
          endTime: DateTime(2026, 9, 7, 19, 0),
          isCompleted: true,
        );
        await sessionRepo.saveSession(yesterdaySession);

        expect(
          await WarningTranslator.hasCompletedSessionToday(
            sessionRepo,
            currentTime: now,
          ),
          isFalse,
        );

        // Completed session today triggers same-day completed advisory
        final todaySession = WorkoutSession(
          id: 's_today',
          startTime: DateTime(2026, 9, 8, 7, 30),
          endTime: DateTime(2026, 9, 8, 8, 15),
          isCompleted: true,
        );
        await sessionRepo.saveSession(todaySession);

        expect(
          await WarningTranslator.hasCompletedSessionToday(
            sessionRepo,
            currentTime: now,
          ),
          isTrue,
        );

        await database.close();
      },
    );
  });

  group('SameDayAdvisoryDialog Widget Tests', () {
    testWidgets('renders dialog and handles cancel tap', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: district01RailsideOutskirts.themeData,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await WarningTranslator.showSameDayAdvisoryDialog(
                      context,
                    );
                  },
                  child: const Text('OPEN'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text(WarningTranslator.sameDayAdvisoryTitle), findsOneWidget);
      expect(
        find.text(WarningTranslator.sameDayAdvisoryMessage),
        findsOneWidget,
      );
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('PROCEED'), findsOneWidget);

      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('handles proceed tap in advisory dialog', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: district01RailsideOutskirts.themeData,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await WarningTranslator.showSameDayAdvisoryDialog(
                      context,
                    );
                  },
                  child: const Text('OPEN'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PROCEED'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
