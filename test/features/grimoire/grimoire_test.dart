import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/app_shell.dart';
import 'package:zenith/core/storage/storage.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/pixel_button.dart';
import 'package:zenith/features/districts/neon_alleys/neon_alleys_theme.dart';
import 'package:zenith/features/grimoire/grimoire.dart';

void main() {
  testWidgets(
    'GrimoireScreen back button returns to Outpost (tab index 0), not a no-op pop',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      container.read(activeNavigationTabIndexProvider.notifier).state = 1;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: zenithThemeRegistry.defaultTheme.themeData,
            home: const GrimoireScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byWidgetPredicate(
        (widget) =>
            widget is PixelButton && widget.semanticLabel == 'Back to Outpost',
      );
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(container.read(activeNavigationTabIndexProvider), 0);
    },
  );

  testWidgets(
    'GrimoireScreen renders metro transit map, filters lines, and inspects station',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: zenithThemeRegistry.defaultTheme.themeData,
            home: const GrimoireScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header and Subtitle
      expect(find.text('THE ATLAS'), findsOneWidget);
      expect(
        find.text('METRO TRANSIT MAP OF MOVEMENT PROGRESSIONS'),
        findsOneWidget,
      );

      // 2. Filter Pills
      expect(find.text('ALL LINES'), findsOneWidget);
      expect(find.text('PUSH'), findsOneWidget);
      expect(find.text('PULL'), findsOneWidget);
      expect(find.text('BEND & LIFT'), findsOneWidget);
      expect(find.text('LEGS'), findsOneWidget);
      expect(find.text('ROTATION'), findsOneWidget);

      // 3. Initial rendering has exercises from the first line (Bend & Lift)
      expect(find.text('Bodyweight Hip Hinge'), findsOneWidget);

      // 4. Tap 'PUSH' filter pill
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      // Bend & Lift stations must no longer be present, Push stations visible
      expect(find.text('Bodyweight Hip Hinge'), findsNothing);
      expect(find.text('Wall Push-up'), findsOneWidget);

      // 5. Tap 'PULL' filter pill
      await tester.tap(find.text('PULL'));
      await tester.pumpAndSettle();

      // Pushing stations must no longer be present, Pull stations visible
      expect(find.text('Wall Push-up'), findsNothing);
      expect(find.text('Doorframe Bodyweight Row'), findsOneWidget);

      // 6. Tap 'PUSH' again to inspect Wall Push-up
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();
      expect(find.text('Wall Push-up'), findsOneWidget);

      // 7. Tap 'Wall Push-up' station card to open StationInspectorSheet
      await tester.tap(find.text('Wall Push-up'));
      await tester.pumpAndSettle();

      // Verify Inspector Sheet contents
      expect(find.text('STATION INSPECTION PASS'), findsOneWidget);
      expect(find.text('BIOMECHANICAL FORM SPECIFICATIONS'), findsOneWidget);
      expect(find.byType(ExerciseIllustration), findsOneWidget);
      expect(find.text('KENNETH MILLER PROGRESSION GAUGES'), findsOneWidget);
      expect(find.text('LOAD VECTOR'), findsOneWidget);
      expect(find.text('RANGE OF MOTION'), findsOneWidget);
      expect(find.text('CLOSE INSPECTOR'), findsOneWidget);

      // 8. Close Inspector Sheet
      // The sheet's own content can now be taller than the default test
      // surface (800x600) with the illustration added, so the close button
      // may sit below the fold of the sheet's internal scroll view -- scroll
      // it into view first, same as a real user would.
      await tester.ensureVisible(find.text('CLOSE INSPECTOR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CLOSE INSPECTOR'));
      await tester.pumpAndSettle();

      // Sheet dismissed, GrimoireScreen visible
      expect(find.text('THE ATLAS'), findsOneWidget);
      expect(find.text('STATION INSPECTION PASS'), findsNothing);
    },
  );

  testWidgets(
    'GrimoireScreen renders without RenderFlex overflow at a narrow mobile viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: zenithThemeRegistry.defaultTheme.themeData,
            home: const GrimoireScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'GrimoireScreen filter pills resolve dynamic colors based on district theme',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 1. Verify under District 01 (Railside Outskirts)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: zenithThemeRegistry.defaultTheme.themeData,
            home: const GrimoireScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      final pushContainerD1 = tester.widget<Container>(
        find.ancestor(
          of: find.text('PUSH'),
          matching: find.byType(Container),
        ).first,
      );
      final d1PushDeco = pushContainerD1.decoration as BoxDecoration;
      expect(d1PushDeco.color, const Color(0xFFFFAE34)); // District 01 accentPrimary

      // 2. Verify under District 02 (Neon Alleys)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: district02NeonAlleys.themeData,
            home: const GrimoireScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      final pushContainerD2 = tester.widget<Container>(
        find.ancestor(
          of: find.text('PUSH'),
          matching: find.byType(Container),
        ).first,
      );
      final d2PushDeco = pushContainerD2.decoration as BoxDecoration;
      expect(d2PushDeco.color, const Color(0xFFFF2FA0)); // District 02 fuchsia accent

      await tester.tap(find.text('PULL'));
      await tester.pumpAndSettle();

      final pullContainerD2 = tester.widget<Container>(
        find.ancestor(
          of: find.text('PULL'),
          matching: find.byType(Container),
        ).first,
      );
      final d2PullDeco = pullContainerD2.decoration as BoxDecoration;
      expect(d2PullDeco.color, const Color(0xFF39C08A)); // District 02 fern accent
    },
  );
}
