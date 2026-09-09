import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/expedition/expedition.dart';
import 'package:zenith/features/outpost/outpost.dart';

void main() {
  group('OutpostScreen Widget Tests', () {
    late SbeeDatabase database;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      database = SbeeDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: const OutpostScreen(),
        ),
      );
    }

    testWidgets(
      'renders daily briefing header, streak, today\'s session, and weekly stats',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Header
        expect(find.text('THE OUTPOST'), findsOneWidget);
        expect(find.text('DAILY BRIEFING & TRAINING STATUS'), findsOneWidget);

        // Streak card - a fresh account has a 0-day streak (real, not fake, data)
        expect(find.text('TRAINING STREAK'), findsOneWidget);
        expect(find.text('CONSECUTIVE DAYS'), findsOneWidget);

        // Today's session card - real SBEE-generated session, not a placeholder
        expect(find.textContaining('DAY'), findsWidgets);
        expect(find.textContaining('EXERCISES /'), findsOneWidget);
        expect(find.text("▶ TODAY'S EXPEDITION"), findsOneWidget);

        // Weekly stats row
        expect(find.text('SESSIONS'), findsOneWidget);
        expect(find.text('SETS'), findsOneWidget);
        expect(find.text('TONNAGE'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the quick-start CTA pushes the full Expedition Portal itinerary',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text("▶ TODAY'S EXPEDITION"));
        await tester.pumpAndSettle();

        expect(find.byType(ExpeditionPortalScreen), findsOneWidget);
        expect(find.text('EXPEDITION ITINERARY'), findsOneWidget);
      },
    );

    testWidgets('renders without RenderFlex overflow at a narrow mobile viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
