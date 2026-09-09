import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../widgets/adaptation_ledger_card.dart';
import '../widgets/macrocycle_progress_card.dart';
import '../widgets/pattern_recovery_grid.dart';

/// The Sanctuary: Screen 1f atmospheric recovery and physiological reflection chamber.
///
/// Surfaces 48-hour movement pattern cooldown clocks, 5-week block periodization
/// macrocycles (accumulation, peak overload, deload), and the Kenneth Miller
/// 5-variable adaptation history ledger.
class SanctuaryScreen extends ConsumerWidget {
  const SanctuaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeController = ref.watch(themeControllerProvider);
    final district = themeController.current;

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: RailsideAtmosphereBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            children: [
              // Chamber Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SANCTUARY // 聖域',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 22.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: colors.amberAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'REST & PHYSIOLOGICAL ADAPTATION CHAMBER',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
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
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceDark,
                      border: Border.all(
                        color: colors.amberAccent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'STATUS: NOMINAL',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: colors.amberAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18.0),

              // Atmospheric Sanctuary Supercompensation Banner
              PixelCard(
                backgroundColor: colors.surfaceDark,
                borderColor: colors.borderBright,
                bevelColor: colors.borderMuted,
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          color: const Color(0xFF2EE6D6),
                          size: 16.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'NEUROMUSCULAR SUPERCOMPENSATION // 超回復',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: const Color(0xFF2EE6D6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Musculoskeletal remodeling, collagen repair, and CNS resensitization occur during downtime. Honor cooldown timers and periodization deloads to consolidate progress.',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11.0,
                        height: 1.4,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // 1. Neuromuscular Recovery Radar (48h Lock HUD)
              const PatternRecoveryGrid(),
              const SizedBox(height: 16.0),

              // 2. Deload Macrocycle Tracker & Periodization Block
              const MacrocycleProgressCard(),
              const SizedBox(height: 16.0),

              // 3. Kenneth Miller Adaptation History Ledger
              const AdaptationLedgerCard(),
              const SizedBox(height: 16.0),

              // District Ambient Telemetry
              PixelCard(
                backgroundColor: colors.surfaceDark,
                borderColor: colors.borderMuted,
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISTRICT ATMOSPHERE // 地区環境テレメトリー',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      district.displayName,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 13.0,
                        fontWeight: FontWeight.w900,
                        color: colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Rainfall frequency: 72% · Ambient Temp: 14°C · Line Voltage: 1500V DC · Platform Hum: 48Hz',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9.5,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
