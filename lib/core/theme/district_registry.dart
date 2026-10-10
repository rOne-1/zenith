import 'package:flutter_refined_kit/flutter_refined_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/districts/neon_alleys/neon_alleys_theme.dart';
import '../../features/districts/railside_outskirts/railside_outskirts_theme.dart';
import '../storage/preferences_provider.dart';
import 'zenith_district_colors.dart';

/// Ordered catalogue of all available district themes in Zenith.
///
/// Falls back safely to District 01 ("Railside Outskirts") if an unknown ID is requested.
final zenithThemeRegistry = ThemeRegistry<ZenithDistrictColors>([
  district01RailsideOutskirts,
  district02NeonAlleys,
]);

/// Riverpod provider managing active district theme selection and persistence.
final themeControllerProvider =
    ChangeNotifierProvider<PersistedThemeController<ZenithDistrictColors>>((
      ref,
    ) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return PersistedThemeController<ZenithDistrictColors>(
        registry: zenithThemeRegistry,
        prefs: prefs,
        prefsKey: 'zenith_active_district_id',
      );
    });
