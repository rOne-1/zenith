import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/core/theme/theme.dart';
import 'package:zenith/engine/engine.dart';
import 'package:zenith/features/armory/armory.dart';
import 'package:zenith/features/expedition/expedition.dart';

/// Regression coverage for a reported bug: "equipment-gated exercises are
/// generated even when not selected in the Depot" (repro: toggling towel
/// off still produced 'Towel Door-Anchor Row'). Investigation traced the
/// full pipeline -- SbeeEngine.generateNextWorkout's equipment filter, the
/// catalog's declared equipmentRequirements, WorkoutPreviewService's cache
/// invalidation, and passive Riverpod ref.watch reactivity (the exact path
/// OutpostScreen relies on, with no explicit refreshPreview call) -- and
/// could not reproduce it in any of these three tests. Kept as permanent
/// regression coverage for the invariant either way, since it's directly
/// worth locking in regardless of whether the original report was hitting
/// a fourth, still-unidentified path (e.g. a resumed interrupted session,
/// which by design does NOT re-filter by current equipment).
void main() {
  test(
    'generateNextWorkout never includes an exercise requiring unavailable equipment',
    () async {
      final database = SbeeDatabase(NativeDatabase.memory());
      final sessionRepo = DriftSessionRepository(database);
      final progressionRepo = DriftProgressionRepository(database);
      final engine = SbeeEngine(
        sessionRepository: sessionRepo,
        progressionRepository: progressionRepo,
        exerciseGraph: expandedExerciseGraph,
      );

      for (var i = 0; i < 30; i++) {
        final workout = await engine.generateNextWorkout(
          userId: 'test_user',
          currentTime: DateTime(2026, 9, 8, 12, 0).add(Duration(days: i)),
          availableEquipment: const {Equipment.bodyweight},
        );
        for (final set in workout.sets) {
          expect(set.exerciseId, isNot('towel_row'));
        }
      }
      await database.close();
    },
  );

  test(
    'toggling equipment off and force-regenerating removes exercises requiring it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final database = SbeeDatabase(NativeDatabase.memory());

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => database.close());

      await container
          .read(userProfileProvider.notifier)
          .toggleEquipment(Equipment.towel);
      expect(
        container.read(userProfileProvider).availableEquipment,
        contains(Equipment.towel),
      );

      // Confirm towel_row CAN appear while towel is available (otherwise
      // the "never appears once removed" assertion below would be vacuous).
      var sawTowelRowWhileEnabled = false;
      for (var i = 0; i < 40 && !sawTowelRowWhileEnabled; i++) {
        final workout = await container
            .read(workoutPreviewProvider.notifier)
            .refreshPreview(
              currentTime: DateTime(2026, 9, 8, 12, 0).add(Duration(days: i)),
            );
        if (workout!.sets.any((s) => s.exerciseId == 'towel_row')) {
          sawTowelRowWhileEnabled = true;
        }
      }
      expect(
        sawTowelRowWhileEnabled,
        isTrue,
        reason: 'towel_row never appeared in 40 tries while towel was on',
      );

      await container
          .read(userProfileProvider.notifier)
          .toggleEquipment(Equipment.towel);
      expect(
        container.read(userProfileProvider).availableEquipment,
        isNot(contains(Equipment.towel)),
      );

      for (var i = 0; i < 40; i++) {
        final workout = await container
            .read(workoutPreviewProvider.notifier)
            .refreshPreview(
              currentTime: DateTime(2026, 9, 8, 12, 0).add(Duration(days: i)),
            );
        for (final set in workout!.sets) {
          expect(set.exerciseId, isNot('towel_row'));
        }
      }
    },
  );

  test(
    'passively watching workoutPreviewProvider (no explicit refresh) still '
    'reflects an equipment toggle -- the exact path OutpostScreen relies on',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final database = SbeeDatabase(NativeDatabase.memory());

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sbeeDatabaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(() => database.close());

      await container
          .read(userProfileProvider.notifier)
          .toggleEquipment(Equipment.towel);

      final firstWorkout = await container.read(workoutPreviewProvider.future);
      expect(firstWorkout, isNotNull);

      await container
          .read(userProfileProvider.notifier)
          .toggleEquipment(Equipment.towel);

      final secondWorkout = await container.read(workoutPreviewProvider.future);
      expect(secondWorkout, isNotNull);

      for (final set in secondWorkout!.sets) {
        expect(set.exerciseId, isNot('towel_row'));
      }
    },
  );
}
