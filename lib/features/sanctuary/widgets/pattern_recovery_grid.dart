import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../grimoire/widgets/metro_transit_map.dart';
import '../services/recovery_status_service.dart';

/// Section widget rendering the 48-hour recovery cooldown clocks across all
/// 5 ACE IFT movement patterns.
class PatternRecoveryGrid extends ConsumerWidget {
  const PatternRecoveryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final recoveryAsync = ref.watch(recoveryStatusProvider);

    return PixelCard(
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
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.radar_outlined,
                      color: colors.amberAccent,
                      size: 18.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECOVERY STATUS',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 12.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: colors.amberAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'NEUROMUSCULAR RECOVERY RADAR',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
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
                  '48H PROTOCOL',
                  style: TextStyle(
                    fontFamily: 'Silkscreen',
                    fontFamilyFallback: const ['monospace'],
                    fontSize: 8.0,
                    fontWeight: FontWeight.w700,
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            'High-threshold sets (RPE ≥ 8) trigger a 48-hour neuromuscular cooldown lock per ACE IFT movement pattern.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontFamilyFallback: const ['sans-serif'],
              fontSize: 10.0,
              height: 1.3,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 16.0),

          recoveryAsync.when(
            data: (statuses) {
              return Column(
                children: MovementPattern.values.map((pattern) {
                  final status = statuses[pattern] ??
                      PatternRecoveryStatus(
                        pattern: pattern,
                        isFresh: true,
                        remainingLockDuration: Duration.zero,
                      );
                  final lineTheme = MetroLineTheme.forPattern(pattern);
                  return _PatternRecoveryRow(
                    pattern: pattern,
                    status: status,
                    lineTheme: lineTheme,
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: PixelLoadingIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'RADAR TELEMETRY OFFLINE: $err',
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 11.0,
                  color: colors.signalRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternRecoveryRow extends StatelessWidget {
  final MovementPattern pattern;
  final PatternRecoveryStatus status;
  final MetroLineTheme lineTheme;

  const _PatternRecoveryRow({
    required this.pattern,
    required this.status,
    required this.lineTheme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isFresh = status.isFresh;
    final progress = status.recoveryProgress;

    final Color statusColor = isFresh
        ? const Color(0xFF2EE6D6)
        : (status.remainingLockDuration.inHours > 24
            ? colors.signalRed
            : colors.amberAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: colors.backgroundVoid,
        border: Border.all(
          color: isFresh ? colors.borderMuted : statusColor.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Line theme badge + Name
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 22.0,
                      height: 22.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: lineTheme.color.withValues(alpha: 0.2),
                        border: Border.all(
                          color: lineTheme.color,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        lineTheme.codePrefix,
                        style: TextStyle(
                          fontFamily: 'Silkscreen',
                          fontFamilyFallback: const ['monospace'],
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                          color: lineTheme.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        lineTheme.lineNameEn,
                        style: TextStyle(
                          fontFamily: 'Silkscreen',
                          fontFamilyFallback: const ['monospace'],
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),

              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: statusColor,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isFresh) ...[
                      PixelPulseDot(
                        color: statusColor,
                        size: 6.0,
                        // Far from unlocking reads as more urgent: a
                        // faster, harder blink than a lock that's close to
                        // clearing.
                        hardCut: status.remainingLockDuration.inHours > 24,
                        period: status.remainingLockDuration.inHours > 24
                            ? const Duration(milliseconds: 1400)
                            : const Duration(milliseconds: 2200),
                        minOpacity:
                            status.remainingLockDuration.inHours > 24
                                ? 0.15
                                : 0.35,
                      ),
                      const SizedBox(width: 5.0),
                    ],
                    Text(
                      status.statusChipLabel,
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: statusColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Recovery progress indicator
          Row(
            children: [
              Expanded(
                child: PixelCountdownBar(
                  progress: progress,
                  totalBlocks: 12,
                  height: 10.0,
                  borderWidth: 1.0,
                  cornerStepSize: 1.5,
                  blockSpacing: 1.5,
                  padding: const EdgeInsets.all(2.0),
                  activeColor: statusColor,
                  inactiveColor: colors.surfaceDark,
                  borderColor: colors.borderMuted,
                  backgroundColor: colors.backgroundVoid,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 9.0,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
