import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../engine/engine.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../../grimoire/widgets/metro_transit_map.dart';
import '../controllers/active_session_controller.dart';
import '../widgets/rpe_selector_card.dart';

/// Screen 1c: Rest & RPE Log Screen.
///
/// Provides an atmospheric rest period with amber streetlight digital countdown,
/// 1-10 Borg RPE tactile selector, Kenneth Miller autoregulation coaching hints,
/// and next-station transit preview tickets.
class RestScreen extends ConsumerWidget {
  const RestScreen({super.key});

  String _formatRestTime(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(activeSessionControllerProvider);
    final controller = ref.read(activeSessionControllerProvider.notifier);

    final set = state.currentSet;
    final nextSet = state.nextSet;
    final targetRpe = set?.targetRpe ?? 8;
    final selectedRpe = state.selectedRpe ?? targetRpe;

    // Countdown progress calculation
    final totalSeconds = state.totalRest.inSeconds > 0
        ? state.totalRest.inSeconds
        : 90;
    final remainingSeconds = state.restRemaining.inSeconds;
    final progress = (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

    // Next exercise preview details
    final nextExercise = nextSet != null
        ? (expandedExerciseGraph.findById(nextSet.exerciseId) ??
              baselineExerciseGraph.findById(nextSet.exerciseId))
        : null;
    final nextMeta = nextExercise != null
        ? MetroStationMeta.forExercise(nextExercise)
        : null;
    final nextLineTheme = nextExercise != null
        ? MetroLineTheme.forPattern(nextExercise.movementPattern)
        : null;

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: RailsideAtmosphereBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REST & RECOVERY',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 16.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: colors.amberAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'METABOLIC CLEARANCE & RPE LOGGING',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 9.0,
                              letterSpacing: 0.8,
                              color: colors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'SET ${state.currentSetIndex + 1} DONE',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: colors.amberGlow,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Container(height: 2.0, color: colors.borderMuted),

              // Scrollable Rest Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Amber Streetlight Rest Countdown
                    PixelCard(
                      backgroundColor: colors.surfaceDark,
                      borderColor: colors.amberAccent,
                      bevelColor: colors.borderMuted,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PixelPulseDot(
                                    color: colors.amberAccent,
                                    size: 8.0,
                                    animate: remainingSeconds > 0,
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    'REST TIME REMAINING',
                                    style: TextStyle(
                                      fontFamily: 'Silkscreen',
                                      fontFamilyFallback: const ['monospace'],
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              PixelButton(
                                label: '+30s',
                                variant: PixelButtonVariant.secondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 3.0,
                                ),
                                onPressed: () => controller.addRestTime(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            _formatRestTime(state.restRemaining),
                            style: pixelHudNumeral(
                              fontSize: 52.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: remainingSeconds > 0
                                  ? colors.amberAccent
                                  : colors.signalRed,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          PixelCountdownBar(
                            progress: progress,
                            height: 14.0,
                            activeColor: colors.amberAccent,
                            inactiveColor: colors.borderMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18.0),

                    // 1–10 Borg RPE Pixel Selector
                    RpeSelectorCard(
                      targetRpe: targetRpe,
                      selectedRpe: selectedRpe,
                      onSelect: controller.logRpe,
                    ),
                    const SizedBox(height: 18.0),

                    // "Next Up" Station Preview Ticket (secondary — collapsed by default)
                    if (nextExercise != null && nextMeta != null)
                      CollapsibleCard(
                        icon: Icons.arrow_forward,
                        title: 'NEXT: ${nextExercise.name.toUpperCase()}',
                        subtitle: nextLineTheme?.lineNameEn,
                        accentColor: nextLineTheme?.color,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${nextMeta.stationCode} // ${nextExercise.name.toUpperCase()}',
                              style: TextStyle(
                                fontFamily: 'Silkscreen',
                                fontFamilyFallback: const ['monospace'],
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Prescribed: ${nextSet?.reps ?? 10} reps · Equipment: ${nextExercise.equipmentRequirements.map((e) => e.name.toUpperCase()).join(', ')}',
                              style: TextStyle(
                                fontFamily: 'Silkscreen',
                                fontFamilyFallback: const ['monospace'],
                                fontSize: 10.0,
                                color: colors.amberGlow,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Action Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 14.0,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceDark,
                  border: Border(
                    top: BorderSide(color: colors.borderMuted, width: 2.0),
                  ),
                ),
                child: PixelButton(
                  label: remainingSeconds <= 0
                      ? '▶ START NEXT SET'
                      : 'SKIP REST & START NEXT SET',
                  variant: PixelButtonVariant.primary,
                  height: 52.0,
                  onPressed: () {
                    controller.completeRest();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
