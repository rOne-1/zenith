import 'package:flutter/widgets.dart';

/// Centralized spacing tokens for the Zenith Design System.
///
/// Defines the canonical modular spacing scale used across all
/// views, cards, sheets, and components:
/// - [xxs]: 2.0 dp (micro hairline gutter, pixel offsets)
/// - [xs]: 4.0 dp (tight internal chip padding, label gaps)
/// - [sm]: 8.0 dp (standard component margin, horizontal icon gaps)
/// - [md]: 12.0 dp (medium element spacing, sheet row gutters)
/// - [lg]: 16.0 dp (standard screen gutter, card interior padding)
/// - [xl]: 24.0 dp (section divider spacing, card stack gaps)
/// - [xxl]: 32.0 dp (hero layout gutters, empty-state margins)
abstract final class ZenithSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // Convenient EdgeInsets presets
  static const EdgeInsets edgeInsetsZero = EdgeInsets.zero;
  static const EdgeInsets edgeInsetsXxs = EdgeInsets.all(xxs);
  static const EdgeInsets edgeInsetsXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsXl = EdgeInsets.all(xl);
  static const EdgeInsets edgeInsetsXxl = EdgeInsets.all(xxl);

  // Convenient symmetric presets
  static const EdgeInsets edgeInsetsHSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets edgeInsetsHMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets edgeInsetsHLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets edgeInsetsHXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets edgeInsetsVSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets edgeInsetsVMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets edgeInsetsVLg = EdgeInsets.symmetric(vertical: lg);

  // Convenient SizedBox gap presets
  static const SizedBox gapXxs = SizedBox(width: xxs, height: xxs);
  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);

  // Vertical SizedBox gaps
  static const SizedBox gapVerticalXxs = SizedBox(height: xxs);
  static const SizedBox gapVerticalXs = SizedBox(height: xs);
  static const SizedBox gapVerticalSm = SizedBox(height: sm);
  static const SizedBox gapVerticalMd = SizedBox(height: md);
  static const SizedBox gapVerticalLg = SizedBox(height: lg);
  static const SizedBox gapVerticalXl = SizedBox(height: xl);
  static const SizedBox gapVerticalXxl = SizedBox(height: xxl);

  // Horizontal SizedBox gaps
  static const SizedBox gapHorizontalXxs = SizedBox(width: xxs);
  static const SizedBox gapHorizontalXs = SizedBox(width: xs);
  static const SizedBox gapHorizontalSm = SizedBox(width: sm);
  static const SizedBox gapHorizontalMd = SizedBox(width: md);
  static const SizedBox gapHorizontalLg = SizedBox(width: lg);
  static const SizedBox gapHorizontalXl = SizedBox(width: xl);
  static const SizedBox gapHorizontalXxl = SizedBox(width: xxl);
}
