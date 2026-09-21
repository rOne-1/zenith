import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/districts/neon_alleys/neon_alleys_atmosphere_backdrop.dart';
import '../../features/districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../theme/district_registry.dart';

/// Renders whichever district's atmospheric backdrop is currently active,
/// so every screen using this (instead of a hardcoded concrete backdrop
/// widget) reacts live to the theme switcher.
class DistrictAtmosphereBackdrop extends ConsumerWidget {
  final Widget? child;

  const DistrictAtmosphereBackdrop({super.key, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeThemeId = ref.watch(
      themeControllerProvider.select((controller) => controller.current.id),
    );

    return switch (activeThemeId) {
      'neon_alleys' => NeonAlleysAtmosphereBackdrop(child: child),
      _ => RailsideAtmosphereBackdrop(child: child),
    };
  }
}
