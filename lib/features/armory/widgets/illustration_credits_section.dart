import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/collapsible_card.dart';
import '../../../engine/expanded_catalog.dart';
import '../../../engine/illustration/illustration_attribution.dart';
import '../../grimoire/widgets/exercise_illustration.dart';

/// Collapsed-by-default credits card for the exercise illustrations, styled
/// like the Depot screen's other [CollapsibleCard] sections. Satisfies
/// CC BY-SA 4.0's attribution requirement with credit visible to anyone who
/// encounters the illustrations in the app, not just in source -- see
/// `local-notes/architecture/exercise_illustration_rig.md` §2.1.
class IllustrationCreditsSection extends StatelessWidget {
  const IllustrationCreditsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final svgSourcedExercises = expandedExercises
        .where((e) => isSvgSourcedExercise(e.id))
        .toList();

    return CollapsibleCard(
      icon: Icons.brush_outlined,
      title: 'ILLUSTRATION CREDITS',
      subtitle: '${svgSourcedExercises.length} EXERCISES · CC BY-SA 4.0',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercise illustrations adapted from workout-guide by '
            '$kIllustrationCreatorName ($kIllustrationCreatorUrl), '
            'licensed under $kIllustrationLicenseName '
            '($kIllustrationLicenseUrl). Some frames are further adapted '
            'from Everkinetic artwork, also $kIllustrationLicenseName. '
            'Recolored at render time to match district theming, an '
            'adaptation under the same license.',
            style: TextStyle(fontSize: 11.0, height: 1.4, color: colors.textMuted),
          ),
          const SizedBox(height: 4.0),
          Text(
            kIllustrationSourceRepoUrl,
            style: TextStyle(
              fontSize: 11.0,
              color: colors.amberAccent,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'SOURCED EXERCISES',
            style: TextStyle(
              fontFamily: 'Silkscreen',
              fontFamilyFallback: const ['monospace'],
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 6.0),
          for (final exercise in svgSourcedExercises)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                kEverkineticSources.containsKey(exercise.id)
                    ? '${exercise.name} — includes Everkinetic artwork'
                    : exercise.name,
                style: TextStyle(fontSize: 10.5, color: colors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}
