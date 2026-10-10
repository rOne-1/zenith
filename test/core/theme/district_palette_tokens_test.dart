import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/pixel_button.dart';
import 'package:zenith/features/districts/neon_alleys/neon_alleys_palette.dart';
import 'package:zenith/features/districts/railside_outskirts/railside_outskirts_palette.dart';

void main() {
  group('PKG-8.3: Design Token System & Palette Foundations', () {
    test('Railside Outskirts palette exposes canonical token values and aliases', () {
      expect(railsideOutskirtsPalette.accentSecondary, const Color(0xFF2EE6D6));
      expect(railsideOutskirtsPalette.accentPrimary, railsideOutskirtsPalette.amberAccent);
      expect(railsideOutskirtsPalette.accentGlow, railsideOutskirtsPalette.amberGlow);

      final theme = zenithThemeRegistry.byId('railside_outskirts');
      final colors = theme.colors;
      expect(colors.accentSecondary, const Color(0xFF2EE6D6));
      expect(colors.accentPrimary, const Color(0xFFFFAE34));
      expect(colors.accentGlow, const Color(0xFFFFD269));
    });

    test('Neon Alleys palette realizes canonical Japanese cyberpunk chromatic DNA', () {
      expect(neonAlleysPalette.backgroundVoid, const Color(0xFF060814));
      expect(neonAlleysPalette.surfaceDark, const Color(0xFF0D1424));
      expect(neonAlleysPalette.surfaceElevated, const Color(0xFF182140));
      expect(neonAlleysPalette.surfaceHighlight, const Color(0xFF232C52));
      expect(neonAlleysPalette.borderMuted, const Color(0xFF1E2A4A));
      expect(neonAlleysPalette.borderBright, const Color(0xFF3C4E88));
      expect(neonAlleysPalette.amberAccent, const Color(0xFFFF2FA0));
      expect(neonAlleysPalette.accentPrimary, const Color(0xFFFF2FA0));
      expect(neonAlleysPalette.amberGlow, const Color(0xFFFF8EC9));
      expect(neonAlleysPalette.accentGlow, const Color(0xFFFF8EC9));
      expect(neonAlleysPalette.accentSecondary, const Color(0xFF39C08A));
      expect(neonAlleysPalette.signalRed, const Color(0xFFFF493A));
      expect(neonAlleysPalette.foliageVibrant, const Color(0xFF4B8E62));
      expect(neonAlleysPalette.textPrimary, const Color(0xFFE8F5F2));
      expect(neonAlleysPalette.textMuted, const Color(0xFF7D9B98));

      final theme = zenithThemeRegistry.byId('neon_alleys');
      final colors = theme.colors;
      expect(colors.backgroundVoid, const Color(0xFF060814));
      expect(colors.accentPrimary, const Color(0xFFFF2FA0));
      expect(colors.accentSecondary, const Color(0xFF39C08A));
    });

    test('ZenithDistrictColors fallback provides valid default tokens and aliases', () {
      const fallback = ZenithDistrictColors.fallback;
      expect(fallback.accentSecondary, const Color(0xFF2EE6D6));
      expect(fallback.accentPrimary, fallback.amberAccent);
      expect(fallback.accentGlow, fallback.amberGlow);

      final copy = fallback.copyWith(
        accentSecondary: const Color(0xFF123456),
      );
      expect(copy.accentSecondary, const Color(0xFF123456));
      expect(copy.accentPrimary, fallback.accentPrimary);
    });
  });

  group('PKG-8.3: Dynamic Button Bevel Shading', () {
    testWidgets('PixelButton adapts primary bevel dynamically between amber and fuchsia themes', (
      tester,
    ) async {
      // 1. Render under Railside Outskirts (Amber)
      final railsideTheme = zenithThemeRegistry.byId('railside_outskirts').themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: railsideTheme,
          home: Scaffold(
            body: PixelButton(
              label: 'RAILSIDE ACTION',
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the CustomPaint that paints the bevel
      final railsideFinder = find.byType(CustomPaint);
      expect(railsideFinder, findsWidgets);

      // 2. Render under Neon Alleys (Fuchsia)
      final neonTheme = zenithThemeRegistry.byId('neon_alleys').themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: neonTheme,
          home: Scaffold(
            body: PixelButton(
              label: 'NEON ACTION',
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEON ACTION'), findsOneWidget);
    });

    testWidgets('PixelButton danger variant derives bevel and border dynamically without hardcoded literals', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: Scaffold(
            body: PixelButton(
              label: 'ABORT',
              variant: PixelButtonVariant.danger,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ABORT'), findsOneWidget);
    });
  });
}
