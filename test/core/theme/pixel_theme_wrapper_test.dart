import 'package:flutter/material.dart';
import 'package:flutter_refined_kit/flutter_refined_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zenith/core/theme/theme.dart';

FontBuilder _testFontBuilder(String family) {
  return ({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) => TextStyle(
    fontFamily: family,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
    height: height,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ZenithPixelMetrics', () {
    test('default constructor sets expected baseline metrics', () {
      const metrics = ZenithPixelMetrics();

      expect(metrics.pixelScale, 2.0);
      expect(metrics.borderWidth, 2.0);
      expect(metrics.buttonDropOffset, 3.0);
      expect(metrics.cornerStepSize, 4.0);
      expect(metrics.bevelDepth, 4.0);
    });

    test('copyWith updates specified fields only', () {
      const metrics = ZenithPixelMetrics();
      final updated = metrics.copyWith(pixelScale: 3.0, buttonDropOffset: 5.0);

      expect(updated.pixelScale, 3.0);
      expect(updated.borderWidth, 2.0);
      expect(updated.buttonDropOffset, 5.0);
      expect(updated.cornerStepSize, 4.0);
      expect(updated.bevelDepth, 4.0);
    });

    test('lerp accurately interpolates between instances', () {
      const a = ZenithPixelMetrics(
        pixelScale: 2.0,
        borderWidth: 2.0,
        buttonDropOffset: 2.0,
        cornerStepSize: 4.0,
        bevelDepth: 4.0,
      );
      const b = ZenithPixelMetrics(
        pixelScale: 4.0,
        borderWidth: 4.0,
        buttonDropOffset: 6.0,
        cornerStepSize: 8.0,
        bevelDepth: 8.0,
      );

      final result = a.lerp(b, 0.5) as ZenithPixelMetrics;

      expect(result.pixelScale, 3.0);
      expect(result.borderWidth, 3.0);
      expect(result.buttonDropOffset, 4.0);
      expect(result.cornerStepSize, 6.0);
      expect(result.bevelDepth, 6.0);
    });

    test('lerp with null or non-ZenithPixelMetrics returns self', () {
      const metrics = ZenithPixelMetrics();
      expect(metrics.lerp(null, 0.5), metrics);
    });
  });

  group('ZenithDistrictColors', () {
    test('fallback constants match expected district defaults', () {
      const fallback = ZenithDistrictColors.fallback;

      expect(fallback.backgroundVoid, const Color(0xFF070E10));
      expect(fallback.surfaceDark, const Color(0xFF0C181A));
      expect(fallback.amberAccent, const Color(0xFFFFAE34));
      expect(fallback.signalRed, const Color(0xFFFF493A));
      expect(fallback.foliageVibrant, const Color(0xFF4B8E62));
    });

    test('copyWith updates targeted color fields', () {
      const fallback = ZenithDistrictColors.fallback;
      final updated = fallback.copyWith(
        amberAccent: const Color(0xFFFFFFFF),
        signalRed: const Color(0xFF000000),
      );

      expect(updated.amberAccent, const Color(0xFFFFFFFF));
      expect(updated.signalRed, const Color(0xFF000000));
      expect(updated.backgroundVoid, fallback.backgroundVoid);
      expect(updated.surfaceDark, fallback.surfaceDark);
    });

    test('lerp correctly interpolates colors', () {
      const a = ZenithDistrictColors.fallback;
      final b = a.copyWith(amberAccent: const Color(0xFF000000));

      final lerped = a.lerp(b, 1.0) as ZenithDistrictColors;
      expect(lerped.amberAccent, const Color(0xFF000000));
    });

    test('lerp with null returns self', () {
      const a = ZenithDistrictColors.fallback;
      expect(a.lerp(null, 0.5), a);
    });
  });

  group('ZenithPixelThemeBuilder', () {
    final testPalette = ZenithDistrictPalette(
      id: 'test_district',
      nameEn: 'Test District',
      nameJp: 'テスト地区',
      description: 'A test district for verification',
      backgroundVoid: const Color(0xFF010101),
      surfaceDark: const Color(0xFF020202),
      surfaceElevated: const Color(0xFF030303),
      surfaceHighlight: const Color(0xFF040404),
      borderMuted: const Color(0xFF050505),
      borderBright: const Color(0xFF060606),
      amberAccent: const Color(0xFF070707),
      amberGlow: const Color(0xFF080808),
      signalRed: const Color(0xFF090909),
      foliageVibrant: const Color(0xFF0A0A0A),
      textPrimary: const Color(0xFF0B0B0B),
      textMuted: const Color(0xFF0C0C0C),
      atmosphericMotif: (context) =>
          const SizedBox(key: ValueKey('test_motif')),
    );

    test('builds AppTheme with expected metadata and extensions', () {
      final appTheme = ZenithPixelThemeBuilder.build(
        testPalette,
        displayFont: _testFontBuilder('Silkscreen'),
        bodyFont: _testFontBuilder('Inter'),
      );

      expect(appTheme.id, 'test_district');
      expect(appTheme.displayName, 'Test District (テスト地区)');
      expect(appTheme.description, 'A test district for verification');
      expect(appTheme.isDark, isTrue);
      expect(appTheme.signatureMotif, isNotNull);

      // Verify colors extension
      final colors = appTheme.themeData.extension<ZenithDistrictColors>();
      expect(colors, isNotNull);
      expect(colors!.backgroundVoid, const Color(0xFF010101));
      expect(colors.surfaceDark, const Color(0xFF020202));
      expect(colors.amberAccent, const Color(0xFF070707));

      // Verify pixel metrics extension
      final metrics = appTheme.themeData.extension<ZenithPixelMetrics>();
      expect(metrics, isNotNull);
      expect(metrics!.pixelScale, 2.0);
      expect(metrics.buttonDropOffset, 3.0);

      // Verify themeData scaffold color matches backgroundVoid
      expect(
        appTheme.themeData.scaffoldBackgroundColor,
        const Color(0xFF010101),
      );
    });
  });

  group('ZenithThemeX BuildContext extension', () {
    testWidgets('reads extensions from theme or provides fallback', (
      tester,
    ) async {
      late ZenithDistrictColors resolvedColors;
      late ZenithPixelMetrics resolvedMetrics;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            resolvedColors = context.colors;
            resolvedMetrics = context.pixelMetrics;
            return const SizedBox();
          },
        ),
      );

      // When no theme extensions are registered, fallbacks are used
      expect(
        resolvedColors.backgroundVoid,
        ZenithDistrictColors.fallback.backgroundVoid,
      );
      expect(resolvedMetrics.pixelScale, 2.0);
    });

    testWidgets('reads custom extensions when registered on Theme', (
      tester,
    ) async {
      final customPalette = ZenithDistrictPalette(
        id: 'custom',
        nameEn: 'Custom',
        nameJp: 'カスタム',
        description: 'Custom palette',
        backgroundVoid: const Color(0xFF111111),
        surfaceDark: const Color(0xFF222222),
        surfaceElevated: const Color(0xFF333333),
        surfaceHighlight: const Color(0xFF444444),
        borderMuted: const Color(0xFF555555),
        borderBright: const Color(0xFF666666),
        amberAccent: const Color(0xFF777777),
        amberGlow: const Color(0xFF888888),
        signalRed: const Color(0xFF999999),
        foliageVibrant: const Color(0xFFAAAAAA),
        textPrimary: const Color(0xFFBBBBBB),
        textMuted: const Color(0xFFCCCCCC),
      );

      final appTheme = ZenithPixelThemeBuilder.build(
        customPalette,
        displayFont: _testFontBuilder('Silkscreen'),
        bodyFont: _testFontBuilder('Inter'),
      );

      late ZenithDistrictColors resolvedColors;
      late ZenithPixelMetrics resolvedMetrics;

      await tester.pumpWidget(
        Theme(
          data: appTheme.themeData,
          child: Builder(
            builder: (context) {
              resolvedColors = context.colors;
              resolvedMetrics = context.pixelMetrics;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedColors.backgroundVoid, const Color(0xFF111111));
      expect(resolvedColors.amberAccent, const Color(0xFF777777));
      expect(resolvedMetrics.borderWidth, 2.0);
    });
  });
}
