import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../app_shell.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../engine/engine.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../widgets/metro_transit_map.dart';
import '../widgets/station_inspector_sheet.dart';

/// The Grimoire: Visual Metro Transit Map of Movement Progressions.
class GrimoireScreen extends ConsumerStatefulWidget {
  const GrimoireScreen({super.key});

  @override
  ConsumerState<GrimoireScreen> createState() => _GrimoireScreenState();
}

class _GrimoireScreenState extends ConsumerState<GrimoireScreen> {
  MovementPattern? _selectedPattern;

  void _handleSelectStation(Exercise exercise, bool isIntermediateUser) {
    StationInspectorSheet.show(
      context,
      exercise: exercise,
      isIntermediateUser: isIntermediateUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Defaults to locked (false) while the status is still resolving or on
    // error -- the same safe default the old hardcoded value always was.
    final isIntermediateUser =
        ref.watch(isIntermediateStatusProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: RailsideAtmosphereBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Row(
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
                        style: TextStyle(
                          fontFamily: 'Silkscreen',
                          fontFamilyFallback: const ['monospace'],
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
                          Text(
                            'THE ATLAS',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 16.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: colors.amberAccent,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'METRO TRANSIT MAP OF MOVEMENT PROGRESSIONS',
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
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

              // Filter Pills Strip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceDark,
                  border: Border(
                    bottom: BorderSide(color: colors.borderBright, width: 1.0),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterPill(
                        label: 'ALL LINES',
                        isSelected: _selectedPattern == null,
                        activeColor: colors.amberAccent,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedPattern = null);
                        },
                      ),
                      const SizedBox(width: 8.0),
                      _FilterPill(
                        label: 'PUSH',
                        isSelected: _selectedPattern == MovementPattern.pushing,
                        activeColor: const Color(0xFFFFAE34),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _selectedPattern = MovementPattern.pushing,
                          );
                        },
                      ),
                      const SizedBox(width: 8.0),
                      _FilterPill(
                        label: 'PULL',
                        isSelected: _selectedPattern == MovementPattern.pulling,
                        activeColor: const Color(0xFF2EE6D6),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _selectedPattern = MovementPattern.pulling,
                          );
                        },
                      ),
                      const SizedBox(width: 8.0),
                      _FilterPill(
                        label: 'BEND & LIFT',
                        isSelected:
                            _selectedPattern == MovementPattern.bendAndLift,
                        activeColor: const Color(0xFFFF493A),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () =>
                                _selectedPattern = MovementPattern.bendAndLift,
                          );
                        },
                      ),
                      const SizedBox(width: 8.0),
                      _FilterPill(
                        label: 'LEGS',
                        isSelected:
                            _selectedPattern == MovementPattern.singleLeg,
                        activeColor: const Color(0xFF4B8E62),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _selectedPattern = MovementPattern.singleLeg,
                          );
                        },
                      ),
                      const SizedBox(width: 8.0),
                      _FilterPill(
                        label: 'ROTATION',
                        isSelected:
                            _selectedPattern == MovementPattern.rotation,
                        activeColor: const Color(0xFFD154EC),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _selectedPattern = MovementPattern.rotation,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Metro Diagram Track
              Expanded(
                child: MetroTransitMap(
                  activePatternFilter: _selectedPattern,
                  onStationSelected: (exercise) =>
                      _handleSelectStation(exercise, isIntermediateUser),
                  isIntermediateUser: isIntermediateUser,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : colors.backgroundVoid,
          border: Border.all(
            color: isSelected ? activeColor : colors.borderMuted,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Silkscreen',
            fontFamilyFallback: const ['monospace'],
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: isSelected ? colors.surfaceDark : colors.textMuted,
          ),
        ),
      ),
    );
  }
}
