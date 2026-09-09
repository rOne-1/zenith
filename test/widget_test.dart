import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/widgets.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/expedition/expedition.dart';
import 'package:zenith/features/sanctuary/sanctuary.dart';
import 'package:zenith/main.dart';

void main() {
  testWidgets(
    'ZenithApp smoke test renders AppShell, navigation bar, and dispatches expedition',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = SbeeDatabase(NativeDatabase.memory());

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              sbeeDatabaseProvider.overrideWithValue(db),
            ],
            child: const ZenithApp(),
          ),
        );

        // Initial frame
        await tester.pumpAndSettle();

        // Verify header and district identity in Expedition tab
        expect(find.text('ZENITH'), findsOneWidget);
        expect(find.textContaining('PLATFORM 01'), findsOneWidget);
        expect(find.text('SECTOR 01'), findsOneWidget);

        // Verify navigation tabs
        expect(find.text('EXPEDITION'), findsOneWidget);
        expect(find.text('ATLAS'), findsOneWidget);
        expect(find.text('DEPOT'), findsOneWidget);
        expect(find.text('SANCTUARY'), findsOneWidget);

        // Verify itinerary and initiate button
        expect(find.text('EXPEDITION ITINERARY'), findsOneWidget);
        final initiateBtn = find.text('▶ INITIATE EXPEDITION');
        expect(initiateBtn, findsOneWidget);

        // Tap initiate expedition button
        await tester.tap(initiateBtn);
        await tester.pumpAndSettle();

        // Verify navigation to active expedition screen
        expect(find.byType(ActiveExpeditionScreen), findsOneWidget);

        // Pop back to shell to test navigation bar tabs
        final nav =
            Navigator.of(tester.element(find.byType(ActiveExpeditionScreen)));
        nav.pop();
        await tester.pumpAndSettle();

        // Test tab switching to Armory
        await tester.tap(find.text('DEPOT'));
        await tester.pumpAndSettle();

        expect(find.text('EQUIPMENT INVENTORY'), findsOneWidget);

        // Test tab switching to Grimoire
        await tester.tap(find.text('ATLAS'));
        await tester.pumpAndSettle();

        expect(find.text('THE ATLAS'), findsOneWidget);

        // Test tab switching to Sanctuary
        await tester.tap(
          find.descendant(
            of: find.byType(ZenithNavigationBar),
            matching: find.text('SANCTUARY'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(SanctuaryScreen),
            matching: find.text('SANCTUARY'),
          ),
          findsOneWidget,
        );
      } finally {
        await db.close();
      }
    },
  );
}
