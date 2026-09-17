import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../engine/engine.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../../grimoire/widgets/exercise_illustration.dart';
import '../../grimoire/widgets/metro_transit_map.dart';
import '../controllers/active_session_controller.dart';

/// Screen 1b: Working Set Screen.
///
/// Ultra-high contrast, tactile mid-set interface rendering Japanese railway
/// station signboards, large form cues, Kenneth Miller variable metrics,
/// and mechanical rep completion inputs.
class WorkingSetScreen extends ConsumerStatefulWidget {
  const WorkingSetScreen({super.key});

  @override
  ConsumerState<WorkingSetScreen> createState() => _WorkingSetScreenState();
}

class _WorkingSetScreenState extends ConsumerState<WorkingSetScreen> {
  int _workSeconds = 0;
  Timer? _workTimer;

  @override
  void initState() {
    super.initState();
    _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _workSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handleSkip(BuildContext context) async {
    final colors = context.colors;
    final confirm = await ZenithDialog.showCard<bool>(
      context,
      borderColor: colors.amberAccent,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SKIP SET',
            style: TextStyle(
              fontFamily: 'Silkscreen',
              fontFamilyFallback: const ['monospace'],
              fontSize: 14.0,
              fontWeight: FontWeight.w900,
              color: colors.amberAccent,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Are you sure you want to skip this set? It will be logged with 0 reps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Silkscreen',
              fontFamilyFallback: const ['monospace'],
              fontSize: 12.0,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20.0),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'CANCEL',
                  variant: PixelButtonVariant.secondary,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: PixelButton(
                  label: 'SKIP',
                  variant: PixelButtonVariant.danger,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.read(activeSessionControllerProvider.notifier).skipCurrentSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(activeSessionControllerProvider);
    final controller = ref.read(activeSessionControllerProvider.notifier);

    final set = state.currentSet;
    if (set == null) {
      return const Scaffold(body: Center(child: PixelLoadingIndicator()));
    }

    final exercise =
        expandedExerciseGraph.findById(set.exerciseId) ??
        baselineExerciseGraph.findById(set.exerciseId);
    final meta = exercise != null
        ? MetroStationMeta.forExercise(exercise)
        : null;
    final lineTheme = exercise != null
        ? MetroLineTheme.forPattern(exercise.movementPattern)
        : null;

    final targetRepsText = set.hasRepRange
        ? '${set.minReps}-${set.maxReps} RM // TARGET: ${set.reps} REPS'
        : 'TARGET: ${set.reps} REPS';

    final cues = set.cues.isNotEmpty
        ? set.cues
        : (exercise?.defaultCues ??
              ['Maintain steady core alignment and controlled tempo.']);

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: RailsideAtmosphereBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Station Signboard Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceDark,
                  border: Border(
                    bottom: BorderSide(color: colors.borderBright, width: 2.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (lineTheme != null)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 3.0,
                              ),
                              decoration: ShapeDecoration(
                                color: lineTheme.color.withValues(alpha: 0.15),
                                shape: SteppedPixelBorder(
                                  side: BorderSide(
                                    color: lineTheme.color,
                                    width: 1.5,
                                  ),
                                  stepSize: context.pixelMetrics.cornerStepSize,
                                ),
                              ),
                              child: Text(
                                lineTheme.lineNameEn,
                                style: TextStyle(
                                  fontFamily: 'Silkscreen',
                                  fontFamilyFallback: const ['monospace'],
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: lineTheme.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: ShapeDecoration(
                            color: colors.backgroundVoid,
                            shape: SteppedPixelBorder(
                              side: BorderSide(
                                color: colors.amberAccent,
                                width: 1.0,
                              ),
                              stepSize: context.pixelMetrics.cornerStepSize,
                            ),
                          ),
                          child: Text(
                            'SET ${state.currentSetIndex + 1} / ${state.totalSets}',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 11.0,
                              fontWeight: FontWeight.w900,
                              color: colors.amberAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      '${meta?.stationCode ?? 'S01'} // ${(exercise?.name ?? set.exerciseId).toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      targetRepsText,
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: colors.amberGlow,
                      ),
                    ),
                  ],
                ),
              ),

              // Active Work HUD Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Timer & Cadence Strip
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12.0,
                      runSpacing: 6.0,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: colors.amberAccent,
                              size: 18.0,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              'WORK TIME: ${_formatTimer(_workSeconds)}',
                              style: TextStyle(
                                fontFamily: 'Silkscreen',
                                fontFamilyFallback: const ['monospace'],
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: colors.amberAccent,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'TARGET RPE: ${set.targetRpe}',
                          style: const TextStyle(
                            fontFamily: 'Silkscreen',
                            fontFamilyFallback: ['monospace'],
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2EE6D6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Kenneth Miller Variables Tag Bar (secondary — collapsed by default)
                    CollapsibleCard(
                      icon: Icons.tune,
                      title: "TODAY'S DIFFICULTY DIALS",
                      subtitle: 'KENNETH MILLER VARIABLES',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MillerVariableGauge(
                            label: 'LOAD',
                            score: set.variables.load,
                          ),
                          MillerVariableGauge(
                            label: 'POS',
                            score: set.variables.bodyPosition,
                          ),
                          MillerVariableGauge(
                            label: 'ROM',
                            score: set.variables.rom,
                          ),
                          MillerVariableGauge(
                            label: 'ELEV',
                            score: set.variables.height,
                          ),
                          MillerVariableGauge(
                            label: 'TEMPO',
                            score: set.variables.tempo,
                            maxScore: 2,
                            displayValueOverride: set.variables.tempo == 2
                                ? '6s (ADV)'
                                : '4s',
                            activeColor: set.variables.tempo == 2
                                ? const Color(0xFF2EE6D6)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Ultra-Legible Form Cues Card
                    PixelCard(
                      backgroundColor: colors.surfaceDark,
                      borderColor: colors.borderBright,
                      bevelColor: colors.borderMuted,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                color: colors.amberAccent,
                                size: 18.0,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'FORM CUES',
                                style: TextStyle(
                                  fontFamily: 'Silkscreen',
                                  fontFamilyFallback: const ['monospace'],
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: colors.amberAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          if (exercise != null) ...[
                            ExerciseIllustration(exercise: exercise),
                            const SizedBox(height: 12.0),
                          ],
                          ...cues.map(
                            (cue) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '■ ',
                                    style: TextStyle(
                                      color: colors.amberAccent,
                                      fontSize: 11.0,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      cue,
                                      style: zenithBodyMono(
                                        fontSize: 13.0,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Reps Completed Mechanical Adjuster
                    PixelCard(
                      backgroundColor: colors.surfaceDark,
                      borderColor: colors.amberAccent,
                      bevelColor: colors.borderMuted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'REPS COMPLETED',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PixelButton(
                                label: '−',
                                width: 54.0,
                                height: 54.0,
                                variant: PixelButtonVariant.secondary,
                                onPressed: () {
                                  controller.updateRepsInput(
                                    state.currentRepsInput - 1,
                                  );
                                },
                              ),
                              const SizedBox(width: 24.0),
                              Text(
                                '${state.currentRepsInput}',
                                style: pixelHudNumeral(
                                  fontSize: 44.0,
                                  fontWeight: FontWeight.w900,
                                  color: colors.amberAccent,
                                ),
                              ),
                              const SizedBox(width: 24.0),
                              PixelButton(
                                label: '+',
                                width: 54.0,
                                height: 54.0,
                                variant: PixelButtonVariant.secondary,
                                onPressed: () {
                                  controller.updateRepsInput(
                                    state.currentRepsInput + 1,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tactile Action Footer
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
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: PixelButton(
                        label: 'SKIP',
                        variant: PixelButtonVariant.secondary,
                        height: 52.0,
                        onPressed: () => _handleSkip(context),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      flex: 3,
                      child: PixelButton(
                        label: '✓ COMPLETE SET',
                        variant: PixelButtonVariant.primary,
                        height: 52.0,
                        onPressed: () {
                          controller.completeCurrentSet();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
