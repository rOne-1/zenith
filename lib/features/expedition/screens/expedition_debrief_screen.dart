import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../controllers/active_session_controller.dart';

/// Screen 1d: Expedition Debrief Screen.
///
/// Surfaces post-expedition debrief metrics, Kenneth Miller variable adaptations,
/// volume summaries, and return to portal actions.
class ExpeditionDebriefScreen extends ConsumerWidget {
  const ExpeditionDebriefScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(activeSessionControllerProvider);
    final session = state.session;

    final completedSets = state.completedSetsCount;
    final totalReps = state.totalRepsCompleted;
    final avgRpe = state.averageRpe.toStringAsFixed(1);
    final durationSeconds = session?.endTime != null && session?.startTime != null
        ? session!.endTime!.difference(session.startTime).inSeconds
        : 0;
    final durationText = '${durationSeconds ~/ 60}m ${durationSeconds % 60}s';

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
                  vertical: 14.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPEDITION CONCLUDED // 任務完了',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 20.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                        color: colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'SESSION DEBRIEF & NEUROMUSCULAR TELEMETRY',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10.0,
                        letterSpacing: 1.0,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 2.0,
                color: colors.borderMuted,
              ),

              // Scrollable Debrief Summary
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Telemetry Grid
                    Row(
                      children: [
                        Expanded(
                          child: PixelCard(
                            backgroundColor: colors.surfaceDark,
                            borderColor: colors.borderMuted,
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COMPLETED SETS',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 9.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  '$completedSets',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 26.0,
                                    fontWeight: FontWeight.w900,
                                    color: colors.amberAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: PixelCard(
                            backgroundColor: colors.surfaceDark,
                            borderColor: colors.borderMuted,
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL VOLUME',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 9.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  '$totalReps REPS',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2EE6D6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),

                    Row(
                      children: [
                        Expanded(
                          child: PixelCard(
                            backgroundColor: colors.surfaceDark,
                            borderColor: colors.borderMuted,
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AVERAGE RPE',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 9.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  avgRpe,
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 26.0,
                                    fontWeight: FontWeight.w900,
                                    color: colors.amberGlow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: PixelCard(
                            backgroundColor: colors.surfaceDark,
                            borderColor: colors.borderMuted,
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DURATION',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 9.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  durationText,
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w900,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    // Kenneth Miller Adaptations Card
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
                                Icons.auto_graph_outlined,
                                color: colors.amberAccent,
                                size: 18.0,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'KENNETH MILLER ADAPTATIONS // 適応結果',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: colors.amberAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          if (state.adaptations.isEmpty)
                            Text(
                              'Standard baseline completed. Mastery state saved to progression ledger.',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11.0,
                                color: colors.textMuted,
                              ),
                            )
                          else
                            ...state.adaptations.map((a) {
                              final Color actionColor = switch (a.action) {
                                AutoregulationAction.increment =>
                                  const Color(0xFF2EE6D6),
                                AutoregulationAction.regress =>
                                  colors.signalRed,
                                AutoregulationAction.maintain =>
                                  colors.amberAccent,
                              };

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10.0),
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: colors.backgroundVoid,
                                  border: Border.all(
                                    color: actionColor,
                                    width: 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          a.exerciseName.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w900,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'RPE ${a.reportedRpe} (TARGET ${a.targetRpe})',
                                          style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.w700,
                                            color: actionColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      a.adaptationSummary,
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 10.0,
                                        height: 1.3,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Return Action
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
                child: PixelButton(
                  label: '◀ RETURN TO TERMINAL',
                  variant: PixelButtonVariant.primary,
                  height: 52.0,
                  onPressed: () {
                    Navigator.of(context).pop();
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
