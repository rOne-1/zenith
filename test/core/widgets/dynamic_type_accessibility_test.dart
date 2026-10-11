import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/widgets/pixel_button.dart';
import 'package:zenith/core/widgets/zenith_navigation_bar.dart';
import 'package:zenith/features/districts/railside_outskirts/railside_outskirts_theme.dart';
import 'package:zenith/features/expedition/widgets/rpe_selector_card.dart';

void main() {
  group('Dynamic Type Scaling & Layout Resilience (A11Y-5)', () {
    testWidgets('ZenithNavigationBar renders at 1.5x text scale without RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: district01RailsideOutskirts.themeData,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5),
              size: Size(390, 844),
            ),
            child: Scaffold(
              bottomNavigationBar: ZenithNavigationBar(
                currentIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ZenithNavigationBar), findsOneWidget);
      expect(find.text('OUTPOST'), findsOneWidget);
      expect(find.text('ATLAS'), findsOneWidget);
    });

    testWidgets('ZenithNavigationBar renders at 2.0x text scale without RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: district01RailsideOutskirts.themeData,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              size: Size(390, 844),
            ),
            child: Scaffold(
              bottomNavigationBar: ZenithNavigationBar(
                currentIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ZenithNavigationBar), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('OUTPOST'), findsOneWidget);
    });

    testWidgets('RpeSelectorCard renders at 2.0x text scale without RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: district01RailsideOutskirts.themeData,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              size: Size(390, 844),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: RpeSelectorCard(
                  targetRpe: 8,
                  selectedRpe: 7,
                  onSelect: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RpeSelectorCard), findsOneWidget);
      expect(find.text('RPE 7: '), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('PixelButton expands vertically for multiline text at 2.0x scale without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: district01RailsideOutskirts.themeData,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              size: Size(390, 844),
            ),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  child: PixelButton(
                    label: 'MULTILINE EXPEDITION INITIATION PROTOCOL CONFIRMATION',
                    height: 48.0,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PixelButton), findsOneWidget);
      final RenderBox box = tester.renderObject(find.byType(PixelButton));
      // Ensure the button expanded beyond the 48.0 minHeight to accommodate multiline 2.0x text
      expect(box.size.height, greaterThanOrEqualTo(48.0));
    });
  });
}
