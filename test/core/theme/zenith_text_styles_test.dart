import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/theme.dart';

void main() {
  group('PKG-9.1: Silkscreen Typography Helper Suite (zenithPixelDisplay)', () {
    test('zenithPixelDisplay returns test-safe Silkscreen style with monospace fallback', () {
      final style = zenithPixelDisplay(
        fontSize: 14.0,
        color: const Color(0xFFFFAE34),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        height: 1.2,
      );

      expect(style.fontFamily, equals('Silkscreen'));
      expect(style.fontFamilyFallback, contains('monospace'));
      expect(style.fontSize, equals(14.0));
      expect(style.color, equals(const Color(0xFFFFAE34)));
      expect(style.fontWeight, equals(FontWeight.w900));
      expect(style.letterSpacing, equals(1.5));
      expect(style.height, equals(1.2));
    });

    test('default parameters for zenithPixelDisplay match brand specification', () {
      final style = zenithPixelDisplay(fontSize: 12.0);

      expect(style.fontFamily, equals('Silkscreen'));
      expect(style.fontFamilyFallback, contains('monospace'));
      expect(style.fontSize, equals(12.0));
      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.letterSpacing, equals(1.0));
      expect(style.height, isNull);
      expect(style.color, isNull);
    });

    test('scale presets map to standard display increments', () {
      expect(kPixelDisplaySmSize, equals(9.0));
      expect(kPixelDisplayMdSize, equals(11.0));
      expect(kPixelDisplayLgSize, equals(13.0));
      expect(kPixelDisplayXlSize, equals(16.0));

      const testColor = Color(0xFF00FFCC);

      final sm = pixelDisplaySm(color: testColor);
      expect(sm.fontSize, equals(9.0));
      expect(sm.color, equals(testColor));
      expect(sm.fontFamily, equals('Silkscreen'));

      final md = pixelDisplayMd(color: testColor);
      expect(md.fontSize, equals(11.0));
      expect(md.color, equals(testColor));
      expect(md.fontFamily, equals('Silkscreen'));

      final lg = pixelDisplayLg(color: testColor);
      expect(lg.fontSize, equals(13.0));
      expect(lg.color, equals(testColor));
      expect(lg.fontFamily, equals('Silkscreen'));

      final xl = pixelDisplayXl(color: testColor);
      expect(xl.fontSize, equals(16.0));
      expect(xl.color, equals(testColor));
      expect(xl.fontFamily, equals('Silkscreen'));
    });

    test('zenithBodyMono returns test-safe IBM Plex Mono style', () {
      final style = zenithBodyMono(
        fontSize: 13.0,
        color: const Color(0xFFFFFFFF),
        height: 1.5,
        fontWeight: FontWeight.w500,
      );

      expect(style.fontFamily, equals('IBM Plex Mono'));
      expect(style.fontFamilyFallback, contains('monospace'));
      expect(style.fontSize, equals(13.0));
      expect(style.color, equals(const Color(0xFFFFFFFF)));
      expect(style.height, equals(1.5));
      expect(style.fontWeight, equals(FontWeight.w500));
    });
  });
}
