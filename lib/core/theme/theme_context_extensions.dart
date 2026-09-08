import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';

import 'zenith_district_colors.dart';
import 'zenith_pixel_metrics.dart';

/// Semantic token and metric accessors on [BuildContext].
///
/// Ensures zero `isDark ? a : b` branching in widgets and screens.
extension ZenithThemeX on BuildContext {
  /// Active Japanese city district semantic color tokens.
  ZenithDistrictColors get colors =>
      themeExtensionOrDefault<ZenithDistrictColors>(
        this,
        ZenithDistrictColors.fallback,
      );

  /// Active pixel geometry metrics for retro frames, borders, and buttons.
  ZenithPixelMetrics get pixelMetrics =>
      themeExtensionOrDefault<ZenithPixelMetrics>(
        this,
        const ZenithPixelMetrics(),
      );
}
