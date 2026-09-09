import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../services/macrocycle_service.dart';

/// Card widget visualizing the 5-week block periodization macrocycle (Accumulation,
/// Overload, Deload), stepped pixel meter, and restorative volume guidance.
class MacrocycleProgressCard extends ConsumerWidget {
  const MacrocycleProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final macrocycleAsync = ref.watch(macrocycleProvider);

    return PixelCard(
      backgroundColor: colors.surfaceDark,
      borderColor: colors.borderBright,
      bevelColor: colors.borderMuted,
      padding: const EdgeInsets.all(16.0),
      child: macrocycleAsync.when(
        data: (state) => _buildContent(context, state),
        loading: () => _buildLoading(colors),
        error: (error, _) => _buildError(colors, error.toString()),
      ),
    );
  }

  Widget _buildLoading(ZenithDistrictColors colors) {
    return SizedBox(
      height: 160.0,
      child: Center(
        child: Text(
          'CALCULATING MACROCYCLE TELEMETRY...',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: colors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildError(ZenithDistrictColors colors, String message) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        'ERROR RESOLVING MACROCYCLE: $message',
        style: TextStyle(
          fontFamily: 'Courier',
          fontSize: 11.0,
          color: colors.signalRed,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MacrocycleState state) {
    final colors = context.colors;
    final phaseColor = _resolvePhaseColor(state.phase, colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Title and Cycle Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.auto_mode_outlined,
                    color: colors.amberAccent,
                    size: 18.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRAINING CYCLE PROGRESS',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: colors.amberAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'DELOAD MACROCYCLE TRACKER',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 8.0,
                            letterSpacing: 0.5,
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
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
                'CYCLE ${state.cycleNumber.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14.0),

        // Stepped Pixel Meter (5 segmented week blocks)
        Row(
          children: List.generate(5, (index) {
            final weekNum = index + 1;
            final isPast = weekNum < state.weekInCycle;
            final isCurrent = weekNum == state.weekInCycle;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 4 ? 6.0 : 0.0),
                child: _buildWeekStepBlock(
                  colors: colors,
                  weekNum: weekNum,
                  isPast: isPast,
                  isCurrent: isCurrent,
                  phaseColor: phaseColor,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10.0),

        // Stepped text meter and Phase Chip
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.0,
          runSpacing: 6.0,
          children: [
            Text(
              state.steppedMeterText,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11.0,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: colors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                color: phaseColor.withAlpha(30),
                border: Border.all(
                  color: phaseColor,
                  width: 1.0,
                ),
              ),
              child: Text(
                state.phaseName,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: phaseColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14.0),

        // Restorative Guidance Callout
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: colors.backgroundVoid,
            border: Border.all(
              color: colors.borderMuted,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  Text(
                    '>> RESTORATIVE GUIDANCE',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: colors.amberGlow,
                    ),
                  ),
                  Text(
                    'TARGET: ${state.targetRpeGuidance}',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                state.restorativeGuidance,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10.5,
                  height: 1.35,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14.0),

        // Weekly Volume Telemetry Grid
        Row(
          children: [
            Expanded(
              child: _buildTelemetryCell(
                colors: colors,
                label: 'WEEK SESSIONS',
                value: '${state.completedSessionsInWeek}',
                unit: 'DONE',
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildTelemetryCell(
                colors: colors,
                label: 'WEEK REPS',
                value: '${state.totalRepsInWeek}',
                unit: 'REPS',
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildTelemetryCell(
                colors: colors,
                label: 'LOAD VOLUME',
                value: '${state.totalTonnageInWeek}',
                unit: 'LV',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekStepBlock({
    required ZenithDistrictColors colors,
    required int weekNum,
    required bool isPast,
    required bool isCurrent,
    required Color phaseColor,
  }) {
    final String weekTag;
    if (weekNum <= 3) {
      weekTag = 'W$weekNum';
    } else if (weekNum == 4) {
      weekTag = 'PEAK';
    } else {
      weekTag = 'DELOAD';
    }

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isCurrent) {
      bgColor = phaseColor.withAlpha(50);
      borderColor = phaseColor;
      textColor = phaseColor;
    } else if (isPast) {
      bgColor = colors.surfaceElevated;
      borderColor = colors.borderBright;
      textColor = colors.textPrimary;
    } else {
      bgColor = colors.backgroundVoid;
      borderColor = colors.borderMuted;
      textColor = colors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Text(
            weekTag,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 9.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            isPast ? '✓' : (isCurrent ? '●' : '○'),
            style: TextStyle(
              fontSize: 8.0,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCell({
    required ZenithDistrictColors colors,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border.all(
          color: colors.borderMuted,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 14.0,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 4.0),
              Text(
                unit,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8.0,
                  fontWeight: FontWeight.w700,
                  color: colors.amberGlow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _resolvePhaseColor(MacrocyclePhase phase, ZenithDistrictColors colors) {
    switch (phase) {
      case MacrocyclePhase.accumulation:
        return colors.amberAccent;
      case MacrocyclePhase.overload:
        return colors.signalRed;
      case MacrocyclePhase.deload:
        return colors.foliageVibrant;
    }
  }
}
