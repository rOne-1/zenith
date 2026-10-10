import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/district_background_media_layer.dart';
import 'package:zenith/core/widgets/widgets.dart';
import 'package:zenith/features/districts/neon_alleys/neon_alleys_atmosphere_backdrop.dart';
import 'package:zenith/features/districts/railside_outskirts/railside_atmosphere_backdrop.dart';

const _neonAlleysVideoAsset = 'assets/backgrounds/neon_alleys_loop.mp4';

void main() {
  group('DistrictAtmosphereBackdrop', () {
    testWidgets('renders RailsideAtmosphereBackdrop for the default theme', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            home: DistrictAtmosphereBackdrop(child: Text('content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RailsideAtmosphereBackdrop), findsOneWidget);
      expect(find.byType(NeonAlleysAtmosphereBackdrop), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets(
      'renders NeonAlleysAtmosphereBackdrop once the theme is switched to Neon Alleys',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: DistrictAtmosphereBackdrop(child: Text('content')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RailsideAtmosphereBackdrop), findsOneWidget);

        await container
            .read(themeControllerProvider)
            .setThemeById('neon_alleys');
        await tester.pumpAndSettle();

        expect(find.byType(NeonAlleysAtmosphereBackdrop), findsOneWidget);
        expect(find.byType(RailsideAtmosphereBackdrop), findsNothing);
        expect(find.text('content'), findsOneWidget);
      },
    );

    testWidgets('multiple simultaneously-mounted consumers of the same video '
        'asset share one districtVideoControllerProvider instance', (
      tester,
    ) async {
      // Regression coverage for the underlying sharing mechanism: any two
      // widgets reading districtVideoControllerProvider for the same asset
      // path -- whether that's two NeonAlleysAtmosphereBackdrop instances,
      // or a pushed route sitting on top of a still-mounted caller -- must
      // resolve to the exact same controller instance, not one each.
      // video_player has no platform implementation under `flutter test`
      // (isTestEnvironment makes the provider return null here), so this
      // can't assert on real playback -- it asserts the sharing contract.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: NeonAlleysAtmosphereBackdrop(),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: NeonAlleysAtmosphereBackdrop(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NeonAlleysAtmosphereBackdrop), findsNWidgets(2));
      expect(
        identical(
          container.read(
            districtVideoControllerProvider(_neonAlleysVideoAsset),
          ),
          container.read(
            districtVideoControllerProvider(_neonAlleysVideoAsset),
          ),
        ),
        isTrue,
        reason:
            'both mounted consumers must resolve the exact same '
            'controller instance from the shared container, not one each',
      );
    });

    testWidgets(
      'isolates NeonAlleysAtmosphereBackdrop layers inside RepaintBoundary separate from child',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: NeonAlleysAtmosphereBackdrop(
                  child: Text('Foreground Neon Content'),
                ),
              ),
            ),
          ),
        );

        final repaintBoundaryFinder = find.descendant(
          of: find.byType(NeonAlleysAtmosphereBackdrop),
          matching: find.byType(RepaintBoundary),
        );
        expect(repaintBoundaryFinder, findsOneWidget);

        expect(
          find.descendant(
            of: repaintBoundaryFinder,
            matching: find.byType(DistrictBackgroundMediaLayer),
          ),
          findsOneWidget,
        );

        expect(
          find.descendant(
            of: repaintBoundaryFinder,
            matching: find.byType(DecoratedBox),
          ),
          findsOneWidget,
        );

        expect(
          find.descendant(
            of: repaintBoundaryFinder,
            matching: find.text('Foreground Neon Content'),
          ),
          findsNothing,
        );
        expect(find.text('Foreground Neon Content'), findsOneWidget);
      },
    );
  });
}
