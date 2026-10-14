import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../app_shell.dart';
import '../../../core/audio/audio.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_card.dart';
import '../../../core/widgets/pixel_toast.dart';
import '../../../core/widgets/stepped_pixel_border.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/data_archive_section.dart';
import '../widgets/gear_tile.dart';
import '../widgets/illustration_credits_section.dart';

/// The 6 canonical equipment types rendered in the 3x2 Armory gear grid.
const List<Equipment> kArmoryEquipmentGrid = [
  Equipment.bodyweight,
  Equipment.pullUpBar,
  Equipment.bands,
  Equipment.benchOrChair,
  Equipment.suspension,
  Equipment.towel,
];

/// The Armory: Equipment inventory and physiological configuration screen.
class ArmoryScreen extends ConsumerWidget {
  const ArmoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;
    final userProfile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);
    final sensorySettings = ref.watch(sensorySettingsProvider);
    final sensoryNotifier = ref.read(sensorySettingsProvider.notifier);

    final equippedCount = userProfile.availableEquipment
        .where((e) => kArmoryEquipmentGrid.contains(e))
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PixelToastHost(
        child: SafeArea(
          child: Column(
            children: [
              // Top App Bar / Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PixelButton(
                      variant: PixelButtonVariant.secondary,
                      padding: const EdgeInsets.all(8.0),
                      semanticLabel: 'Back to Outpost',
                      onPressed: () {
                        ref
                                .read(activeNavigationTabIndexProvider.notifier)
                                .state =
                            0;
                      },
                      child: Text(
                        '←',
                        style: zenithPixelDisplay(
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'THE DEPOT',
                                  style: zenithPixelDisplay(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
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
                                    color: colors.borderBright,
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  'SAVED ✓',
                                  style: zenithPixelDisplay(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.bold,
                                    color: colors.amberGlow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'SELECT AVAILABLE GEAR TO UNLOCK EXERCISE ROUTES',
                            style: zenithPixelDisplay(
                              fontSize: 9.0,
                              letterSpacing: 0.8,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1.0, thickness: 1.0),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section Header: Equipment Grid
                      Row(
                        children: [
                          Container(
                            width: 6.0,
                            height: 6.0,
                            color: colors.amberAccent,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'EQUIPMENT INVENTORY',
                            style: zenithPixelDisplay(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      // 3x2 Grid
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: kArmoryEquipmentGrid.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12.0,
                              mainAxisSpacing: 12.0,
                              // A fixed extent (rather than an aspect ratio)
                              // guarantees enough height for GearTile's
                              // content regardless of how narrow the
                              // available width is.
                              mainAxisExtent: 140.0,
                            ),
                        itemBuilder: (context, index) {
                          final equipment = kArmoryEquipmentGrid[index];
                          final isEquipped = userProfile.availableEquipment
                              .contains(equipment);

                          return GearTile(
                            equipment: equipment,
                            isEquipped: isEquipped,
                            onToggle: () => notifier.toggleEquipment(equipment),
                          );
                        },
                      ),

                      const SizedBox(height: 24.0),

                      // Section Header: Physiology Accommodations
                      Row(
                        children: [
                          Container(
                            width: 6.0,
                            height: 6.0,
                            color: colors.amberAccent,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'PHYSIOLOGY ACCOMMODATIONS',
                            style: zenithPixelDisplay(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      // Joint Protection Toggle Tile
                      _PhysiologyToggleTile(
                        title: 'JOINT PROTECTION',
                        subtitle: 'Skips jumping and other hard-impact moves',
                        isActive: userProfile.hasJointPain,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.toggleJointProtection();
                        },
                      ),

                      const SizedBox(height: 12.0),

                      // Cycle Autoregulation Toggle Tile
                      _PhysiologyToggleTile(
                        title: 'CYCLE AUTOREGULATION',
                        subtitle: 'Adds extra rest days early in your cycle',
                        isActive: userProfile.hasCycleAutoregulation,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.toggleCycleAutoregulation();
                        },
                      ),

                      ZenithSpacing.gapVerticalXl,

                      // Section Header: Audio & Sensory
                      Row(
                        children: [
                          Container(
                            width: 6.0,
                            height: 6.0,
                            color: colors.amberAccent,
                          ),
                          ZenithSpacing.gapHorizontalSm,
                          Text(
                            'AUDIO & SENSORY',
                            style: zenithPixelDisplay(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      ZenithSpacing.gapVerticalMd,

                      // Sound Effects Toggle Tile
                      _SensoryToggleTile(
                        title: 'SOUND EFFECTS',
                        subtitle: 'Countdown ticks, chimes, and victory fanfare',
                        isActive: sensorySettings.soundEffectsEnabled,
                        onTap: () {
                          if (sensorySettings.hapticFeedbackEnabled) {
                            HapticFeedback.selectionClick();
                          }
                          sensoryNotifier.toggleSoundEffects();
                        },
                      ),

                      ZenithSpacing.gapVerticalMd,

                      // Haptic Feedback Toggle Tile
                      _SensoryToggleTile(
                        title: 'HAPTIC FEEDBACK',
                        subtitle: 'Tactile vibration pulses during workout cues',
                        isActive: sensorySettings.hapticFeedbackEnabled,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          sensoryNotifier.toggleHapticFeedback();
                        },
                      ),

                      ZenithSpacing.gapVerticalXl,

                      const DataArchiveSection(),

                      const SizedBox(height: 24.0),

                      // Section Header: Illustration Credits
                      Row(
                        children: [
                          Container(
                            width: 6.0,
                            height: 6.0,
                            color: colors.amberAccent,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'ATTRIBUTION',
                            style: zenithPixelDisplay(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      const IllustrationCreditsSection(),
                    ],
                  ),
                ),
              ),

              // Footer Telemetry Ribbon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceDark,
                  border: Border(
                    top: BorderSide(
                      color: colors.borderBright,
                      width: metrics.borderWidth,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: colors.amberAccent,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        '$equippedCount of 6 gear routes equipped · '
                        'joint protection ${userProfile.hasJointPain ? 'ON' : 'OFF'}'
                        '${userProfile.hasCycleAutoregulation ? ' · cycle autoreg ON' : ''}',
                        style: zenithPixelDisplay(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: colors.amberGlow,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

/// Stepped retro toggle switch card for physiological settings.
class _PhysiologyToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _PhysiologyToggleTile({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ZenithSpacing.edgeInsetsMd,
        decoration: ShapeDecoration(
          color: isActive ? colors.surfaceElevated : colors.surfaceDark,
          shape: SteppedPixelBorder(
            side: BorderSide(
              color: isActive ? colors.amberAccent : colors.borderMuted,
              width: metrics.borderWidth,
            ),
            stepSize: metrics.cornerStepSize,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: zenithPixelDisplay(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: isActive ? colors.textPrimary : colors.textMuted,
                    ),
                  ),
                  ZenithSpacing.gapVerticalXxs,
                  Text(
                    subtitle,
                    style: zenithBodyMono(
                      fontSize: 11.0,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            ZenithSpacing.gapHorizontalMd,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ZenithSpacing.sm + ZenithSpacing.xxs,
                vertical: ZenithSpacing.xs + ZenithSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: isActive ? colors.amberAccent : colors.backgroundVoid,
                border: Border.all(
                  color: isActive ? colors.amberGlow : colors.borderMuted,
                  width: 1.0,
                ),
              ),
              child: Text(
                isActive ? 'ON  ●' : 'OFF ○',
                style: zenithPixelDisplay(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w900,
                  color: isActive ? colors.surfaceDark : colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Retro neo-pixel toggle switch card for audio and haptic sensory settings.
class _SensoryToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _SensoryToggleTile({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;

    return PixelCard(
      onTap: onTap,
      padding: ZenithSpacing.edgeInsetsMd,
      backgroundColor: isActive ? colors.surfaceElevated : colors.surfaceDark,
      borderColor: isActive ? colors.amberAccent : colors.borderMuted,
      bevelColor: isActive ? colors.borderBright : colors.surfaceDark,
      borderWidth: metrics.borderWidth,
      cornerStepSize: metrics.cornerStepSize,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: zenithPixelDisplay(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: isActive ? colors.textPrimary : colors.textMuted,
                  ),
                ),
                ZenithSpacing.gapVerticalXxs,
                Text(
                  subtitle,
                  style: zenithBodyMono(
                    fontSize: 11.0,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ZenithSpacing.gapHorizontalMd,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ZenithSpacing.sm + ZenithSpacing.xxs,
              vertical: ZenithSpacing.xs + ZenithSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: isActive ? colors.amberAccent : colors.backgroundVoid,
              border: Border.all(
                color: isActive ? colors.amberGlow : colors.borderMuted,
                width: 1.0,
              ),
            ),
            child: Text(
              isActive ? 'ON  ●' : 'OFF ○',
              style: zenithPixelDisplay(
                fontSize: 10.0,
                fontWeight: FontWeight.w900,
                color: isActive ? colors.surfaceDark : colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
