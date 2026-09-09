import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/stepped_pixel_border.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/gear_tile.dart';

/// The 6 canonical equipment types rendered in the 3x2 Armory gear grid.
const List<Equipment> kArmoryEquipmentGrid = [
  Equipment.bodyweight,
  Equipment.pullUpBar,
  Equipment.bands,
  Equipment.benchOrChair,
  Equipment.suspension,
  Equipment.towel,
];

/// The Armory (装備庫): Equipment inventory and physiological configuration screen.
class ArmoryScreen extends ConsumerWidget {
  const ArmoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final metrics = context.pixelMetrics;
    final userProfile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    final equippedCount = userProfile.availableEquipment
        .where((e) => kArmoryEquipmentGrid.contains(e))
        .length;

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: RailsideAtmosphereBackdrop(
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20.0),
                      color: colors.amberAccent,
                      tooltip: 'Back to Dispatch',
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'THE ARMORY // 装備庫',
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
                                  style: TextStyle(
                                    fontFamily: 'Courier',
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
                            style: TextStyle(
                              fontFamily: 'Courier',
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
                            style: TextStyle(
                              fontFamily: 'Courier',
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
                            style: TextStyle(
                              fontFamily: 'Courier',
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
                        subtitle: 'Excludes high-impact plyometrics',
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
                        subtitle:
                            'Early-follicular rest padding & endocrine cues',
                        isActive: userProfile.hasCycleAutoregulation,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.toggleCycleAutoregulation();
                        },
                      ),
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
                        style: TextStyle(
                          fontFamily: 'Courier',
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
        padding: const EdgeInsets.all(12.0),
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
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: isActive ? colors.textPrimary : colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.0, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
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
                style: TextStyle(
                  fontFamily: 'Courier',
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
