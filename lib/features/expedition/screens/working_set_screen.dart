import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../engine/engine.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: PixelCard(
          backgroundColor: colors.surfaceDark,
          borderColor: colors.amberAccent,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SKIP SET',
                style: TextStyle(
                  fontFamily: 'Courier',
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
                  fontFamily: 'Courier',
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
        ),
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final exercise = expandedExerciseGraph.findById(set.exerciseId) ??
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
        : (exercise?.defaultCues ?? ['Maintain steady core alignment and controlled tempo.']);

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
                    bottom: BorderSide(
                      color: colors.borderBright,
                      width: 2.0,
                    ),
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
                              decoration: BoxDecoration(
                                color: lineTheme.color.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: lineTheme.color,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                lineTheme.lineNameEn,
                                style: TextStyle(
                                  fontFamily: 'Courier',
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
                          decoration: BoxDecoration(
                            color: colors.backgroundVoid,
                            border: Border.all(
                              color: colors.amberAccent,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'SET ${state.currentSetIndex + 1} / ${state.totalSets}',
                            style: TextStyle(
                              fontFamily: 'Courier',
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
                        fontFamily: 'Courier',
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
                        fontFamily: 'Courier',
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
                                fontFamily: 'Courier',
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
                            fontFamily: 'Courier',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2EE6D6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Kenneth Miller Variables Tag Bar
                    PixelCard(
                      backgroundColor: colors.surfaceDark,
                      borderColor: colors.borderMuted,
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KENNETH MILLER ACTIVE VARIABLES',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 6.0,
                            children: [
                              _VariableBadge(label: 'LOAD', value: '${set.variables.load}/5'),
                              _VariableBadge(label: 'POS', value: '${set.variables.bodyPosition}/5'),
                              _VariableBadge(label: 'ROM', value: '${set.variables.rom}/5'),
                              _VariableBadge(label: 'ELEV', value: '${set.variables.height}/5'),
                              _VariableBadge(
                                label: 'TEMPO',
                                value: set.variables.tempo == 2 ? '6s (ADV)' : '4s',
                                isHighlight: set.variables.tempo == 2,
                              ),
                            ],
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
                                  fontFamily: 'Courier',
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: colors.amberAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          ...cues.map((cue) => Padding(
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
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 13.0,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
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
                              fontFamily: 'Courier',
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
                                style: TextStyle(
                                  fontFamily: 'Courier',
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
                    top: BorderSide(
                      color: colors.borderMuted,
                      width: 2.0,
                    ),
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
                        label: '⚔ COMPLETE SET',
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

class _VariableBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _VariableBadge({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: colors.backgroundVoid,
        border: Border.all(
          color: isHighlight ? const Color(0xFF2EE6D6) : colors.borderBright,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10.0,
              color: colors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              color: isHighlight ? const Color(0xFF2EE6D6) : colors.amberAccent,
            ),
          ),
        ],
      ),
    );
  }
}
