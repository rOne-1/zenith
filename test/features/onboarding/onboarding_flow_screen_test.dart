import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/app_shell.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/core/widgets/pixel_button.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/armory/armory.dart';
import 'package:zenith/features/onboarding/providers/onboarding_provider.dart';
import 'package:zenith/features/onboarding/screens/onboarding_flow_screen.dart';

void main() {
  group('OnboardingFlowScreen', () {
    late SbeeDatabase database;
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      database = SbeeDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(database),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    Widget createTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: zenithThemeRegistry.defaultTheme.themeData,
          home: const OnboardingFlowScreen(),
        ),
      );
    }

    testWidgets('starts on the welcome step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('WELCOME TO ZENITH'), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);
    });

    testWidgets(
      'selecting equipment on the equipment step updates the real profile',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('GET STARTED'));
        await tester.pumpAndSettle();

        expect(find.text('WHAT GEAR DO YOU HAVE?'), findsOneWidget);
        expect(
          container.read(userProfileProvider).availableEquipment,
          equals({Equipment.bodyweight}),
        );

        await tester.tap(find.text('Pull-up Bar'));
        await tester.pumpAndSettle();

        expect(
          container.read(userProfileProvider).availableEquipment,
          contains(Equipment.pullUpBar),
        );

        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();
        expect(find.text('ANY PHYSICAL CONSIDERATIONS?'), findsOneWidget);
      },
    );

    testWidgets(
      'toggling joint protection on the physiology step updates the real profile',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('GET STARTED'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SKIP')); // past equipment
        await tester.pumpAndSettle();

        expect(find.text('ANY PHYSICAL CONSIDERATIONS?'), findsOneWidget);
        expect(container.read(userProfileProvider).hasJointPain, isFalse);

        await tester.tap(find.text('JOINT PROTECTION'));
        await tester.pumpAndSettle();

        expect(container.read(userProfileProvider).hasJointPain, isTrue);

        await tester.tap(find.text('NEXT'));
        await tester.pumpAndSettle();
        expect(find.text('HOW EXPERIENCED ARE YOU?'), findsOneWidget);
      },
    );

    testWidgets('FINISH is disabled until an experience level is picked, then '
        'persists the choice and marks onboarding complete', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SKIP')); // past equipment
      await tester.pumpAndSettle();
      await tester.tap(find.text('SKIP')); // past physiology
      await tester.pumpAndSettle();

      expect(find.text('HOW EXPERIENCED ARE YOU?'), findsOneWidget);

      final finishButton = tester.widget<PixelButton>(
        find.byWidgetPredicate(
          (widget) => widget is PixelButton && widget.label == 'FINISH',
        ),
      );
      expect(
        finishButton.onPressed,
        isNull,
        reason: 'FINISH must be disabled with nothing selected yet',
      );

      await tester.tap(find.text('NEW TO TRAINING'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('FINISH'));
      await tester.pumpAndSettle();

      expect(
        container.read(userProfileProvider).experienceLevel,
        equals(ExperienceLevel.beginner),
      );
      expect(prefs.getBool(kHasCompletedOnboardingKey), isTrue);
      expect(find.byType(ZenithAppShell), findsOneWidget);
    });

    testWidgets(
      'skipping the experience step leaves experienceLevel unset but still '
      'completes onboarding',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('GET STARTED'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SKIP'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SKIP'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SKIP'));
        await tester.pumpAndSettle();

        expect(container.read(userProfileProvider).experienceLevel, isNull);
        expect(prefs.getBool(kHasCompletedOnboardingKey), isTrue);
        expect(find.byType(ZenithAppShell), findsOneWidget);
      },
    );
  });
}
