import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/widgets/zenith_navigation_bar.dart';
import 'package:zenith/features/districts/railside_outskirts/railside_outskirts_theme.dart';

void main() {
  group('ZenithNavigationBar Widget Tests', () {
    testWidgets('renders all 4 railway ticket tabs with bilingual labels', (
      tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: district01RailsideOutskirts.themeData,
          home: Scaffold(
            bottomNavigationBar: ZenithNavigationBar(
              currentIndex: selectedIndex,
              onDestinationSelected: (idx) => selectedIndex = idx,
            ),
          ),
        ),
      );

      // Verify all 4 tab numbers
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('04'), findsOneWidget);

      // Verify all 4 English tab names
      expect(find.text('EXPEDITION'), findsOneWidget);
      expect(find.text('GRIMOIRE'), findsOneWidget);
      expect(find.text('ARMORY'), findsOneWidget);
      expect(find.text('SANCTUARY'), findsOneWidget);

      // Verify Japanese railway markings
      expect(find.text('遠征'), findsOneWidget);
      expect(find.text('魔導書'), findsOneWidget);
      expect(find.text('兵装'), findsOneWidget);
      expect(find.text('聖域'), findsOneWidget);
    });

    testWidgets('triggers onDestinationSelected when non-selected tab is tapped', (
      tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: district01RailsideOutskirts.themeData,
              home: Scaffold(
                bottomNavigationBar: ZenithNavigationBar(
                  currentIndex: selectedIndex,
                  onDestinationSelected: (idx) {
                    setState(() => selectedIndex = idx);
                  },
                ),
              ),
            );
          },
        ),
      );

      // Tap Armory tab (index 2)
      await tester.tap(find.text('ARMORY'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(2));

      // Tap Sanctuary tab (index 3)
      await tester.tap(find.text('SANCTUARY'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(3));
    });

    testWidgets(
      'tab press-down produces a spring-scaled tactile response, not a static tap',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: district01RailsideOutskirts.themeData,
            home: Scaffold(
              bottomNavigationBar: ZenithNavigationBar(
                currentIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        );

        // The tab bar uses AnimatedScale (HouseSpring-driven), not a bare
        // GestureDetector with no visual feedback.
        expect(find.byType(AnimatedScale), findsNWidgets(4));

        final armoryFinder = find.text('ARMORY');
        final gesture = await tester.startGesture(
          tester.getCenter(armoryFinder),
        );
        await tester.pump(const Duration(milliseconds: 16));

        final pressedScale = tester
            .widgetList<AnimatedScale>(find.byType(AnimatedScale))
            .firstWhere(
              (w) => w.scale != 1.0,
              orElse: () => const AnimatedScale(
                scale: 1.0,
                duration: Duration.zero,
                child: SizedBox(),
              ),
            );
        expect(pressedScale.scale, lessThan(1.0));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
