import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../../expedition/screens/expedition_portal_screen.dart';
import '../../expedition/services/workout_preview_service.dart';
import '../../expedition/utils/session_summary_formatter.dart';
import '../../sanctuary/services/macrocycle_service.dart';
import '../services/streak_service.dart';

/// The Outpost: Zenith's dashboard / home screen.
///
/// A condensed daily briefing -- today's session at a glance, training
/// streak, and this week's stats -- with a single entry point into the full
/// Expedition Portal itinerary. Replaces the itinerary as the app's first
/// tab (F-23): the original design never had a landing screen of its own,
/// and every tab opened straight into full task content.
class OutpostScreen extends ConsumerWidget {
  const OutpostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final previewAsync = ref.watch(workoutPreviewProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final macrocycleAsync = ref.watch(macrocycleProvider);

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: RailsideAtmosphereBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE OUTPOST',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 22.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'DAILY BRIEFING & TRAINING STATUS',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 10.0,
                        letterSpacing: 1.0,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StreakCard(streakAsync: streakAsync),
                      const SizedBox(height: 16.0),
                      _TodaySessionCard(previewAsync: previewAsync),
                      const SizedBox(height: 16.0),
                      _WeeklyStatsRow(macrocycleAsync: macrocycleAsync),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final AsyncValue<int> streakAsync;

  const _StreakCard({required this.streakAsync});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final streak = streakAsync.valueOrNull ?? 0;

    return PixelCard(
      backgroundColor: colors.surfaceDark,
      borderColor: colors.amberAccent,
      bevelColor: colors.borderMuted,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRAINING STREAK',
                  style: TextStyle(
                    fontFamily: 'Silkscreen',
                    fontFamilyFallback: const ['monospace'],
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  streak == 1 ? 'CONSECUTIVE DAY' : 'CONSECUTIVE DAYS',
                  style: TextStyle(
                    fontFamily: 'Silkscreen',
                    fontFamilyFallback: const ['monospace'],
                    fontSize: 9.0,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          streakAsync.isLoading
              ? const SizedBox(
                  width: 32.0,
                  height: 32.0,
                  child: PixelLoadingIndicator(width: 32.0, height: 8.0),
                )
              : Text(
                  '$streak',
                  style: pixelHudNumeral(
                    fontSize: 36.0,
                    fontWeight: FontWeight.w900,
                    color: colors.amberAccent,
                  ),
                ),
        ],
      ),
    );
  }
}

class _TodaySessionCard extends ConsumerWidget {
  final AsyncValue<WorkoutSession?> previewAsync;

  const _TodaySessionCard({required this.previewAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return PixelCard(
      backgroundColor: colors.surfaceDark,
      borderColor: colors.borderBright,
      bevelColor: colors.borderMuted,
      padding: const EdgeInsets.all(16.0),
      child: previewAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: PixelLoadingIndicator(),
          ),
        ),
        error: (err, stack) => Text(
          'UNABLE TO LOAD TODAY\'S SESSION: $err',
          style: TextStyle(
            fontFamily: 'Silkscreen',
            fontFamilyFallback: const ['monospace'],
            fontSize: 10.0,
            color: colors.signalRed,
          ),
        ),
        data: (session) {
          if (session == null) {
            return Text(
              'NO SESSION AVAILABLE -- CHECK YOUR DEPOT GEAR SELECTION.',
              style: TextStyle(
                fontFamily: 'Silkscreen',
                fontFamilyFallback: const ['monospace'],
                fontSize: 11.0,
                color: colors.textMuted,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDayTypeHeader(session.dayType),
                          style: TextStyle(
                            fontFamily: 'Silkscreen',
                            fontFamilyFallback: const ['monospace'],
                            fontSize: 16.0,
                            fontWeight: FontWeight.w900,
                            color: colors.amberAccent,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          formatDayTypeSubtitle(session.dayType),
                          style: TextStyle(
                            fontFamily: 'Silkscreen',
                            fontFamilyFallback: const ['monospace'],
                            fontSize: 9.0,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: ShapeDecoration(
                      color: colors.backgroundVoid,
                      shape: SteppedPixelBorder(
                        side: BorderSide(
                          color: colors.amberGlow,
                          width: 1.0,
                        ),
                        stepSize: context.pixelMetrics.cornerStepSize,
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
              const SizedBox(height: 8.0),
              Text(
                '${exerciseCountFor(session)} EXERCISES / ${session.sets.length} TOTAL SETS',
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 10.0,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 16.0),
              PixelButton(
                label: '▶ TODAY\'S EXPEDITION',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExpeditionPortalScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeeklyStatsRow extends StatelessWidget {
  final AsyncValue<MacrocycleState> macrocycleAsync;

  const _WeeklyStatsRow({required this.macrocycleAsync});

  @override
  Widget build(BuildContext context) {
    final state = macrocycleAsync.valueOrNull;

    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'SESSIONS',
            value: '${state?.completedSessionsInWeek ?? 0}',
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: _StatChip(
            label: 'SETS',
            value: '${state?.completedSetsInWeek ?? 0}',
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: _StatChip(
            label: 'TONNAGE',
            value: '${state?.totalTonnageInWeek ?? 0}',
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PixelCard(
      backgroundColor: colors.surfaceDark,
      borderColor: colors.borderMuted,
      bevelColor: colors.borderMuted,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Silkscreen',
              fontFamilyFallback: const ['monospace'],
              fontSize: 16.0,
              fontWeight: FontWeight.w900,
              color: colors.amberAccent,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Silkscreen',
              fontFamilyFallback: const ['monospace'],
              fontSize: 8.0,
              letterSpacing: 0.6,
              color: colors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
