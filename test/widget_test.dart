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

        // Verify the Outpost dashboard renders as the home screen
        expect(find.text('THE OUTPOST'), findsOneWidget);

        // Verify navigation tabs
        expect(find.text('OUTPOST'), findsOneWidget);
        expect(find.text('ATLAS'), findsOneWidget);
        expect(find.text('DEPOT'), findsOneWidget);
        expect(find.text('SANCTUARY'), findsOneWidget);

        // Push into the full Expedition Portal itinerary via the Outpost's
        // quick-start CTA
        final startBtn = find.text("▶ TODAY'S EXPEDITION");
        expect(startBtn, findsOneWidget);
        await tester.tap(startBtn);
        await tester.pumpAndSettle();

        // Verify header and district identity in the pushed Expedition Portal
        expect(find.text('ZENITH'), findsOneWidget);
        expect(find.textContaining('PLATFORM 01'), findsOneWidget);
        expect(find.text('SECTOR 01'), findsOneWidget);

        // Verify itinerary and initiate button
        expect(find.text('EXPEDITION ITINERARY'), findsOneWidget);
        final initiateBtn = find.text('▶ INITIATE EXPEDITION');
        expect(initiateBtn, findsOneWidget);

        // Tap initiate expedition button
        await tester.tap(initiateBtn);
        await tester.pumpAndSettle();

        // Verify navigation to active expedition screen
        expect(find.byType(ActiveExpeditionScreen), findsOneWidget);

        // Pop back to the Expedition Portal, then back to the Outpost shell
        final nav =
            Navigator.of(tester.element(find.byType(ActiveExpeditionScreen)));
        nav.pop();
        await tester.pumpAndSettle();
        expect(find.byType(ExpeditionPortalScreen), findsOneWidget);

        final portalNav =
            Navigator.of(tester.element(find.byType(ExpeditionPortalScreen)));
        portalNav.pop();
        await tester.pumpAndSettle();
        expect(find.text('THE OUTPOST'), findsOneWidget);

        // Test tab switching to Depot
        await tester.tap(find.text('DEPOT'));
        await tester.pumpAndSettle();

        expect(find.text('EQUIPMENT INVENTORY'), findsOneWidget);

        // Test tab switching to Atlas
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
