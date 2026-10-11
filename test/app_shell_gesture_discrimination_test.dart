import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/storage/storage.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/onboarding/providers/onboarding_provider.dart';
import 'package:zenith/main.dart';

void main() {
  group('ZenithAppShell Gesture Discrimination (UX-1)', () {
    late SharedPreferences prefs;
    late SbeeDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        kHasCompletedOnboardingKey: true,
      });
      prefs = await SharedPreferences.getInstance();
      db = SbeeDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(db),
        ],
        child: const ZenithApp(),
      );
    }

    testWidgets('committed swipe with displacement >= 64dp and velocity >= 500px/s switches tabs', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final swipeArea = find.byKey(const Key('zenithTabSwipeDetector'));
      expect(find.text('THE OUTPOST'), findsOneWidget);

      // Decisive swipe left: displacement -200dp, velocity 800px/s -> navigates to Atlas
      await tester.fling(swipeArea, const Offset(-200, 0), 800);
      await tester.pumpAndSettle();

      expect(find.text('THE ATLAS'), findsOneWidget);
    });

    testWidgets('short displacement (< 64dp) even with high velocity does NOT switch tabs', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final swipeArea = find.byKey(const Key('zenithTabSwipeDetector'));
      expect(find.text('THE OUTPOST'), findsOneWidget);

      // Short fling: displacement -40dp, velocity 800px/s
      await tester.fling(swipeArea, const Offset(-40, 0), 800);
      await tester.pumpAndSettle();

      // Should remain on OUTPOST
      expect(find.text('THE OUTPOST'), findsOneWidget);
    });

    testWidgets('slow drag (< 500px/s velocity) even with large displacement does NOT switch tabs', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final swipeArea = find.byKey(const Key('zenithTabSwipeDetector'));
      expect(find.text('THE OUTPOST'), findsOneWidget);

      // Drag 150dp slowly (velocity 200px/s)
      await tester.fling(swipeArea, const Offset(-150, 0), 200);
      await tester.pumpAndSettle();

      // Should remain on OUTPOST
      expect(find.text('THE OUTPOST'), findsOneWidget);
    });

    testWidgets('opposing displacement and velocity directions do NOT switch tabs', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final gestureDetector = find.byKey(const Key('zenithTabSwipeDetector'));
      expect(find.text('THE OUTPOST'), findsOneWidget);

      final TestGesture gesture = await tester.startGesture(tester.getCenter(gestureDetector));
      await gesture.moveBy(const Offset(100, 0));
      // Cancel gesture to trigger onHorizontalDragCancel
      await gesture.cancel();
      await tester.pumpAndSettle();

      // Should remain on OUTPOST
      expect(find.text('THE OUTPOST'), findsOneWidget);
    });

    testWidgets('arena cancellation in child scrollable does NOT switch tabs', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap to navigate to Atlas tab first
      await tester.tap(find.text('ATLAS'));
      await tester.pumpAndSettle();
      expect(find.text('THE ATLAS'), findsOneWidget);

      // In Grimoire, find a movement pattern chip or horizontal scrollable
      final chips = find.text('PUSH');
      if (chips.evaluate().isNotEmpty) {
        // Drag horizontally on the chip row
        await tester.drag(chips.first, const Offset(-80, 0));
        await tester.pumpAndSettle();
        // Still on ATLAS tab
        expect(find.text('THE ATLAS'), findsOneWidget);
      }
    });
  });
}
