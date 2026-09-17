import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/features/districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import 'package:zenith/features/districts/railside_outskirts/railside_outskirts_palette.dart';
import 'package:zenith/features/districts/railside_outskirts/railside_outskirts_theme.dart';

void main() {
  group('District 01: Railside Outskirts Palette', () {
    test('matches canonical hex tokens from visual_identity_anchor.md', () {
      expect(railsideOutskirtsPalette.id, 'railside_outskirts');
      expect(railsideOutskirtsPalette.nameEn, 'Railside Outskirts');

      // Surfaces
      expect(railsideOutskirtsPalette.backgroundVoid, const Color(0xFF070E10));
      expect(railsideOutskirtsPalette.surfaceDark, const Color(0xFF0C181A));
      expect(railsideOutskirtsPalette.surfaceElevated, const Color(0xFF152B2C));
      expect(
        railsideOutskirtsPalette.surfaceHighlight,
        const Color(0xFF1F3E3D),
      );

      // Borders
      expect(railsideOutskirtsPalette.borderMuted, const Color(0xFF1A3332));
      expect(railsideOutskirtsPalette.borderBright, const Color(0xFF2D5552));

      // Signals & Accents
      expect(railsideOutskirtsPalette.amberAccent, const Color(0xFFFFAE34));
      expect(railsideOutskirtsPalette.amberGlow, const Color(0xFFFFD269));
      expect(railsideOutskirtsPalette.signalRed, const Color(0xFFFF493A));
      expect(railsideOutskirtsPalette.foliageVibrant, const Color(0xFF4B8E62));

      // Typography
      expect(railsideOutskirtsPalette.textPrimary, const Color(0xFFE8F5F2));
      expect(railsideOutskirtsPalette.textMuted, const Color(0xFF7D9B98));
    });

    test('atmosphericMotif builds RailsideAtmosphereBackdrop', () {
      expect(railsideOutskirtsPalette.atmosphericMotif, isNotNull);
    });
  });

  group('District Registry & Default Theme', () {
    test('zenithThemeRegistry registers district01 as default', () {
      expect(zenithThemeRegistry.themes, contains(district01RailsideOutskirts));
      expect(zenithThemeRegistry.defaultTheme.id, 'railside_outskirts');
      expect(
        zenithThemeRegistry.defaultTheme.displayName,
        'Railside Outskirts',
      );
    });

    test(
      'zenithThemeRegistry resolves known ID and safely falls back on unknown ID',
      () {
        final known = zenithThemeRegistry.byId('railside_outskirts');
        expect(known.id, 'railside_outskirts');

        final unknown = zenithThemeRegistry.byId('shrine_mist_unregistered');
        expect(unknown.id, 'railside_outskirts');
      },
    );

    test(
      'district01 theme has both ZenithDistrictColors and ZenithPixelMetrics extensions',
      () {
        final themeData = district01RailsideOutskirts.themeData;
        final colors = themeData.extension<ZenithDistrictColors>();
        final metrics = themeData.extension<ZenithPixelMetrics>();

        expect(colors, isNotNull);
        expect(metrics, isNotNull);
        expect(colors!.amberAccent, const Color(0xFFFFAE34));
        expect(metrics!.pixelScale, 2.0);
      },
    );
  });

  group('RailsideAtmosphereBackdrop Widget', () {
    testWidgets('renders cleanly on standard phone viewport (390x844)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RailsideAtmosphereBackdrop(
              child: Center(child: Text('Workout In Progress')),
            ),
          ),
        ),
      );

      expect(find.byType(RailsideAtmosphereBackdrop), findsOneWidget);
      expect(find.text('Workout In Progress'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renders without overflow on compact phone viewport (320x568)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: RailsideAtmosphereBackdrop())),
        );

        expect(find.byType(RailsideAtmosphereBackdrop), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders without overflow on tall phone viewport (412x915)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RailsideAtmosphereBackdrop(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text('Bottom Controls'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bottom Controls'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'pumpAndSettle completes -- the breathing lamp glow must not repeat forever under test',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: RailsideAtmosphereBackdrop())),
        );

        // A repeating (non-test-gated) AnimationController never reaches
        // rest, so pumpAndSettle() times out -- not just here, but on
        // every one of the 9 screens sharing this backdrop. This is the
        // regression test for that: it fails (times out) if the ground
        // lamp glow's controller ever repeats under isTestEnvironment
        // again, passes as soon as it holds a fixed value instead.
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
