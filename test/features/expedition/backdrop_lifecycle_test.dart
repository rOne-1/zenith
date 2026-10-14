import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/app_shell.dart';
import 'package:zenith/core/storage/storage.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/widgets.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/districts/neon_alleys/neon_alleys_atmosphere_backdrop.dart';
import 'package:zenith/features/expedition/screens/active_expedition_screen.dart';
import 'package:zenith/features/expedition/screens/expedition_portal_screen.dart';
import 'package:zenith/features/expedition/screens/working_set_screen.dart';
import 'package:zenith/features/onboarding/providers/onboarding_provider.dart';
import 'package:zenith/main.dart';

void main() {
  group(
    'Backdrop Lifecycle & Single Backdrop Invariant Tests (PKG-12.1 / PKG-12.4)',
    () {
      late SbeeDatabase database;
      late SharedPreferences prefs;

      setUp(() async {
        SharedPreferences.setMockInitialValues({
          kHasCompletedOnboardingKey: true,
        });
        prefs = await SharedPreferences.getInstance();
        database = SbeeDatabase(NativeDatabase.memory());
      });

      tearDown(() async {
        await database.close();
      });

      testWidgets(
        'enforces exactly 1 DistrictAtmosphereBackdrop across ExpeditionPortal, ActiveExpedition, and post-abort recovery',
        (tester) async {
          tester.view.physicalSize = const Size(600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                sbeeDatabaseProvider.overrideWithValue(database),
              ],
              child: const ZenithApp(),
            ),
          );
          await tester.pumpAndSettle();

          // Switch to Neon Alleys theme to test the animated video backdrop
          final container = ProviderScope.containerOf(
            tester.element(find.byType(ZenithAppShell)),
          );
          await container
              .read(themeControllerProvider)
              .setThemeById('neon_alleys');
          await tester.pumpAndSettle();

          // 1. Initial State: OutpostScreen
          // Root backdrop must be mounted exactly once
          expect(find.byType(DistrictAtmosphereBackdrop), findsOneWidget);
          expect(find.byType(NeonAlleysAtmosphereBackdrop), findsOneWidget);

          // 2. Navigate to ExpeditionPortalScreen
          final todayButton = find.text("▶ TODAY'S EXPEDITION");
          expect(todayButton, findsOneWidget);
          await tester.tap(todayButton);
          await tester.pumpAndSettle();

          expect(find.byType(ExpeditionPortalScreen), findsOneWidget);
          expect(find.text('EXPEDITION ITINERARY'), findsOneWidget);
          // Assert Single Backdrop Invariant (SP-1) in portal
          expect(find.byType(DistrictAtmosphereBackdrop), findsOneWidget);
          expect(find.byType(NeonAlleysAtmosphereBackdrop), findsOneWidget);

          // 3. Initiate Expedition -> ActiveExpeditionScreen (Warm-Up phase)
          final initiateBtn = find.text('▶ INITIATE EXPEDITION');
          expect(initiateBtn, findsOneWidget);
          await tester.tap(initiateBtn);
          await tester.pumpAndSettle();

          expect(find.byType(ActiveExpeditionScreen), findsOneWidget);
          expect(find.text('WARM-UP MOBILIZATION'), findsOneWidget);
          // Verify underlying ExpeditionPortalScreen content is occluded (no visual bleed/stacking)
          expect(find.text('EXPEDITION ITINERARY'), findsNothing);
          expect(find.text("TODAY'S DIFFICULTY DIALS"), findsNothing);
          // Assert Single Backdrop Invariant in warm-up
          expect(find.byType(DistrictAtmosphereBackdrop), findsOneWidget);
          expect(find.byType(NeonAlleysAtmosphereBackdrop), findsOneWidget);

          // 4. Advance to Working Set phase
          final startWorkingSetsBtn = find.text('▶ COMMENCE WORKING SETS');
          expect(startWorkingSetsBtn, findsOneWidget);
          await tester.tap(startWorkingSetsBtn);
          await tester.pumpAndSettle();

          expect(find.byType(WorkingSetScreen), findsOneWidget);
          expect(find.text("TODAY'S DIFFICULTY DIALS"), findsOneWidget);
          // Verify underlying ExpeditionPortalScreen content remains occluded behind WorkingSetScreen
          expect(find.text('EXPEDITION ITINERARY'), findsNothing);
          // Assert Single Backdrop Invariant in working sets
          expect(find.byType(DistrictAtmosphereBackdrop), findsOneWidget);
          expect(find.byType(NeonAlleysAtmosphereBackdrop), findsOneWidget);

          // 5. Abort Workout Flow
          // Tap abort button '✕'
          final abortButton = find.text('✕');
          expect(abortButton, findsOneWidget);
          await tester.tap(abortButton);
          await tester.pumpAndSettle();

          // Dialog opens
          expect(find.text('ABORT EXPEDITION'), findsOneWidget);
          final confirmAbortButton = find.descendant(
            of: find.byType(Dialog),
            matching: find.widgetWithText(PixelButton, 'ABORT'),
          );
          expect(confirmAbortButton, findsOneWidget);
          await tester.tap(confirmAbortButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Allow background persistence discard and provider invalidation on isolate to complete
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pumpAndSettle();

          // 6. Post-Abort Recovery:
          // ActiveExpeditionScreen must be popped, returning to ExpeditionPortalScreen
          expect(find.byType(ActiveExpeditionScreen), findsNothing);
          expect(find.byType(ExpeditionPortalScreen), findsOneWidget);
          // ExpeditionPortalScreen content reappears on stage
          expect(find.text('EXPEDITION ITINERARY'), findsOneWidget);
          expect(find.text("TODAY'S DIFFICULTY DIALS"), findsNothing);

          // The root backdrop must remain actively mounted and rendered with zero blackout
          expect(find.byType(DistrictAtmosphereBackdrop), findsOneWidget);
          expect(find.byType(NeonAlleysAtmosphereBackdrop), findsOneWidget);

          // 7. Pop from ExpeditionPortalScreen back to Outpost
          final backButton = find.text('←');
          expect(backButton, findsOneWidget);
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          expect(find.byType(ExpeditionPortalScreen), findsNothing);
          expect(find.text('THE OUTPOST'), findsOneWidget);
          expect(find.byType(DistrictAtmosphereBackdrop), findsOneWidget);
          expect(find.byType(NeonAlleysAtmosphereBackdrop), findsOneWidget);
        },
      );
    },
  );
}
