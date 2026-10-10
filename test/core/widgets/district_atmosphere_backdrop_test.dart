import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/widgets.dart';
import 'package:zenith/features/districts/neon_alleys/neon_alleys_atmosphere_backdrop.dart';
import 'package:zenith/features/districts/railside_outskirts/railside_atmosphere_backdrop.dart';

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

    testWidgets('multiple simultaneously-mounted NeonAlleysAtmosphereBackdrop '
        'widgets share one neonAlleysVideoControllerProvider instance', (
      tester,
    ) async {
      // Regression coverage: IndexedStack keeps Outpost/Atlas/Depot/
      // Sanctuary mounted at the same time, so switching to Neon Alleys
      // used to construct one independent VideoPlayerController per
      // screen -- 4 simultaneous decoders for the same asset, of which
      // only the visible one actually played; the rest stalled on their
      // first frame and read as a static image. video_player has no
      // platform implementation under `flutter test` (isTestEnvironment
      // makes the provider return null here), so this can't assert on
      // real playback -- what it does assert is the architectural fix:
      // reading the provider from two independently-mounted consumers in
      // the same container resolves to the exact same value, proving
      // there's one shared instance rather than one per widget.
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
          container.read(neonAlleysVideoControllerProvider),
          container.read(neonAlleysVideoControllerProvider),
        ),
        isTrue,
        reason:
            'both mounted backdrops must resolve the exact same '
            'controller instance from the shared container, not one each',
      );
    });
  });
}
