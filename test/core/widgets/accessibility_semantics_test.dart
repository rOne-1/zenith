import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/collapsible_card.dart';
import 'package:zenith/core/widgets/miller_variable_gauge.dart';
import 'package:zenith/core/widgets/pixel_button.dart';
import 'package:zenith/core/widgets/zenith_navigation_bar.dart';
import 'package:zenith/features/armory/widgets/gear_tile.dart';
import 'package:zenith/features/expedition/widgets/rpe_selector_card.dart';

bool hasFlag(SemanticsData data, SemanticsFlag flag) {
  // ignore: deprecated_member_use
  return data.hasFlag(flag);
}

void main() {
  final themeData = zenithThemeRegistry.defaultTheme.themeData;

  Widget wrapWithTheme(Widget child, {Size size = const Size(800, 600)}) {
    return MaterialApp(
      theme: themeData,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('A11Y-1 & A11Y-3: Accessibility Semantics & Touch Targets', () {
    testWidgets('ZenithNavigationBar tabs expose proper button, selected state, and composite labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          ZenithNavigationBar(
            currentIndex: 1, // ATLAS selected
            onDestinationSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify semantics nodes exist with the expected labels
      expect(
        find.bySemanticsLabel('OUTPOST tab, 01 of 4'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('ATLAS tab, 02 of 4'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('DEPOT tab, 03 of 4'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('SANCTUARY tab, 04 of 4'),
        findsOneWidget,
      );

      // Verify semantic traits (button: true, selected: isSelected)
      final atlasSemantics = tester.getSemantics(find.bySemanticsLabel('ATLAS tab, 02 of 4')).getSemanticsData();
      expect(hasFlag(atlasSemantics, SemanticsFlag.isSelected), isTrue);
      expect(hasFlag(atlasSemantics, SemanticsFlag.isButton), isTrue);

      final outpostSemantics = tester.getSemantics(find.bySemanticsLabel('OUTPOST tab, 01 of 4')).getSemanticsData();
      expect(hasFlag(outpostSemantics, SemanticsFlag.isSelected), isFalse);
      expect(hasFlag(outpostSemantics, SemanticsFlag.isButton), isTrue);
    });

    testWidgets('CollapsibleCard header exposes button trait, expanded state, and label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const CollapsibleCard(
            title: 'ADVANCED METRICS',
            subtitle: 'Real-time telemetry',
            icon: Icons.analytics,
            initiallyExpanded: false,
            child: Text('Telemetry details'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.bySemanticsLabel(RegExp(r'ADVANCED METRICS'));
      expect(headerFinder, findsOneWidget);

      var semantics = tester.getSemantics(headerFinder).getSemanticsData();
      expect(hasFlag(semantics, SemanticsFlag.isButton), isTrue);
      expect(hasFlag(semantics, SemanticsFlag.isExpanded), isFalse);

      // Tap header to toggle expansion
      await tester.tap(headerFinder);
      await tester.pumpAndSettle();

      semantics = tester.getSemantics(headerFinder).getSemanticsData();
      expect(hasFlag(semantics, SemanticsFlag.isExpanded), isTrue);
    });

    testWidgets('GearTile exposes button trait, checked state, and equipment name label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Column(
            children: [
              GearTile(
                equipment: Equipment.pullUpBar,
                isEquipped: true,
                onToggle: () {},
              ),
              GearTile(
                equipment: Equipment.bands,
                isEquipped: false,
                onToggle: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final barFinder = find.bySemanticsLabel('Pull-up Bar equipment');
      expect(barFinder, findsOneWidget);
      final barSemantics = tester.getSemantics(barFinder).getSemanticsData();
      expect(hasFlag(barSemantics, SemanticsFlag.isButton), isTrue);
      expect(hasFlag(barSemantics, SemanticsFlag.isChecked), isTrue);

      final bandsFinder = find.bySemanticsLabel('Resistance Bands equipment');
      expect(bandsFinder, findsOneWidget);
      final bandsSemantics = tester.getSemantics(bandsFinder).getSemanticsData();
      expect(hasFlag(bandsSemantics, SemanticsFlag.isButton), isTrue);
      expect(hasFlag(bandsSemantics, SemanticsFlag.isChecked), isFalse);
    });

    testWidgets('RpeSelectorCard buttons expose button trait, selected state, and RPE score label', (
      tester,
    ) async {
      int currentRpe = 7;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return wrapWithTheme(
              RpeSelectorCard(
                selectedRpe: currentRpe,
                targetRpe: 8,
                onSelect: (val) => setState(() => currentRpe = val),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 10 RPE buttons have semantic labels
      for (int i = 1; i <= 10; i++) {
        expect(find.bySemanticsLabel('RPE $i'), findsOneWidget);
      }

      // Verify selected state
      final rpe7Semantics = tester.getSemantics(find.bySemanticsLabel('RPE 7')).getSemanticsData();
      expect(hasFlag(rpe7Semantics, SemanticsFlag.isButton), isTrue);
      expect(hasFlag(rpe7Semantics, SemanticsFlag.isSelected), isTrue);

      final rpe8Semantics = tester.getSemantics(find.bySemanticsLabel('RPE 8')).getSemanticsData();
      expect(hasFlag(rpe8Semantics, SemanticsFlag.isButton), isTrue);
      expect(hasFlag(rpe8Semantics, SemanticsFlag.isSelected), isFalse);

      // Tap RPE 9 and verify update
      await tester.tap(find.bySemanticsLabel('RPE 9'));
      await tester.pumpAndSettle();

      final rpe9Semantics = tester.getSemantics(find.bySemanticsLabel('RPE 9')).getSemanticsData();
      expect(hasFlag(rpe9Semantics, SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('RpeButton touch target meets 48dp minimum height requirement', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          RpeSelectorCard(
            selectedRpe: 7,
            targetRpe: 7,
            onSelect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find first RPE button container and measure height
      final rpe1Finder = find.bySemanticsLabel('RPE 1');
      final size = tester.getSize(rpe1Finder);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('RpeSelectorCard renders without RenderFlex overflow on narrow 320px viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: themeData,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RpeSelectorCard(
                selectedRpe: 7,
                targetRpe: 8,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // If there was an overflow exception, tester.takeException() would be non-null
      expect(tester.takeException(), isNull);
    });

    testWidgets('MillerVariableGauge exposes intelligible spoken label and excludes raw block glyphs', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const Column(
            children: [
              MillerVariableGauge(
                label: 'LOAD',
                score: 3,
                maxScore: 5,
              ),
              MillerVariableGauge(
                label: 'TEMPO',
                score: 2,
                maxScore: 2,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('LOAD: 3 of 5'), findsOneWidget);
      expect(find.bySemanticsLabel('TEMPO: 2 of 2'), findsOneWidget);
    });
  });

  group('A11Y-2: WCAG AA Danger Button Contrast Compliance', () {
    testWidgets('PixelButtonVariant.danger text color uses backgroundVoid for 5.8:1 contrast', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          PixelButton(
            label: 'ABORT SESSION',
            variant: PixelButtonVariant.danger,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('ABORT SESSION'));
      final textColor = textWidget.style?.color;

      // Assert text color is backgroundVoid (dark inverted)
      final colors = zenithThemeRegistry.defaultTheme.colors;
      expect(textColor, equals(colors.backgroundVoid));

      // Calculate relative luminance and verify contrast ratio against signalRed >= 4.5:1
      final signalRed = colors.signalRed;
      final bgVoid = colors.backgroundVoid;

      double luminance(Color c) {
        final r = c.r;
        final g = c.g;
        final b = c.b;
        final lr = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055) * ((r + 0.055) / 1.055);
        final lg = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055) * ((g + 0.055) / 1.055);
        final lb = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055) * ((b + 0.055) / 1.055);
        return 0.2126 * lr + 0.7152 * lg + 0.0722 * lb;
      }

      final l1 = luminance(signalRed);
      final l2 = luminance(bgVoid);
      final brighter = l1 > l2 ? l1 : l2;
      final darker = l1 > l2 ? l2 : l1;
      final contrastRatio = (brighter + 0.05) / (darker + 0.05);

      expect(contrastRatio, greaterThanOrEqualTo(4.5));
    });
  });
}
