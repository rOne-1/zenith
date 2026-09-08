import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../engine/engine.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';

/// The Sanctuary: an atmospheric recovery and reflection screen for rest days,
/// physiological adaptation tracking, and district telemetry.
class SanctuaryScreen extends ConsumerWidget {
  const SanctuaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeController = ref.watch(themeControllerProvider);
    final district = themeController.current;
    final sessionRepo = ref.watch(sessionRepositoryProvider);

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: RailsideAtmosphereBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'REST & ADAPTATION CHAMBER',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11.0,
                          letterSpacing: 1.5,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
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
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: colors.amberAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // Recovery Guidance Banner
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
                          Icons.nightlight_round,
                          color: const Color(0xFF2EE6D6),
                          size: 18.0,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'NEUROMUSCULAR SUPERCOMPENSATION',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: const Color(0xFF2EE6D6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      'Musculoskeletal adaptation and protein synthesis occur during sleep and rest. Restorative walking, hydration, and nutrient timing accelerate systemic repair.',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12.0,
                        height: 1.5,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18.0),

              // Telemetry Section
              FutureBuilder<int>(
                future: sessionRepo.getCompletedSessionCount(),
                builder: (context, snapshot) {
                  final completedCount = snapshot.data ?? 0;
                  return Row(
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
                                'TOTAL EXPEDITIONS',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10.0,
                                  color: colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                '$completedCount',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 24.0,
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
                                'CURRENT SECTOR',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10.0,
                                  color: colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                district.displayName.split(' ').first.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF2EE6D6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18.0),

              // District Environment Terminal
              PixelCard(
                backgroundColor: colors.surfaceDark,
                borderColor: colors.borderMuted,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISTRICT ATMOSPHERE // 地区環境',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      district.displayName,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w900,
                        color: colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Rainfall frequency: 72% · Ambient Temp: 14°C · Line Voltage: 1500V DC',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10.0,
                        color: colors.textMuted,
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
