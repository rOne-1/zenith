import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/miller_variable_gauge.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/stepped_pixel_border.dart';
import '../../../engine/expanded_catalog.dart';

/// Japanese railway inspection pass / station detail sheet for an [Exercise].
class StationInspectorSheet extends StatelessWidget {
  final Exercise exercise;
  final bool isIntermediateUser;

  const StationInspectorSheet({
    super.key,
    required this.exercise,
    this.isIntermediateUser = false,
  });

  /// Displays this inspector sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Exercise exercise,
    bool isIntermediateUser = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StationInspectorSheet(
        exercise: exercise,
        isIntermediateUser: isIntermediateUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;
    final meta = MetroStationMeta.forExercise(exercise);
    final isTierLocked = !isIntermediateUser && exercise.difficultyTier > 3;

    final equipmentNames = exercise.equipmentRequirements
        .map((e) => e.name.toUpperCase())
        .join(' · ');

    final String statusBadgeText;
    final Color statusColor;

    if (isTierLocked) {
      statusBadgeText = 'INTERMEDIATE LOCKED';
      statusColor = colors.signalRed;
    } else if (exercise.difficultyTier == 1) {
      statusBadgeText = 'ACTIVE ROUTE';
      statusColor = colors.amberAccent;
    } else {
      statusBadgeText = 'TIER UNLOCKED';
      statusColor = colors.amberGlow;
    }

    return DragToDismissSheet(
      onDismiss: () => Navigator.of(context).pop(),
      handleColor: colors.borderBright,
      child: Container(
        decoration: ShapeDecoration(
          color: colors.surfaceDark,
          shape: SteppedPixelBorder(
            side: BorderSide(
              color: colors.borderBright,
              width: metrics.borderWidth,
            ),
            stepSize: metrics.cornerStepSize,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ticket Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: colors.backgroundVoid,
                            border: Border.all(
                              color: colors.amberAccent,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            meta.stationCode,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12.0,
                              fontWeight: FontWeight.w900,
                              color: colors.amberAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'STATION INSPECTION PASS',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: colors.backgroundVoid,
                        border: Border.all(color: statusColor, width: 1.0),
                      ),
                      child: Text(
                        statusBadgeText,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Exercise Title
                Text(
                  exercise.name,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 18.0,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Route & Equipment Pills
                Wrap(
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: [
                    _PillBadge(
                      label:
                          'TIER ${exercise.difficultyTier} // ${exercise.movementPattern.name.toUpperCase()}',
                      color: colors.borderBright,
                      textColor: colors.textPrimary,
                    ),
                    _PillBadge(
                      label: 'GEAR: $equipmentNames',
                      color: colors.borderMuted,
                      textColor: colors.textMuted,
                    ),
                  ],
                ),

                const SizedBox(height: 20.0),
                const Divider(height: 1.0, thickness: 1.0),
                const SizedBox(height: 16.0),

                // Biomechanical Form Cues Terminal
                Text(
                  'BIOMECHANICAL FORM SPECIFICATIONS',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: colors.amberAccent,
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: colors.backgroundVoid,
                    border: Border.all(color: colors.borderMuted, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < exercise.defaultCues.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '> ',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: colors.amberAccent,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  exercise.defaultCues[i],
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11.0,
                                    height: 1.4,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // Kenneth Miller 5-Variable Segmented Gauges
                Text(
                  'KENNETH MILLER PROGRESSION GAUGES',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: colors.amberAccent,
                  ),
                ),
                const SizedBox(height: 10.0),
                MillerVariableGauge(
                  label: 'LOAD VECTOR',
                  score: meta.defaultLoadScore,
                ),
                MillerVariableGauge(
                  label: 'BODY POSITION',
                  score: meta.defaultPositionScore,
                ),
                MillerVariableGauge(
                  label: 'RANGE OF MOTION',
                  score: meta.defaultRomScore,
                ),
                MillerVariableGauge(
                  label: 'LIMB ELEVATION',
                  score: meta.defaultElevationScore,
                ),
                MillerVariableGauge(
                  label: 'TEMPO / TIME-UNDER-TENSION',
                  score: meta.defaultTempoScore,
                ),

                const SizedBox(height: 24.0),

                // Close Button
                PixelButton(
                  label: 'CLOSE INSPECTOR',
                  variant: PixelButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _PillBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: color, width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Courier',
          fontSize: 9.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }
}

