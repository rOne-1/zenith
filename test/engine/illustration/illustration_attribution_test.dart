import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/engine/expanded_catalog.dart';
import 'package:zenith/engine/illustration/illustration_attribution.dart';
import 'package:zenith/features/grimoire/widgets/exercise_illustration.dart';

void main() {
  group('illustration attribution', () {
    test('kEverkineticSources keys are all SVG-sourced exercise ids', () {
      for (final id in kEverkineticSources.keys) {
        expect(
          isSvgSourcedExercise(id),
          isTrue,
          reason: "'$id' in kEverkineticSources is not an SVG-sourced "
              'exercise id',
        );
      }
    });

    test(
      'kEverkineticSources stays in sync with assets/exercises/ATTRIBUTION.md',
      () {
        final attributionFile = File('assets/exercises/ATTRIBUTION.md');
        expect(
          attributionFile.existsSync(),
          isTrue,
          reason: 'ATTRIBUTION.md not found -- run this test from the '
              'package root',
        );
        final attributionText = attributionFile.readAsStringSync();

        for (final exercise in expandedExercises) {
          if (!isSvgSourcedExercise(exercise.id)) continue;

          final hasEverkineticLine = RegExp(
            '\\*\\*${RegExp.escape(exercise.id)}\\*\\*.*\\n(  - includes frames sourced from Everkinetic.*\\n)?',
          ).firstMatch(attributionText);
          expect(
            hasEverkineticLine,
            isNotNull,
            reason: "'${exercise.id}' has no entry in ATTRIBUTION.md",
          );

          final mentionsEverkinetic = hasEverkineticLine!
              .group(0)!
              .contains('Everkinetic');
          expect(
            mentionsEverkinetic,
            kEverkineticSources.containsKey(exercise.id),
            reason: mentionsEverkinetic
                ? "ATTRIBUTION.md credits Everkinetic for '${exercise.id}' "
                      'but kEverkineticSources has no entry for it'
                : "kEverkineticSources credits Everkinetic for "
                      "'${exercise.id}' but ATTRIBUTION.md doesn't",
          );
        }
      },
    );
  });
}
