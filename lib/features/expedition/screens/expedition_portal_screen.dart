import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../engine/engine.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../../grimoire/widgets/metro_transit_map.dart';
import '../../grimoire/widgets/station_inspector_sheet.dart';
import '../controllers/active_session_controller.dart';
import '../services/workout_preview_service.dart';
import '../utils/session_summary_formatter.dart';
import '../utils/warning_translator.dart';
import 'active_expedition_screen.dart';

/// Screen 1a: The Expedition Portal.
///
/// Serves as the primary operational terminal for Zenith operators. Backed by
/// District 01 atmospheric visuals, it renders the day's stable candidate
/// workout preview, DUP phase banner, Kenneth Miller variable insights,
/// active crash recovery prompts, and reassuring coaching advisories.
class ExpeditionPortalScreen extends ConsumerStatefulWidget {
  const ExpeditionPortalScreen({super.key});

  @override
  ConsumerState<ExpeditionPortalScreen> createState() =>
      _ExpeditionPortalScreenState();
}

class _ExpeditionPortalScreenState
    extends ConsumerState<ExpeditionPortalScreen> {
  String? _statusFeedback;
  bool _isInitiating = false;

  String _formatDepartureStamp(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y.$m.$d // $hh:$mm JST';
  }

  Future<void> _handleInitiateExpedition(WorkoutSession session) async {
    setState(() {
      _isInitiating = true;
      _statusFeedback = null;
    });

    try {
      final sessionRepo = ref.read(sessionRepositoryProvider);
      final hasCompletedToday =
          await WarningTranslator.hasCompletedSessionToday(sessionRepo);

      if (hasCompletedToday && mounted) {
        final proceed = await WarningTranslator.showSameDayAdvisoryDialog(
          context,
        );
        if (!proceed) {
          if (mounted) {
            setState(() {
              _isInitiating = false;
              _statusFeedback = 'EXPEDITION ABORTED BY OPERATOR';
            });
          }
          return;
        }
      }

      await ref
          .read(activeSessionControllerProvider.notifier)
          .startSession(session);

      if (mounted) {
        setState(() {
          _isInitiating = false;
          _statusFeedback =
              'EXPEDITION DISPATCHED (${session.sets.length} SETS)';
        });
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ActiveExpeditionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitiating = false;
          _statusFeedback = 'DISPATCH ERROR: $e';
        });
      }
    }
  }

  Future<void> _handleDiscardInterruptedSession() async {
    final sbeeService = ref.read(sbeeServiceProvider);
    await sbeeService.discardActiveSession();
    ref.read(workoutPreviewProvider.notifier).invalidate();
    if (mounted) {
      setState(() {
        _statusFeedback = 'INTERRUPTED SESSION DISCARDED';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeController = ref.watch(themeControllerProvider);
    final district = themeController.current;
    final previewAsync = ref.watch(workoutPreviewProvider);
    final resumeState = ref.watch(activeSessionResumeProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: RailsideAtmosphereBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Station Schedule HUD Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 14.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PixelButton(
                      variant: PixelButtonVariant.secondary,
                      padding: const EdgeInsets.all(8.0),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        '←',
                        style: TextStyle(
                          fontFamily: 'Silkscreen',
                          fontFamilyFallback: const ['monospace'],
                          fontSize: 18.0,
                          color: colors.amberAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ZENITH',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 22.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: colors.amberAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'PLATFORM 01 // ${district.displayName.toUpperCase()}',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 11.0,
                              letterSpacing: 1.5,
                              color: colors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: ShapeDecoration(
                            color: colors.surfaceDark,
                            shape: SteppedPixelBorder(
                              side: BorderSide(
                                color: colors.amberAccent,
                                width: 1.5,
                              ),
                              stepSize: context.pixelMetrics.cornerStepSize,
                            ),
                          ),
                          child: Text(
                            'SECTOR 01',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 10.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: colors.amberAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3.0),
                        Text(
                          _formatDepartureStamp(now),
                          style: TextStyle(
                            fontFamily: 'Silkscreen',
                            fontFamilyFallback: const ['monospace'],
                            fontSize: 9.0,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Divider Ribbon
              Container(height: 2.0, color: colors.borderMuted),

              // Main Body Content
              Expanded(
                child: previewAsync.when(
                  loading: () => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SYNCHRONIZING TIMETABLE...',
                          style: TextStyle(
                            fontFamily: 'Silkscreen',
                            fontFamilyFallback: const ['monospace'],
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: colors.amberAccent,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        const SizedBox(
                          width: 160.0,
                          child: PixelCountdownBar(progress: 0.5),
                        ),
                      ],
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: colors.signalRed,
                            size: 32.0,
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            'DISPATCH COMPILATION ERROR',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 14.0,
                              fontWeight: FontWeight.w900,
                              color: colors.signalRed,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 11.0,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          PixelButton(
                            label: 'RETRY DISPATCH',
                            variant: PixelButtonVariant.secondary,
                            onPressed: () {
                              ref
                                  .read(workoutPreviewProvider.notifier)
                                  .refreshPreview();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (session) {
                    if (session == null) {
                      return Center(
                        child: Text(
                          'NO DISPATCH AVAILABLE',
                          style: TextStyle(
                            fontFamily: 'Silkscreen',
                            fontFamilyFallback: const ['monospace'],
                            color: colors.textMuted,
                          ),
                        ),
                      );
                    }

                    // Group sets by exercise
                    final setsByExercise = <String, List<WorkoutSet>>{};
                    for (final set in session.sets) {
                      setsByExercise
                          .putIfAbsent(set.exerciseId, () => [])
                          .add(set);
                    }

                    final notices = WarningTranslator.extractNotices(
                      session: session,
                    );

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        20.0,
                        16.0,
                        20.0,
                        20.0,
                      ),
                      children: [
                        // Crash / Interrupted Session Banner
                        resumeState.when(
                          data: (manager) {
                            if (manager == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: PixelCard(
                                backgroundColor: colors.surfaceDark,
                                borderColor: colors.signalRed,
                                bevelColor: colors.signalRed,
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: colors.signalRed,
                                          size: 18.0,
                                        ),
                                        const SizedBox(width: 8.0),
                                        Expanded(
                                          child: Text(
                                            'UNFINISHED EXPEDITION',
                                            style: TextStyle(
                                              fontFamily: 'Silkscreen',
                                              fontFamilyFallback: const [
                                                'monospace',
                                              ],
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.0,
                                              color: colors.signalRed,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'An active workout was interrupted. You can resume your logged sets or discard the attempt to begin fresh.',
                                      style: TextStyle(
                                        fontFamily: 'Silkscreen',
                                        fontFamilyFallback: const ['monospace'],
                                        fontSize: 11.0,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12.0),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: PixelButton(
                                            label: 'DISCARD',
                                            variant:
                                                PixelButtonVariant.secondary,
                                            onPressed:
                                                _handleDiscardInterruptedSession,
                                          ),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Expanded(
                                          child: PixelButton(
                                            label: 'RESUME',
                                            variant: PixelButtonVariant.primary,
                                            onPressed: () {
                                              ref
                                                  .read(
                                                    activeSessionControllerProvider
                                                        .notifier,
                                                  )
                                                  .resumeSession(manager);
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ActiveExpeditionScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (error, stackTrace) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: PixelCard(
                              backgroundColor: colors.surfaceDark,
                              borderColor: colors.signalRed,
                              bevelColor: colors.signalRed,
                              padding: const EdgeInsets.all(14.0),
                              child: Text(
                                'Failed to check for an interrupted session: $error',
                                style: TextStyle(
                                  fontFamily: 'Silkscreen',
                                  fontFamilyFallback: const ['monospace'],
                                  fontSize: 11.0,
                                  color: colors.signalRed,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // DUP Phase & RM Prescription Banner
                        PixelCard(
                          backgroundColor: colors.surfaceDark,
                          borderColor: colors.amberAccent,
                          bevelColor: colors.borderMuted,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formatDayTypeHeader(session.dayType),
                                          style: TextStyle(
                                            fontFamily: 'Silkscreen',
                                            fontFamilyFallback: const [
                                              'monospace',
                                            ],
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                            color: colors.amberAccent,
                                          ),
                                        ),
                                        Text(
                                          formatDayTypeSubtitle(
                                            session.dayType,
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Silkscreen',
                                            fontFamilyFallback: const [
                                              'monospace',
                                            ],
                                            fontSize: 9.0,
                                            letterSpacing: 0.6,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: colors.backgroundVoid,
                                      shape: SteppedPixelBorder(
                                        side: BorderSide(
                                          color: colors.amberGlow,
                                          width: 1.0,
                                        ),
                                        stepSize:
                                            context.pixelMetrics.cornerStepSize,
                                      ),
                                    ),
                                    child: Text(
                                      formatRmZone(session.dayType),
                                      style: TextStyle(
                                        fontFamily: 'Silkscreen',
                                        fontFamilyFallback: const ['monospace'],
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w700,
                                        color: colors.amberGlow,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12.0,
                                runSpacing: 4.0,
                                children: [
                                  Text(
                                    'TARGET RPE: ${session.sets.isNotEmpty ? session.sets.first.targetRpe : 8}',
                                    style: const TextStyle(
                                      fontFamily: 'Silkscreen',
                                      fontFamilyFallback: ['monospace'],
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2EE6D6),
                                    ),
                                  ),
                                  Text(
                                    '·',
                                    style: TextStyle(color: colors.textMuted),
                                  ),
                                  Text(
                                    '${setsByExercise.length} EXERCISES / ${session.sets.length} TOTAL SETS',
                                    style: TextStyle(
                                      fontFamily: 'Silkscreen',
                                      fontFamilyFallback: const ['monospace'],
                                      fontSize: 11.0,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14.0),

                        // Postural / Recovery Coaching Cards (secondary — collapsed by default)
                        if (notices.isNotEmpty)
                          ...notices.map((notice) {
                            final Color noticeColor =
                                notice.type == CoachingNoticeType.recovery
                                ? const Color(0xFF2EE6D6)
                                : (notice.type == CoachingNoticeType.postural
                                      ? colors.amberAccent
                                      : colors.amberGlow);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: CollapsibleCard(
                                icon: Icons.info_outline,
                                title: notice.title,
                                accentColor: noticeColor,
                                child: Text(
                                  notice.message,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontFamilyFallback: const ['sans-serif'],
                                    fontSize: 11.0,
                                    height: 1.4,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }),

                        // Section Title: Itinerary
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'EXPEDITION ITINERARY',
                                  style: TextStyle(
                                    fontFamily: 'Silkscreen',
                                    fontFamilyFallback: const ['monospace'],
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: colors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Container(
                                  height: 1.0,
                                  color: colors.borderMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Exercise Cards
                        ...setsByExercise.entries.map((entry) {
                          final exerciseId = entry.key;
                          final exerciseSets = entry.value;
                          final exercise =
                              expandedExerciseGraph.findById(exerciseId) ??
                              baselineExerciseGraph.findById(exerciseId);

                          if (exercise == null) return const SizedBox.shrink();

                          final meta = MetroStationMeta.forExercise(exercise);
                          final lineTheme = MetroLineTheme.forPattern(
                            exercise.movementPattern,
                          );
                          final firstSet = exerciseSets.first;
                          final repText = firstSet.hasRepRange
                              ? '${firstSet.minReps}-${firstSet.maxReps} REPS'
                              : '${firstSet.reps} REPS';
                          final restSeconds =
                              firstSet.restDuration?.inSeconds ?? 90;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: PixelCard(
                              backgroundColor: colors.surfaceDark,
                              borderColor: colors.borderMuted,
                              onTap: () {
                                StationInspectorSheet.show(
                                  context,
                                  exercise: exercise,
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Pattern Badge + Tier
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6.0,
                                          vertical: 2.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: lineTheme.color.withValues(
                                            alpha: 0.15,
                                          ),
                                          border: Border.all(
                                            color: lineTheme.color,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Text(
                                          lineTheme.lineNameEn,
                                          style: TextStyle(
                                            fontFamily: 'Silkscreen',
                                            fontFamilyFallback: const [
                                              'monospace',
                                            ],
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                            color: lineTheme.color,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '[T${exercise.difficultyTier}]',
                                        style: TextStyle(
                                          fontFamily: 'Silkscreen',
                                          fontFamilyFallback: const [
                                            'monospace',
                                          ],
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w900,
                                          color: colors.amberGlow,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),

                                  // Station / Exercise Name
                                  Text(
                                    '${meta.stationCode} // ${exercise.name.toUpperCase()}',
                                    style: TextStyle(
                                      fontFamily: 'Silkscreen',
                                      fontFamilyFallback: const ['monospace'],
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),

                                  // Prescription Details: Sets x Reps & Rest
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12.0,
                                    runSpacing: 4.0,
                                    children: [
                                      Text(
                                        '${exerciseSets.length} SETS × $repText',
                                        style: TextStyle(
                                          fontFamily: 'Silkscreen',
                                          fontFamilyFallback: const [
                                            'monospace',
                                          ],
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w700,
                                          color: colors.amberAccent,
                                        ),
                                      ),
                                      Text(
                                        '·',
                                        style: TextStyle(
                                          color: colors.textMuted,
                                        ),
                                      ),
                                      Text(
                                        '${restSeconds}s REST',
                                        style: const TextStyle(
                                          fontFamily: 'Silkscreen',
                                          fontFamilyFallback: ['monospace'],
                                          fontSize: 11.0,
                                          color: Color(0xFF2EE6D6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),

                                  // Equipment Chips
                                  Wrap(
                                    spacing: 6.0,
                                    children: exercise.equipmentRequirements
                                        .map((eq) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6.0,
                                              vertical: 2.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.backgroundVoid,
                                              border: Border.all(
                                                color: colors.borderMuted,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Text(
                                              eq.name.toUpperCase(),
                                              style: TextStyle(
                                                fontFamily: 'Silkscreen',
                                                fontFamilyFallback: const [
                                                  'monospace',
                                                ],
                                                fontSize: 8.0,
                                                color: colors.textMuted,
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),

              // Status Feedback Strip
              if (_statusFeedback != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  color: colors.surfaceDark,
                  child: Text(
                    _statusFeedback!,
                    style: TextStyle(
                      fontFamily: 'Silkscreen',
                      fontFamilyFallback: const ['monospace'],
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: colors.amberAccent,
                    ),
                  ),
                ),

              // Bottom Action Bar: Hero CTA
              previewAsync.maybeWhen(
                data: (session) {
                  if (session == null) return const SizedBox.shrink();
                  // Never offer to start a new expedition while an
                  // unresolved interrupted session is being shown above --
                  // starting one anyway would create a second concurrent
                  // session and permanently orphan the interrupted one
                  // (SessionRepository only tracks the single most recently
                  // started incomplete session). The RESUME/DISCARD banner
                  // is the only valid way forward until it's resolved.
                  if (resumeState.valueOrNull != null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceDark,
                      border: Border(
                        top: BorderSide(color: colors.borderMuted, width: 2.0),
                      ),
                    ),
                    child: PixelButton(
                      label: _isInitiating
                          ? 'DISPATCHING EXPEDITION...'
                          : '▶ INITIATE EXPEDITION',
                      enabled: !_isInitiating,
                      variant: PixelButtonVariant.primary,
                      height: 48.0,
                      onPressed: () => _handleInitiateExpedition(session),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
