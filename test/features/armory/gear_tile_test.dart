import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/features/armory/widgets/gear_tile.dart';

void main() {
  testWidgets(
    'press-release spring animation actually animates the drop offset across ticks',
    (tester) async {
      // Regression coverage: dropOffset used to be computed once outside
      // AnimatedBuilder.builder from _springAnimation.value, so it stayed
      // frozen at whatever value it had during the last full build() instead
      // of updating every animation tick.
      await tester.pumpWidget(
        MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: Scaffold(
            body: GearTile(
              equipment: Equipment.bands,
              isEquipped: false,
              onToggle: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GearTile)),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Sample the rendered Transform's offset at two different points
      // during the 200ms spring-rebound animation.
      double readOffsetDy() {
        final transform = tester.widget<Transform>(
          find
              .descendant(
                of: find.byType(GearTile),
                matching: find.byType(Transform),
              )
              .first,
        );
        return transform.transform.getTranslation().y;
      }

      final early = readOffsetDy();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = readOffsetDy();
      await tester.pump(const Duration(milliseconds: 100));
      final settled = readOffsetDy();

      expect(
        early,
        isNot(equals(mid)),
        reason:
            'drop offset must change as the spring animation ticks, not stay frozen',
      );
      expect(
        settled,
        closeTo(0.0, 0.01),
        reason: 'tile should have fully rebounded to its resting position',
      );
    },
  );
}
