import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A single Kenneth Miller 5-variable segmented gauge row (e.g.
/// `[LOAD] █ █ █ ░ ░ 3/5`).
///
/// Shared between the Grimoire Station Inspector and the Working Set
/// screen so the same underlying [MillerVariables] data always renders
/// identically wherever it's shown (EP-3) — previously the Inspector had
/// its own private `_SegmentedGaugeRow` while the Working Set screen
/// re-derived a plainer text-badge treatment for the same numbers.
class MillerVariableGauge extends StatelessWidget {
  final String label;
  final int score;

  /// Top of this gauge's scale — 5 for the standard Load/Position/ROM/
  /// Elevation variables, 2 for Tempo (standard vs. advanced slow tempo).
  final int maxScore;

  /// Overrides the "score/max" trailing text (e.g. Tempo shows "6s (ADV)"
  /// instead of "2/2") while the filled-block ratio still reflects
  /// [score]/[maxScore].
  final String? displayValueOverride;
  final Color? activeColor;
  final Color? inactiveColor;

  const MillerVariableGauge({
    super.key,
    required this.label,
    required this.score,
    this.maxScore = 5,
    this.displayValueOverride,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveActive = activeColor ?? colors.amberAccent;
    final effectiveInactive = inactiveColor ?? colors.backgroundVoid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          Row(
            children: [
              for (int i = 1; i <= maxScore; i++)
                Container(
                  width: 14.0,
                  height: 8.0,
                  margin: const EdgeInsets.only(left: 3.0),
                  decoration: BoxDecoration(
                    color: i <= score ? effectiveActive : effectiveInactive,
                    border: Border.all(
                      color: effectiveActive.withValues(alpha: 0.7),
                      width: 1.0,
                    ),
                  ),
                ),
              const SizedBox(width: 6.0),
              Text(
                displayValueOverride ?? '$score/$maxScore',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: effectiveActive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
