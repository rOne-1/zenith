import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/expanded_catalog.dart';
import 'package:zenith/features/grimoire/widgets/exercise_illustration.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark().copyWith(
      extensions: const [ZenithDistrictColors.fallback],
    ),
    home: Scaffold(
      body: SizedBox(width: 320, child: child),
    ),
  );
}

void main() {
  group('ExerciseIllustration', () {
    testWidgets('renders a known SVG-sourced exercise without exception', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ExerciseIllustration(exercise: standardPushup)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ExerciseIllustration), findsOneWidget);
    });

    testWidgets('renders a known custom-rig exercise without exception', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ExerciseIllustration(exercise: hipHinge)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets(
      'every catalog exercise renders without exception or overflow at a narrow (320px) viewport',
      (tester) async {
        for (final exercise in expandedExercises) {
          await tester.pumpWidget(_wrap(ExerciseIllustration(exercise: exercise)));
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: '${exercise.id} threw while rendering',
          );
        }
      },
    );
  });
}
