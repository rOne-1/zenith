import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/main.dart';

void main() {
  testWidgets(
    'ZenithApp smoke test renders landing shell and initiates dispatch',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            sbeeDatabaseProvider.overrideWithValue(
              SbeeDatabase(NativeDatabase.memory()),
            ),
          ],
          child: const ZenithApp(),
        ),
      );

      // Initial frame
      await tester.pumpAndSettle();

      // Verify header and district identity
      expect(find.text('ZENITH // 頂点'), findsOneWidget);
      expect(find.textContaining('RAILSIDE OUTSKIRTS'), findsOneWidget);
      expect(find.text('SECTOR 01'), findsOneWidget);

      // Verify engine status card
      expect(find.text('SBEE ENGINE CORE // ONLINE'), findsOneWidget);
      expect(find.text('INITIATE EXPEDITION'), findsOneWidget);

      // Tap initiate expedition button
      await tester.tap(find.text('INITIATE EXPEDITION'));
      await tester.pump();

      // Let the generation future resolve
      await tester.pumpAndSettle();

      // Verify dispatch feedback displays
      expect(find.textContaining('DISPATCH PREPARED'), findsOneWidget);
    },
  );
}
