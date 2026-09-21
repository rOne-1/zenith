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
  });
}
