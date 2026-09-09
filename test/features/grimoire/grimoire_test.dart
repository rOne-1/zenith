import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/features/grimoire/grimoire.dart';

void main() {
  testWidgets(
    'GrimoireScreen renders metro transit map, filters lines, and inspects station',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: const GrimoireScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header and Subtitle
      expect(find.text('THE GRIMOIRE // 運動系統樹'), findsOneWidget);
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
      expect(find.text('STATION INSPECTION PASS // 乗車券'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StationInspectorSheet),
          matching: find.text('壁腕立て伏せ'),
        ),
        findsOneWidget,
      );
      expect(find.text('BIOMECHANICAL FORM SPECIFICATIONS'), findsOneWidget);
      expect(find.text('KENNETH MILLER PROGRESSION GAUGES'), findsOneWidget);
      expect(find.text('LOAD VECTOR'), findsOneWidget);
      expect(find.text('RANGE OF MOTION'), findsOneWidget);
      expect(find.text('CLOSE INSPECTOR // 閉じる'), findsOneWidget);

      // 8. Close Inspector Sheet
      await tester.tap(find.text('CLOSE INSPECTOR // 閉じる'));
      await tester.pumpAndSettle();

      // Sheet dismissed, GrimoireScreen visible
      expect(find.text('THE GRIMOIRE // 運動系統樹'), findsOneWidget);
      expect(find.text('STATION INSPECTION PASS // 乗車券'), findsNothing);
    },
  );

  testWidgets(
    'GrimoireScreen renders without RenderFlex overflow at a narrow mobile viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: const GrimoireScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
