import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/features/armory/armory.dart';

void main() {
  testWidgets(
    'ArmoryScreen renders all 6 gear slots and physiology toggles cleanly',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: zenithThemeRegistry.defaultTheme.themeData,
            home: const ArmoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Header & Title
      expect(find.text('THE ARMORY'), findsOneWidget);
      expect(find.text('SAVED ✓'), findsOneWidget);
      expect(find.text('EQUIPMENT INVENTORY'), findsOneWidget);
      expect(find.text('PHYSIOLOGY ACCOMMODATIONS'), findsOneWidget);

      // 2. Verify all 6 gear tiles are present
      expect(find.text('Bodyweight'), findsOneWidget);
      expect(find.text('Pull-up Bar'), findsOneWidget);
      expect(find.text('Resistance Bands'), findsOneWidget);
      expect(find.text('Bench / Chair'), findsOneWidget);
      expect(find.text('Suspension Straps'), findsOneWidget);
      expect(find.text('Door Towel Anchor'), findsOneWidget);

      // 3. Verify Bodyweight is ANCHORED and other gear is LOCKED by default
      expect(find.text('ANCHORED ●'), findsOneWidget);
      expect(find.text('LOCKED ○'), findsNWidgets(5));
      expect(
        find.textContaining('1 of 6 gear routes equipped'),
        findsOneWidget,
      );

      // 4. Tap Bodyweight -> must remain anchored and show a themed toast explanation
      await tester.tap(find.text('Bodyweight'));
      await tester.pump();
      expect(find.textContaining('permanently anchored'), findsOneWidget);
      expect(find.text('ANCHORED ●'), findsOneWidget);

      // 5. Tap Pull-up Bar -> becomes EQUIPPED
      await tester.tap(find.text('Pull-up Bar'));
      await tester.pumpAndSettle();

      expect(find.text('EQUIPPED ●'), findsOneWidget);
      expect(find.text('LOCKED ○'), findsNWidgets(4));
      expect(
        find.textContaining('2 of 6 gear routes equipped'),
        findsOneWidget,
      );

      // 6. Tap Pull-up Bar again -> un-equips back to LOCKED
      await tester.tap(find.text('Pull-up Bar'));
      await tester.pumpAndSettle();

      expect(find.text('EQUIPPED ●'), findsNothing);
      expect(find.text('LOCKED ○'), findsNWidgets(5));
      expect(
        find.textContaining('1 of 6 gear routes equipped'),
        findsOneWidget,
      );

      // 7. Scroll and verify Physiology Toggles
      await tester.ensureVisible(find.text('JOINT PROTECTION'));
      await tester.pumpAndSettle();

      expect(find.text('JOINT PROTECTION'), findsOneWidget);
      expect(find.text('CYCLE AUTOREGULATION'), findsOneWidget);
      expect(find.text('OFF ○'), findsNWidgets(2));
      expect(find.textContaining('joint protection OFF'), findsOneWidget);

      // Tap Joint Protection -> becomes ON
      await tester.tap(find.text('JOINT PROTECTION'));
      await tester.pumpAndSettle();

      expect(find.text('ON  ●'), findsOneWidget);
      expect(find.text('OFF ○'), findsOneWidget);
      expect(find.textContaining('joint protection ON'), findsOneWidget);

      // Scroll to Cycle Autoregulation and tap -> becomes ON
      await tester.ensureVisible(find.text('CYCLE AUTOREGULATION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CYCLE AUTOREGULATION'));
      await tester.pumpAndSettle();

      expect(find.text('ON  ●'), findsNWidgets(2));
      expect(find.textContaining('cycle autoreg ON'), findsOneWidget);
    },
  );

  testWidgets(
    'ArmoryScreen renders without RenderFlex overflow at a narrow mobile viewport',
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
            home: const ArmoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
