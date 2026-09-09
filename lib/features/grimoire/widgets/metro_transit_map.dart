import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../engine/expanded_catalog.dart';

/// Metro transit line visual styling configuration for each movement pattern.
class MetroLineTheme {
  final String lineNameEn;
  final String codePrefix;
  final Color color;

  const MetroLineTheme({
    required this.lineNameEn,
    required this.codePrefix,
    required this.color,
  });

  static const Map<MovementPattern, MetroLineTheme> configs = {
    MovementPattern.pushing: MetroLineTheme(
      lineNameEn: 'PUSH LINE',
      codePrefix: 'P',
      color: Color(0xFFFFAE34),
    ),
    MovementPattern.pulling: MetroLineTheme(
      lineNameEn: 'PULL LINE',
      codePrefix: 'L',
      color: Color(0xFF2EE6D6),
    ),
    MovementPattern.bendAndLift: MetroLineTheme(
      lineNameEn: 'BEND & LIFT LINE',
      codePrefix: 'B',
      color: Color(0xFFFF493A),
    ),
    MovementPattern.singleLeg: MetroLineTheme(
      lineNameEn: 'SINGLE LEG LINE',
      codePrefix: 'S',
      color: Color(0xFF4B8E62),
    ),
    MovementPattern.rotation: MetroLineTheme(
      lineNameEn: 'ROTATION LINE',
      codePrefix: 'R',
      color: Color(0xFFD154EC),
    ),
  };

  static MetroLineTheme forPattern(MovementPattern pattern) {
    return configs[pattern] ??
        MetroLineTheme(
          lineNameEn: pattern.name.toUpperCase(),
          codePrefix: pattern.name.substring(0, 1).toUpperCase(),
          color: const Color(0xFFFFAE34),
        );
  }
}

/// Interactive metro transit map diagram rendering progression routes.
class MetroTransitMap extends StatelessWidget {
  final MovementPattern? activePatternFilter;
  final ValueChanged<Exercise> onStationSelected;
  final bool isIntermediateUser;

  const MetroTransitMap({
    super.key,
    this.activePatternFilter,
    required this.onStationSelected,
    this.isIntermediateUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final patternsToRender = activePatternFilter != null
        ? [activePatternFilter!]
        : MovementPattern.values;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      itemCount: patternsToRender.length,
      itemBuilder: (context, index) {
        final pattern = patternsToRender[index];
        final lineTheme = MetroLineTheme.forPattern(pattern);
        final lineExercises =
            expandedExercises
                .where((e) => e.movementPattern == pattern)
                .toList()
              ..sort((a, b) => a.difficultyTier.compareTo(b.difficultyTier));

        return _MetroLineSection(
          lineTheme: lineTheme,
          exercises: lineExercises,
          onStationSelected: onStationSelected,
          isIntermediateUser: isIntermediateUser,
        );
      },
    );
  }
}

class _MetroLineSection extends StatelessWidget {
  final MetroLineTheme lineTheme;
  final List<Exercise> exercises;
  final ValueChanged<Exercise> onStationSelected;
  final bool isIntermediateUser;

  const _MetroLineSection({
    required this.lineTheme,
    required this.exercises,
    required this.onStationSelected,
    required this.isIntermediateUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transit Line Header
          Row(
            children: [
              Container(width: 4.0, height: 18.0, color: lineTheme.color),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  lineTheme.lineNameEn,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: lineTheme.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Stations on this line
          for (int i = 0; i < exercises.length; i++) ...[
            _MetroStationNode(
              exercise: exercises[i],
              lineColor: lineTheme.color,
              isFirst: i == 0,
              isLast: i == exercises.length - 1,
              isIntermediateUser: isIntermediateUser,
              onTap: () {
                HapticFeedback.selectionClick();
                onStationSelected(exercises[i]);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MetroStationNode extends StatelessWidget {
  final Exercise exercise;
  final Color lineColor;
  final bool isFirst;
  final bool isLast;
  final bool isIntermediateUser;
  final VoidCallback onTap;

  const _MetroStationNode({
    required this.exercise,
    required this.lineColor,
    required this.isFirst,
    required this.isLast,
    required this.isIntermediateUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = MetroStationMeta.forExercise(exercise);
    final isLocked = !isIntermediateUser && exercise.difficultyTier > 3;
    final isActiveStation = exercise.difficultyTier == 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Track and Station Circle Indicator
          SizedBox(
            width: 32.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vertical railway track connector
                Positioned(
                  top: isFirst ? 16.0 : 0.0,
                  bottom: isLast ? 16.0 : 0.0,
                  child: Container(
                    width: 3.0,
                    color: isLocked
                        ? colors.borderMuted
                        : lineColor.withValues(alpha: 0.6),
                  ),
                ),

                // Station Node Circle
                Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: isActiveStation
                        ? lineColor
                        : (isLocked
                              ? colors.surfaceDark
                              : colors.backgroundVoid),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLocked ? colors.borderMuted : lineColor,
                      width: isActiveStation ? 3.0 : 2.0,
                    ),
                    boxShadow: isActiveStation
                        ? [
                            BoxShadow(
                              color: lineColor.withValues(alpha: 0.5),
                              blurRadius: 6.0,
                              spreadRadius: 1.0,
                            ),
                          ]
                        : null,
                  ),
                  child: isActiveStation
                      ? Center(
                          child: Container(
                            width: 4.0,
                            height: 4.0,
                            decoration: BoxDecoration(
                              color: colors.surfaceDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8.0),

          // Station Details Card (Touch Target)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceDark,
                    border: Border.all(
                      color: isLocked
                          ? colors.borderMuted.withValues(alpha: 0.5)
                          : colors.borderBright,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Station Code Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: colors.backgroundVoid,
                          border: Border.all(
                            color: isLocked
                                ? colors.borderMuted
                                : lineColor.withValues(alpha: 0.7),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          meta.stationCode,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? colors.textMuted : lineColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),

                      // Exercise Name
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: isLocked
                                ? colors.textMuted
                                : colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Tier / Lock Badge
                      if (isLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: colors.backgroundVoid,
                            border: Border.all(
                              color: colors.signalRed.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'T${exercise.difficultyTier} LOCKED',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 8.0,
                              fontWeight: FontWeight.bold,
                              color: colors.signalRed,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: colors.backgroundVoid,
                            border: Border.all(
                              color: colors.borderBright,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'TIER ${exercise.difficultyTier}',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              color: colors.amberGlow,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
