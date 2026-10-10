import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/theme.dart';

void main() {
  group('PKG-9.3: Centralized Spacing Token Scale (ZenithSpacing)', () {
    test('canonical scale values match 4dp/8dp modular specifications', () {
      expect(ZenithSpacing.xxs, equals(2.0));
      expect(ZenithSpacing.xs, equals(4.0));
      expect(ZenithSpacing.sm, equals(8.0));
      expect(ZenithSpacing.md, equals(12.0));
      expect(ZenithSpacing.lg, equals(16.0));
      expect(ZenithSpacing.xl, equals(24.0));
      expect(ZenithSpacing.xxl, equals(32.0));
    });

    test('EdgeInsets presets match scale values', () {
      expect(ZenithSpacing.edgeInsetsZero, equals(EdgeInsets.zero));
      expect(ZenithSpacing.edgeInsetsXxs, equals(const EdgeInsets.all(2.0)));
      expect(ZenithSpacing.edgeInsetsXs, equals(const EdgeInsets.all(4.0)));
      expect(ZenithSpacing.edgeInsetsSm, equals(const EdgeInsets.all(8.0)));
      expect(ZenithSpacing.edgeInsetsMd, equals(const EdgeInsets.all(12.0)));
      expect(ZenithSpacing.edgeInsetsLg, equals(const EdgeInsets.all(16.0)));
      expect(ZenithSpacing.edgeInsetsXl, equals(const EdgeInsets.all(24.0)));
      expect(ZenithSpacing.edgeInsetsXxl, equals(const EdgeInsets.all(32.0)));

      expect(
        ZenithSpacing.edgeInsetsHSm,
        equals(const EdgeInsets.symmetric(horizontal: 8.0)),
      );
      expect(
        ZenithSpacing.edgeInsetsHMd,
        equals(const EdgeInsets.symmetric(horizontal: 12.0)),
      );
      expect(
        ZenithSpacing.edgeInsetsHLg,
        equals(const EdgeInsets.symmetric(horizontal: 16.0)),
      );
      expect(
        ZenithSpacing.edgeInsetsHXl,
        equals(const EdgeInsets.symmetric(horizontal: 24.0)),
      );

      expect(
        ZenithSpacing.edgeInsetsVSm,
        equals(const EdgeInsets.symmetric(vertical: 8.0)),
      );
      expect(
        ZenithSpacing.edgeInsetsVMd,
        equals(const EdgeInsets.symmetric(vertical: 12.0)),
      );
      expect(
        ZenithSpacing.edgeInsetsVLg,
        equals(const EdgeInsets.symmetric(vertical: 16.0)),
      );
    });

    test('SizedBox gap presets match dimensions', () {
      expect(ZenithSpacing.gapSm.width, equals(8.0));
      expect(ZenithSpacing.gapSm.height, equals(8.0));
      expect(ZenithSpacing.gapVerticalMd.height, equals(12.0));
      expect(ZenithSpacing.gapVerticalMd.width, isNull);
      expect(ZenithSpacing.gapHorizontalLg.width, equals(16.0));
      expect(ZenithSpacing.gapHorizontalLg.height, isNull);
    });
  });
}
