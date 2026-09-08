import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenith/features/armory/armory.dart';

void main() {
  group('UserProfile Model Invariants & Serialization', () {
    test('Bodyweight is ALWAYS retained in availableEquipment', () {
      // 1. Explicit empty set
      final p1 = UserProfile(availableEquipment: {});
      expect(p1.availableEquipment, contains(Equipment.bodyweight));

      // 2. Explicit set without bodyweight
      final p2 = UserProfile(
        availableEquipment: {Equipment.pullUpBar, Equipment.bands},
      );
      expect(p2.availableEquipment, contains(Equipment.bodyweight));
      expect(p2.availableEquipment, contains(Equipment.pullUpBar));
      expect(p2.availableEquipment, contains(Equipment.bands));

      // 3. copyWith without bodyweight
      final p3 = p2.copyWith(availableEquipment: {Equipment.suspension});
      expect(p3.availableEquipment, contains(Equipment.bodyweight));
      expect(p3.availableEquipment, contains(Equipment.suspension));
      expect(p3.availableEquipment, isNot(contains(Equipment.pullUpBar)));
    });

    test(
      'toJson and fromJson serialize and deserialize round-trip accurately',
      () {
        const female = FemaleProfile(
          userStatus: 'Untrained_Female',
          cycleDay: 14,
          hasKneeDiscomfort: false,
          age: 30,
          hasJointPain: true,
        );

        final original = UserProfile(
          availableEquipment: {
            Equipment.bodyweight,
            Equipment.pullUpBar,
            Equipment.bands,
          },
          hasJointPain: true,
          femaleProfile: female,
        );

        final jsonMap = original.toJson();
        final jsonString = jsonEncode(jsonMap);
        final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final restored = UserProfile.fromJson(decodedMap);

        expect(restored, equals(original));
        expect(
          restored.availableEquipment,
          equals(original.availableEquipment),
        );
        expect(restored.hasJointPain, isTrue);
        expect(restored.hasCycleAutoregulation, isTrue);
        expect(restored.femaleProfile!.cycleDay, equals(14));
        expect(restored.femaleProfile!.age, equals(30));
      },
    );

    test('fromJson gracefully handles empty or corrupted equipment list', () {
      final restored = UserProfile.fromJson({
        'availableEquipment': ['invalid_gear', 'another_nonexistent'],
        'hasJointPain': false,
      });

      // Must still contain bodyweight
      expect(restored.availableEquipment, contains(Equipment.bodyweight));
      expect(restored.availableEquipment.length, equals(1));
    });
  });

  group('UserProfileNotifier State & Persistence', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Initializes with baseline profile when preferences are empty', () {
      final notifier = UserProfileNotifier(prefs);
      expect(notifier.state.availableEquipment, contains(Equipment.bodyweight));
      expect(notifier.state.hasJointPain, isFalse);
      expect(notifier.state.hasCycleAutoregulation, isFalse);
    });

    test(
      'Toggling equipment adds and removes gear, but bodyweight cannot be removed',
      () async {
        final notifier = UserProfileNotifier(prefs);

        // Attempt to toggle bodyweight (must be ignored)
        await notifier.toggleEquipment(Equipment.bodyweight);
        expect(
          notifier.state.availableEquipment,
          contains(Equipment.bodyweight),
        );

        // Toggle pullUpBar on
        await notifier.toggleEquipment(Equipment.pullUpBar);
        expect(
          notifier.state.availableEquipment,
          contains(Equipment.pullUpBar),
        );
        expect(
          notifier.state.availableEquipment,
          contains(Equipment.bodyweight),
        );

        // Verify immediate persistence in SharedPreferences
        final storedJson = prefs.getString(kUserProfileStorageKey);
        expect(storedJson, isNotNull);
        expect(storedJson, contains('pullUpBar'));

        // Toggle pullUpBar off
        await notifier.toggleEquipment(Equipment.pullUpBar);
        expect(
          notifier.state.availableEquipment,
          isNot(contains(Equipment.pullUpBar)),
        );
        expect(
          notifier.state.availableEquipment,
          contains(Equipment.bodyweight),
        );
      },
    );

    test(
      'Toggling joint protection updates flag and female profile sync',
      () async {
        final notifier = UserProfileNotifier(prefs);
        expect(notifier.state.hasJointPain, isFalse);

        await notifier.toggleJointProtection();
        expect(notifier.state.hasJointPain, isTrue);

        // Now enable cycle autoreg and toggle joint pain again
        await notifier.toggleCycleAutoregulation(cycleDay: 5, age: 26);
        expect(notifier.state.femaleProfile!.hasJointPain, isTrue);

        await notifier.toggleJointProtection();
        expect(notifier.state.hasJointPain, isFalse);
        expect(notifier.state.femaleProfile!.hasJointPain, isFalse);
      },
    );

    test(
      'Toggling cycle autoregulation adds and removes FemaleProfile',
      () async {
        final notifier = UserProfileNotifier(prefs);
        expect(notifier.state.hasCycleAutoregulation, isFalse);

        await notifier.toggleCycleAutoregulation(cycleDay: 3, age: 29);
        expect(notifier.state.hasCycleAutoregulation, isTrue);
        expect(notifier.state.femaleProfile!.cycleDay, equals(3));
        expect(notifier.state.femaleProfile!.age, equals(29));

        await notifier.toggleCycleAutoregulation();
        expect(notifier.state.hasCycleAutoregulation, isFalse);
        expect(notifier.state.femaleProfile, isNull);
      },
    );

    test('setCycleDay clamps day between 1 and 35', () async {
      final notifier = UserProfileNotifier(prefs);
      await notifier.toggleCycleAutoregulation(cycleDay: 10);

      await notifier.setCycleDay(40);
      expect(notifier.state.femaleProfile!.cycleDay, equals(35));

      await notifier.setCycleDay(-5);
      expect(notifier.state.femaleProfile!.cycleDay, equals(1));
    });
  });
}
