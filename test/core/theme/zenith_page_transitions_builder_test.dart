import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenith/core/theme/zenith_pixel_theme_builder.dart';

void main() {
  group('ZenithPageTransitionsBuilder', () {
    testWidgets(
      'push completes with a visible (non-zero) transition, not an instant cut',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
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

        expect(find.text('Home'), findsOneWidget);

        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Pushed')),
          ),
        );

        // One frame in: both routes are visible mid-transition -- this is
        // the actual regression check. An instant cut (zero-duration or a
        // broken transition) would already show only "Pushed" here, with
        // "Home" gone in the very first frame instead of fading/sliding out.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Pushed'), findsOneWidget);

        // Once fully settled, only the pushed route remains.
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsNothing);
        expect(find.text('Pushed'), findsOneWidget);
      },
    );

    testWidgets('pop completes and returns to the previous route', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
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
          builder: (_) => const Scaffold(body: Text('Pushed')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pushed'), findsOneWidget);

      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Pushed'), findsNothing);
    });
  });
}
