import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/expedition/expedition.dart';
import 'package:zenith/features/grimoire/widgets/station_inspector_sheet.dart';

void main() {
  group('ExpeditionPortalScreen Widget Tests', () {
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

    Widget createTestWidget({List<Override> overrides = const []}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(database),
          ...overrides,
        ],
        child: MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: const ExpeditionPortalScreen(),
        ),
      );
    }

    testWidgets('renders station schedule HUD, DUP banner, and itinerary', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Station HUD header
      expect(find.text('ZENITH // 頂点'), findsOneWidget);
      expect(find.textContaining('PLATFORM 01'), findsOneWidget);
      expect(find.text('SECTOR 01'), findsOneWidget);

      // DUP banner
      expect(find.textContaining('//'), findsWidgets);
      expect(find.textContaining('TARGET RPE:'), findsOneWidget);

      // Itinerary section title
      expect(find.text('EXPEDITION ITINERARY // 運行表'), findsOneWidget);

      // Hero action button
      expect(find.text('▶ INITIATE EXPEDITION'), findsOneWidget);
    });

    testWidgets('tapping an exercise card opens StationInspectorSheet', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find first exercise card in itinerary by looking for difficulty tier indicator
      final tierFinder = find.textContaining('[T1]').first;
      expect(tierFinder, findsOneWidget);

      await tester.ensureVisible(tierFinder);
      await tester.tap(tierFinder);
      await tester.pumpAndSettle();

      // Station inspector pass sheet should be displayed
      expect(find.byType(StationInspectorSheet), findsOneWidget);
      expect(
        find.textContaining('STATION INSPECTION PASS // 乗車券'),
        findsOneWidget,
      );
    });

    testWidgets('tapping initiate expedition dispatches session', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initiateBtn = find.text('▶ INITIATE EXPEDITION');
      expect(initiateBtn, findsOneWidget);

      await tester.tap(initiateBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('EXPEDITION DISPATCHED'), findsOneWidget);
    });

    testWidgets(
      'triggers same-day advisory dialog if a completed session exists today',
      (tester) async {
        // Save a completed session earlier today
        final sessionRepo = DriftSessionRepository(database);
        final todayMorning = DateTime.now().subtract(const Duration(hours: 2));
        final morningSession = WorkoutSession(
          id: 'morning_completed',
          startTime: todayMorning,
          endTime: todayMorning.add(const Duration(minutes: 40)),
          isCompleted: true,
        );
        await sessionRepo.saveSession(morningSession);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap initiate expedition
        await tester.tap(find.text('▶ INITIATE EXPEDITION'));
        await tester.pumpAndSettle();

        // Should display the advisory dialog
        expect(find.byType(SameDayAdvisoryDialog), findsOneWidget);
        expect(
          find.text(WarningTranslator.sameDayAdvisoryTitle),
          findsOneWidget,
        );

        // Tap cancel in advisory dialog
        await tester.tap(find.text('CANCEL'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed and dispatch aborted
        expect(find.byType(SameDayAdvisoryDialog), findsNothing);
        expect(find.textContaining('EXPEDITION ABORTED'), findsOneWidget);
      },
    );

    testWidgets('displays unfinished session alert card when crash detected', (
      tester,
    ) async {
      // Save an incomplete session in DB
      final sessionRepo = DriftSessionRepository(database);
      final incompleteSession = WorkoutSession(
        id: 'incomplete_session_1',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        isCompleted: false,
      );
      await sessionRepo.saveSession(incompleteSession);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Crash alert card should appear
      expect(find.text('UNFINISHED EXPEDITION // 未完了の遠征'), findsOneWidget);
      expect(find.text('DISCARD'), findsOneWidget);
      expect(find.text('RESUME'), findsOneWidget);

      // Tap DISCARD
      await tester.tap(find.text('DISCARD'));
      await tester.pumpAndSettle();

      expect(find.textContaining('DISCARDED'), findsOneWidget);
    });
  });
}
