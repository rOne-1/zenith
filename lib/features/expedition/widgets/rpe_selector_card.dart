import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Reusable 1-10 Borg RPE selector card ("HOW HARD DID THAT FEEL?").
///
/// Shared by [RestScreen] (shown between sets) and the cool-down view
/// (shown for the session's final set, which has no rest period after it
/// to show this selector during otherwise -- see
/// ActiveSessionController.completeCurrentSet's isLastSet branch).
class RpeSelectorCard extends StatelessWidget {
  final int targetRpe;
  final int selectedRpe;
  final ValueChanged<int> onSelect;

  const RpeSelectorCard({
    super.key,
    required this.targetRpe,
    required this.selectedRpe,
    required this.onSelect,
  });

  static String _getRpeHint(int rpe) {
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

  static String _getAutoregulationFeedback({
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

  static Color _getFeedbackColor({
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
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PixelCard(
      backgroundColor: colors.surfaceDark,
      borderColor: colors.borderBright,
      bevelColor: colors.borderMuted,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW HARD DID THAT FEEL?',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: colors.amberAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'BORG RPE SCALE',
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
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 2.0,
                ),
                decoration: ShapeDecoration(
                  color: colors.backgroundVoid,
                  shape: SteppedPixelBorder(
                    side: const BorderSide(
                      color: Color(0xFF2EE6D6),
                      width: 1.0,
                    ),
                    stepSize: context.pixelMetrics.cornerStepSize,
                  ),
                ),
                child: Text(
                  'TARGET: $targetRpe RPE',
                  style: const TextStyle(
                    fontFamily: 'Silkscreen',
                    fontFamilyFallback: ['monospace'],
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
                  onTap: () => onSelect(score),
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
                  onTap: () => onSelect(score),
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
              border: Border.all(color: colors.borderMuted, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'RPE $selectedRpe: ',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                        color: colors.amberAccent,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _getRpeHint(selectedRpe),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontFamilyFallback: const ['sans-serif'],
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
                    fontFamily: 'Silkscreen',
                    fontFamilyFallback: const ['monospace'],
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
    final metrics = context.pixelMetrics;
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
          decoration: ShapeDecoration(
            color: bgColor,
            shape: SteppedPixelBorder(
              side: BorderSide(
                color: borderColor,
                width: isTarget || isSelected ? 1.5 : 1.0,
              ),
              stepSize: metrics.cornerStepSize,
            ),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontFamily: 'Silkscreen',
                fontFamilyFallback: const ['monospace'],
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
