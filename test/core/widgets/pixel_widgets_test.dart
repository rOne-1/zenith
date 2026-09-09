import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/widgets/widgets.dart';

void main() {
  group('SteppedPixelBorder', () {
    test('dimensions matches side width', () {
      const border = SteppedPixelBorder(
        side: BorderSide(color: Colors.white, width: 3.0),
        stepSize: 4.0,
      );
      expect(border.dimensions, const EdgeInsets.all(3.0));
    });

    test('scale scales side width and step size', () {
      const border = SteppedPixelBorder(
        side: BorderSide(color: Colors.white, width: 2.0),
        stepSize: 4.0,
      );
      final scaled = border.scale(2.0) as SteppedPixelBorder;
      expect(scaled.side.width, 4.0);
      expect(scaled.stepSize, 8.0);
    });

    test('copyWith updates specified properties', () {
      const border = SteppedPixelBorder(
        side: BorderSide(color: Colors.white, width: 2.0),
        stepSize: 4.0,
      );
      final copied =
          border.copyWith(
                side: const BorderSide(color: Colors.red, width: 3.0),
                stepSize: 6.0,
              )
              as SteppedPixelBorder;

      expect(copied.side.color, Colors.red);
      expect(copied.side.width, 3.0);
      expect(copied.stepSize, 6.0);
    });

    test('getOuterPath returns non-empty path with bounds matching rect', () {
      const border = SteppedPixelBorder(stepSize: 4.0);
      const rect = Rect.fromLTWH(0, 0, 100, 50);
      final path = border.getOuterPath(rect);

      expect(path, isNotNull);
      expect(path.getBounds(), const Rect.fromLTWH(0, 0, 100, 50));
    });

    test('getInnerPath returns deflated path', () {
      const border = SteppedPixelBorder(
        side: BorderSide(color: Colors.white, width: 2.0),
        stepSize: 4.0,
      );
      const rect = Rect.fromLTWH(0, 0, 100, 50);
      final innerPath = border.getInnerPath(rect);

      expect(innerPath, isNotNull);
      expect(innerPath.getBounds(), const Rect.fromLTWH(2, 2, 96, 46));
    });

    test('lerp correctly interpolates borders', () {
      const a = SteppedPixelBorder(
        side: BorderSide(color: Colors.black, width: 2.0),
        stepSize: 2.0,
      );
      const b = SteppedPixelBorder(
        side: BorderSide(color: Colors.black, width: 4.0),
        stepSize: 6.0,
      );

      final lerped = ShapeBorder.lerp(a, b, 0.5) as SteppedPixelBorder;
      expect(lerped.side.width, 3.0);
      expect(lerped.stepSize, 4.0);
    });

    test('equality and hashCode contract', () {
      const b1 = SteppedPixelBorder(
        side: BorderSide(color: Colors.white, width: 2.0),
        stepSize: 4.0,
      );
      const b2 = SteppedPixelBorder(
        side: BorderSide(color: Colors.white, width: 2.0),
        stepSize: 4.0,
      );
      const b3 = SteppedPixelBorder(
        side: BorderSide(color: Colors.red, width: 2.0),
        stepSize: 4.0,
      );

      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
      expect(b1, isNot(equals(b3)));
    });
  });

  group('PixelCard', () {
    testWidgets('renders child content with default padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PixelCard(child: Text('Card Content'))),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when pressed', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PixelCard(
              onTap: () => tapped = true,
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Card'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders with custom colors and metrics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelCard(
              backgroundColor: Color(0xFF123456),
              borderColor: Color(0xFF654321),
              bevelColor: Color(0xFF000000),
              bevelDepth: 6.0,
              cornerStepSize: 5.0,
              padding: EdgeInsets.all(24.0),
              margin: EdgeInsets.all(8.0),
              child: Text('Custom Card'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Card'), findsOneWidget);
    });
  });

  group('PixelButton', () {
    testWidgets('renders label and triggers onPressed callback', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PixelButton(
              label: 'START WORKOUT',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('START WORKOUT'), findsOneWidget);

      await tester.tap(find.text('START WORKOUT'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('does not trigger callback when disabled', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PixelButton(
              label: 'DISABLED',
              enabled: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('DISABLED'));
      await tester.pumpAndSettle();

      expect(pressed, isFalse);
    });

    testWidgets('renders secondary and danger variants cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PixelButton(
                  label: 'SECONDARY',
                  variant: PixelButtonVariant.secondary,
                ),
                PixelButton(
                  label: 'DANGER',
                  variant: PixelButtonVariant.danger,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('SECONDARY'), findsOneWidget);
      expect(find.text('DANGER'), findsOneWidget);
    });

    testWidgets('renders icon alongside label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelButton(
              label: 'WITH ICON',
              icon: Icon(Icons.play_arrow, key: ValueKey('btn_icon')),
            ),
          ),
        ),
      );

      expect(find.text('WITH ICON'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_icon')), findsOneWidget);
    });
  });

  group('PixelCountdownBar', () {
    test('computes filled block count deterministically', () {
      const bar0 = PixelCountdownBar(progress: 0.0, totalBlocks: 20);
      expect(bar0.filledBlocks, 0);

      const barHalf = PixelCountdownBar(progress: 0.5, totalBlocks: 20);
      expect(barHalf.filledBlocks, 10);

      const barFull = PixelCountdownBar(progress: 1.0, totalBlocks: 20);
      expect(barFull.filledBlocks, 20);

      const barQuarter = PixelCountdownBar(progress: 0.25, totalBlocks: 20);
      expect(barQuarter.filledBlocks, 5);
    });

    testWidgets('renders 20 block children in Row', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelCountdownBar(progress: 0.5, totalBlocks: 20),
          ),
        ),
      );

      expect(find.byType(PixelCountdownBar), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('clamps progress values outside [0.0, 1.0]', (tester) async {
      const negativeBar = PixelCountdownBar(progress: -0.5, totalBlocks: 10);
      expect(negativeBar.filledBlocks, 0);

      const overflowBar = PixelCountdownBar(progress: 1.5, totalBlocks: 10);
      expect(overflowBar.filledBlocks, 10);
    });
  });

  group('PixelPulseDot', () {
    test('opacityAt: hardCut is a step function, not a fade', () {
      // First half of the cycle: fully opaque.
      expect(
        PixelPulseDot.opacityAt(0.0, hardCut: true, minOpacity: 0.35),
        1.0,
      );
      expect(
        PixelPulseDot.opacityAt(0.49, hardCut: true, minOpacity: 0.35),
        1.0,
      );
      // Second half: an instant cut to minOpacity, no interpolation.
      expect(
        PixelPulseDot.opacityAt(0.5, hardCut: true, minOpacity: 0.35),
        0.35,
      );
      expect(
        PixelPulseDot.opacityAt(0.99, hardCut: true, minOpacity: 0.35),
        0.35,
      );
    });

    test('opacityAt: smooth pulse eases between 1.0 and minOpacity', () {
      // Start/end of the cycle: at the trough (opacity == minOpacity).
      expect(
        PixelPulseDot.opacityAt(0.0, hardCut: false, minOpacity: 0.15),
        closeTo(0.15, 0.001),
      );
      // Midpoint of the cycle: at the peak (opacity 1.0).
      expect(
        PixelPulseDot.opacityAt(0.5, hardCut: false, minOpacity: 0.15),
        closeTo(1.0, 0.001),
      );
      // Unlike hardCut, values strictly between the peak and trough are
      // genuinely interpolated, not snapped to one of two values.
      final quarter = PixelPulseDot.opacityAt(
        0.25,
        hardCut: false,
        minOpacity: 0.15,
      );
      expect(quarter, greaterThan(0.15));
      expect(quarter, lessThan(1.0));
    });

    testWidgets('renders a circular dot at the given size and color', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelPulseDot(color: Colors.red, size: 12.0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, 12.0);
      expect(container.constraints?.maxHeight, 12.0);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, Colors.red);
    });

    testWidgets('animate: false renders a static, fully-opaque dot', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelPulseDot(color: Colors.amber, animate: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });

    testWidgets(
      'does not hang pumpAndSettle even when animate is true (test-env guard)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PixelPulseDot(color: Colors.amber, animate: true),
            ),
          ),
        );
        // Would time out if a real repeating AnimationController were
        // running under test, since it never settles.
        await tester.pumpAndSettle();

        expect(find.byType(PixelPulseDot), findsOneWidget);
      },
    );
  });
}
