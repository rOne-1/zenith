import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/pixel_loading_indicator.dart';
import 'package:zenith/core/widgets/pixel_pulse_dot.dart';
import 'package:zenith/core/widgets/zenith_dialog.dart';
import 'package:zenith/core/widgets/zenith_sheet.dart';

void main() {
  group('ZenithMotionContext Extension', () {
    testWidgets('evaluates motion duration and adaptive durations correctly when disableAnimations is false', (tester) async {
      late bool disabled;
      late Duration motionDur;
      late Duration adaptiveDur;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: false),
            child: Builder(
              builder: (context) {
                disabled = context.animationsDisabled;
                motionDur = context.motionDuration;
                adaptiveDur = context.adaptiveDuration(const Duration(milliseconds: 400));
                return const Placeholder();
              },
            ),
          ),
        ),
      );

      expect(disabled, isFalse);
      expect(motionDur, zenithMotionDuration);
      expect(adaptiveDur, const Duration(milliseconds: 400));
    });

    testWidgets('evaluates motion duration to Duration.zero when disableAnimations is true', (tester) async {
      late bool disabled;
      late Duration motionDur;
      late Duration adaptiveDur;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                disabled = context.animationsDisabled;
                motionDur = context.motionDuration;
                adaptiveDur = context.adaptiveDuration(const Duration(milliseconds: 400));
                return const Placeholder();
              },
            ),
          ),
        ),
      );

      expect(disabled, isTrue);
      expect(motionDur, Duration.zero);
      expect(adaptiveDur, Duration.zero);
    });
  });

  group('PixelPulseDot reduced motion', () {
    testWidgets('renders static fully opaque dot when disableAnimations is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: PixelPulseDot(color: Colors.cyan, animate: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });
  });

  group('PixelLoadingIndicator reduced motion', () {
    testWidgets('renders static illuminated blocks with zero active tickers when disableAnimations is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: PixelLoadingIndicator(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PixelLoadingIndicator), findsOneWidget);
    });
  });

  group('ZenithPageTransitionsBuilder reduced motion', () {
    testWidgets('bypasses transition animations and renders immediately when disableAnimations is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZenithPageTransitionsBuilder(),
              },
            ),
          ),
          home: const Scaffold(body: Text('Home')),
        ),
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('InstantPushed')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      // With disableAnimations: true, ZenithPageTransitionsBuilder returns child without slide/fade transitions.
      expect(find.text('InstantPushed'), findsOneWidget);
      expect(find.byType(SlideTransition), findsNothing);
    });
  });

  group('ZenithDialog and ZenithSheet reduced motion', () {
    testWidgets('ZenithDialog opens cleanly when disableAnimations is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      ZenithDialog.show<void>(
                        context,
                        builder: (_) => const Text('DialogContent'),
                      );
                    },
                    child: const Text('OpenDialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OpenDialog'));
      await tester.pump();
      expect(find.text('DialogContent'), findsOneWidget);
    });

    testWidgets('ZenithSheet opens cleanly when disableAnimations is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      ZenithSheet.show<void>(
                        context,
                        builder: (_) => const Text('SheetContent'),
                      );
                    },
                    child: const Text('OpenSheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OpenSheet'));
      await tester.pump();
      expect(find.text('SheetContent'), findsOneWidget);
    });
  });
}
