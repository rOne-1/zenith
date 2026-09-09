import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../engine/engine.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../../grimoire/widgets/metro_transit_map.dart';
import '../controllers/active_session_controller.dart';

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

  String _getRpeHint(int rpe) {
    switch (rpe) {
      case 1:
      case 2:
      case 3:
      case 4:
        return 'Active recovery intensity. Effortless, no muscular strain (4+ reps in reserve).';
      case 5:
      case 6:
        return 'Moderate warm-up effort. Noticeable effort with 3-4 reps in reserve.';
      case 7:
        return 'Vigorous speed & power zone. ~3 reps in reserve, explosive intent.';
      case 8:
        return 'Heavy training stimulus. 2 reps in reserve. Threshold for 48h pattern recovery lock.';
      case 9:
        return 'Near-maximal effort. 1 rep in reserve. Triggers 48h movement lock.';
      case 10:
        return 'Maximum effort. 0 reps in reserve, absolute mechanical failure reached.';
      default:
        return '';
    }
  }

  String _getAutoregulationFeedback({
    required int selectedRpe,
    required int targetRpe,
  }) {
    if (selectedRpe < targetRpe - 1) {
      return 'UNDER-STIMULATED // PROGRESSION (+1 Load/ROM adaptation recommended)';
    } else if (selectedRpe > targetRpe + 1) {
      return 'HIGH FATIGUE // REGRESSION PROTECTION (Load buffer will be applied)';
    } else {
      return 'OPTIMAL STIMULUS // MASTERY SOLIDIFIED (Current parameters maintained)';
    }
  }

  Color _getFeedbackColor({
    required int selectedRpe,
    required int targetRpe,
    required ZenithDistrictColors colors,
  }) {
    if (selectedRpe < targetRpe - 1) {
      return const Color(0xFF2EE6D6); // Progression cyan
    } else if (selectedRpe > targetRpe + 1) {
      return colors.signalRed; // Regression buffer
    } else {
      return colors.amberAccent; // Optimal
    }
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
                              fontFamily: 'Courier',
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
                              fontFamily: 'Courier',
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
                        fontFamily: 'Courier',
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

              Container(
                height: 2.0,
                color: colors.borderMuted,
              ),

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
                              Text(
                                'REST TIME REMAINING',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textMuted,
                                ),
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
                            style: TextStyle(
                              fontFamily: 'Courier',
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
                    PixelCard(
                      backgroundColor: colors.surfaceDark,
                      borderColor: colors.borderBright,
                      bevelColor: colors.borderMuted,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'SET EXERTION (BORG RPE)',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: colors.amberAccent,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.backgroundVoid,
                                  border: Border.all(
                                    color: const Color(0xFF2EE6D6),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  'TARGET: $targetRpe RPE',
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2EE6D6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14.0),

                          // 1–10 RPE Selector Grid (Row 1: 1-5, Row 2: 6-10)
                          Row(
                            children: List.generate(5, (index) {
                              final score = index + 1;
                              final isSelected = selectedRpe == score;
                              final isTarget = targetRpe == score;
                              return Expanded(
                                child: _RpeButton(
                                  score: score,
                                  isSelected: isSelected,
                                  isTarget: isTarget,
                                  onTap: () => controller.logRpe(score),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6.0),
                          Row(
                            children: List.generate(5, (index) {
                              final score = index + 6;
                              final isSelected = selectedRpe == score;
                              final isTarget = targetRpe == score;
                              return Expanded(
                                child: _RpeButton(
                                  score: score,
                                  isSelected: isSelected,
                                  isTarget: isTarget,
                                  onTap: () => controller.logRpe(score),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14.0),

                          // Selected RPE Coaching Hint
                          Container(
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
                                Row(
                                  children: [
                                    Text(
                                      'RPE $selectedRpe: ',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w900,
                                        color: colors.amberAccent,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _getRpeHint(selectedRpe),
                                        style: TextStyle(
                                          fontFamily: 'Courier',
                                          fontSize: 10.0,
                                          height: 1.3,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  _getAutoregulationFeedback(
                                    selectedRpe: selectedRpe,
                                    targetRpe: targetRpe,
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    color: _getFeedbackColor(
                                      selectedRpe: selectedRpe,
                                      targetRpe: targetRpe,
                                      colors: colors,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18.0),

                    // "Next Up" Station Preview Ticket
                    if (nextExercise != null && nextMeta != null)
                      PixelCard(
                        backgroundColor: colors.surfaceDark,
                        borderColor: colors.borderMuted,
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'NEXT STATION',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: colors.textMuted,
                                  ),
                                ),
                                if (nextLineTheme != null)
                                  Text(
                                    nextLineTheme.lineNameEn,
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w700,
                                      color: nextLineTheme.color,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              '${nextMeta.stationCode} // ${nextExercise.name.toUpperCase()}',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Prescribed: ${nextSet?.reps ?? 10} reps · Equipment: ${nextExercise.equipmentRequirements.map((e) => e.name.toUpperCase()).join(', ')}',
                              style: TextStyle(
                                fontFamily: 'Courier',
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
                    top: BorderSide(
                      color: colors.borderMuted,
                      width: 2.0,
                    ),
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

class _RpeButton extends StatefulWidget {
  final int score;
  final bool isSelected;
  final bool isTarget;
  final VoidCallback onTap;

  const _RpeButton({
    required this.score,
    required this.isSelected,
    required this.isTarget,
    required this.onTap,
  });

  @override
  State<_RpeButton> createState() => _RpeButtonState();
}

class _RpeButtonState extends State<_RpeButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final score = widget.score;
    final isSelected = widget.isSelected;
    final isTarget = widget.isTarget;

    final Color bgColor = isSelected
        ? colors.amberAccent
        : (isTarget ? colors.surfaceHighlight : colors.backgroundVoid);
    final Color textColor = isSelected
        ? colors.backgroundVoid
        : (isTarget ? colors.amberAccent : colors.textPrimary);
    final Color borderColor = isTarget
        ? const Color(0xFF2EE6D6)
        : (isSelected ? colors.amberAccent : colors.borderBright);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: _isPressed
            ? const Duration(milliseconds: 60)
            : HouseSpring.duration,
        curve: HouseSpring.curve,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          height: 38.0,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: borderColor,
              width: isTarget || isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 13.0,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
