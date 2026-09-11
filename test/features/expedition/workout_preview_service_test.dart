import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/armory/armory.dart';
import 'package:zenith/features/expedition/services/workout_preview_service.dart';

void main() {
  group('WorkoutPreviewService & workoutPreviewProvider', () {
    late SbeeDatabase database;
    late ProviderContainer container;
    late SharedPreferences prefs;

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

    test('generates workout preview when cache is empty', () async {
      final service = container.read(workoutPreviewServiceProvider);
      final profile = UserProfile.baseline;
      final now = DateTime(2026, 9, 8, 10, 0);

      expect(service.cachedSession, isNull);
      expect(service.isCacheValid(profile: profile, currentTime: now), isFalse);

      final session = await service.getOrGeneratePreview(
        profile: profile,
        currentTime: now,
      );

      expect(session, isNotNull);
      expect(session.sets, isNotEmpty);
      expect(service.cachedSession, equals(session));
      expect(service.isCacheValid(profile: profile, currentTime: now), isTrue);
    });

    test(
      'cache stays valid for a structurally-identical but differently-constructed femaleProfile',
      () async {
        // Regression coverage: isCacheValid used to compare FemaleProfile by
        // identity (it has no == of its own), so two instances with equal
        // field values but different identity -- e.g. one round-tripped
        // through UserProfile.fromJson -- would wrongly invalidate the
        // cache and force an unnecessary regeneration.
        final service = container.read(workoutPreviewServiceProvider);
        final now = DateTime(2026, 9, 8, 10, 0);

        final profileA = UserProfile(
          availableEquipment: const {Equipment.bodyweight},
          femaleProfile: const FemaleProfile(
            userStatus: 'Untrained_Female',
            cycleDay: 2,
            hasKneeDiscomfort: false,
            age: 25,
            hasJointPain: false,
          ),
        );
        await service.getOrGeneratePreview(profile: profileA, currentTime: now);

        // Round-tripping through JSON (as persistence does) constructs a
        // genuinely distinct, non-const FemaleProfile instance at runtime --
        // unlike two `const FemaleProfile(...)` literals, which Dart
        // canonicalizes to the same object and would pass `identical` even
        // with the bug present, defeating the point of this regression test.
        final profileB = UserProfile.fromJson(profileA.toJson());

        expect(
          identical(profileA.femaleProfile, profileB.femaleProfile),
          isFalse,
          reason: 'the two FemaleProfile instances must be distinct objects',
        );
        expect(
          service.isCacheValid(profile: profileB, currentTime: now),
          isTrue,
        );
      },
    );

    test(
      'returns identical cached session on subsequent calls within same calendar day',
      () async {
        final service = container.read(workoutPreviewServiceProvider);
        final profile = UserProfile.baseline;
        final morning = DateTime(2026, 9, 8, 8, 30);
        final evening = DateTime(2026, 9, 8, 20, 45);

        final first = await service.getOrGeneratePreview(
          profile: profile,
          currentTime: morning,
        );
        final second = await service.getOrGeneratePreview(
          profile: profile,
          currentTime: evening,
        );

        // Must be exact same object reference (no re-generation or random re-shuffling)
        expect(identical(first, second), isTrue);
        expect(first.id, equals(second.id));
      },
    );

    test('re-generates preview when calendar day rolls over', () async {
      final service = container.read(workoutPreviewServiceProvider);
      final profile = UserProfile.baseline;
      final day1 = DateTime(2026, 9, 8, 22, 0);
      final day2 = DateTime(2026, 9, 9, 7, 0);

      final sessionDay1 = await service.getOrGeneratePreview(
        profile: profile,
        currentTime: day1,
      );

      expect(
        service.isCacheValid(profile: profile, currentTime: day2),
        isFalse,
      );

      final sessionDay2 = await service.getOrGeneratePreview(
        profile: profile,
        currentTime: day2,
      );

      // Distinct objects and IDs across different days
      expect(identical(sessionDay1, sessionDay2), isFalse);
      expect(sessionDay2.id, isNot(equals(sessionDay1.id)));
      expect(
        service.cachedDay,
        equals(DateTime(day2.year, day2.month, day2.day)),
      );
    });

    test(
      're-generates preview when user profile equipment is modified in the Depot',
      () async {
        final service = container.read(workoutPreviewServiceProvider);
        final baseProfile = UserProfile.baseline;
        final now = DateTime(2026, 9, 8, 10, 0);

        final initialSession = await service.getOrGeneratePreview(
          profile: baseProfile,
          currentTime: now,
        );

        // User equips bands in the Depot
        final modifiedProfile = baseProfile.copyWith(
          availableEquipment: {Equipment.bodyweight, Equipment.bands},
        );

        expect(
          service.isCacheValid(profile: modifiedProfile, currentTime: now),
          isFalse,
        );

        final newSession = await service.getOrGeneratePreview(
          profile: modifiedProfile,
          currentTime: now,
        );

        // New session object generated
        expect(identical(initialSession, newSession), isFalse);
        expect(service.isCacheValid(profile: modifiedProfile, currentTime: now), isTrue);
      },
    );

    test('explicit invalidateCache clears cached preview', () async {
      final service = container.read(workoutPreviewServiceProvider);
      final profile = UserProfile.baseline;
      final now = DateTime(2026, 9, 8, 10, 0);

      await service.getOrGeneratePreview(profile: profile, currentTime: now);
      expect(service.cachedSession, isNotNull);

      service.invalidateCache();
      expect(service.cachedSession, isNull);
      expect(service.cachedDay, isNull);
      expect(service.isCacheValid(profile: profile, currentTime: now), isFalse);
    });

    test(
      'workoutPreviewProvider automatically reacts to userProfileProvider changes',
      () async {
        final fixedTime = DateTime(2026, 9, 8, 12, 0);
        final subDb = SbeeDatabase(NativeDatabase.memory());
        final overrideContainer = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            sbeeDatabaseProvider.overrideWithValue(subDb),
            currentClockProvider.overrideWithValue(() => fixedTime),
          ],
        );

        try {
          // First read initializes preview
          final initialSession = await overrideContainer.read(
            workoutPreviewProvider.future,
          );
          expect(initialSession, isNotNull);

          // Toggling equipment via notifier updates userProfileProvider
          await overrideContainer
              .read(userProfileProvider.notifier)
              .toggleEquipment(Equipment.pullUpBar);

          // Reading future again yields an updated session reflecting pullUpBar
          final updatedSession = await overrideContainer.read(
            workoutPreviewProvider.future,
          );
          expect(updatedSession, isNotNull);
          expect(identical(initialSession, updatedSession), isFalse);
        } finally {
          overrideContainer.dispose();
          await subDb.close();
        }
      },
    );
  });
}
