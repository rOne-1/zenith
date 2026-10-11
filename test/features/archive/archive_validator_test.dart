import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbee/sbee.dart';
import 'package:zenith/features/archive/models/zenith_archive_bundle.dart';
import 'package:zenith/features/archive/services/archive_validator.dart';

void main() {
  group('ArchiveValidator Tests', () {
    const validator = ArchiveValidator();

    Future<Map<String, dynamic>> createValidRawBundle() async {
      final now = DateTime.utc(2026, 10, 11, 10, 0, 0);
      final rawMap = <String, dynamic>{
        r'$schema': kArchiveSchema,
        'version': kArchiveVersion,
        'exportedAt': now.toIso8601String(),
        'appVersion': '0.9.0',
        'checksum': '',
        'profile': {
          'nonSensitive': {
            'availableEquipment': [Equipment.bodyweight.name, Equipment.pullUpBar.name],
            'experienceLevel': 'beginner',
          },
          'sensitive': {
            'hasJointPain': false,
            'femaleProfile': {
              'userStatus': 'Untrained_Female',
              'cycleDay': 14,
              'hasKneeDiscomfort': false,
              'age': 28,
              'hasJointPain': false,
            },
          },
        },
        'preferences': {
          'activeDistrictId': 'district_01_railside_outskirts',
          'hasCompletedOnboarding': true,
        },
        'database': {
          'workoutSessions': [
            {
              'id': 'session-101',
              'startTime': now.toIso8601String(),
              'endTime': now.add(const Duration(minutes: 45)).toIso8601String(),
              'isCompleted': true,
              'dayType': DayType.moderate.index,
            },
          ],
          'workoutSets': [
            {
              'id': 'set-101-1',
              'sessionId': 'session-101',
              'exerciseId': 'pushup_standard',
              'movementPattern': MovementPattern.pushing.index,
              'setNumber': 1,
              'reps': 10,
              'targetRpe': 7,
              'reportedRpe': 7,
              'loadVal': 0,
              'bodyPosition': 1,
              'rom': 1,
              'height': 0,
              'tempo': 1,
              'timestamp': now.toIso8601String(),
            },
          ],
          'exerciseProgressions': [],
          'statusAchieved': [],
        },
      };

      final checksum = await ZenithArchiveBundle.computeChecksum(rawMap);
      rawMap['checksum'] = checksum;
      return rawMap;
    }

    test('valid v1 archive validates successfully', () async {
      final rawBundle = await createValidRawBundle();
      final jsonString = jsonEncode(rawBundle);

      final bundle = await validator.validateJsonString(jsonString);

      expect(bundle.schema, equals(kArchiveSchema));
      expect(bundle.version, equals(1));
      expect(bundle.appVersion, equals('0.9.0'));
      expect(bundle.profile.nonSensitive['availableEquipment'], contains('pullUpBar'));
      expect(bundle.database.workoutSessions.length, equals(1));
      expect(bundle.database.workoutSets.length, equals(1));
    });

    test('tampered payload fails checksum verification', () async {
      final rawBundle = await createValidRawBundle();
      // Corrupt data without updating checksum
      (rawBundle['preferences'] as Map<String, dynamic>)['hasCompletedOnboarding'] = false;
      final jsonString = jsonEncode(rawBundle);

      expect(
        () => validator.validateJsonString(jsonString),
        throwsA(
          isA<ArchiveValidationException>().having(
            (e) => e.message,
            'message',
            contains('checksum mismatch'),
          ),
        ),
      );
    });

    test('missing or unsupported schema throws ArchiveValidationException', () async {
      final rawBundle = await createValidRawBundle();
      rawBundle[r'$schema'] = 'zenith://invalid-schema';
      rawBundle['checksum'] = await ZenithArchiveBundle.computeChecksum(rawBundle);
      final jsonString = jsonEncode(rawBundle);

      expect(
        () => validator.validateJsonString(jsonString),
        throwsA(
          isA<ArchiveValidationException>().having(
            (e) => e.message,
            'message',
            contains('Invalid or unsupported schema'),
          ),
        ),
      );
    });

    test('unsupported version throws ArchiveValidationException', () async {
      final rawBundle = await createValidRawBundle();
      rawBundle['version'] = 99;
      rawBundle['checksum'] = await ZenithArchiveBundle.computeChecksum(rawBundle);
      final jsonString = jsonEncode(rawBundle);

      expect(
        () => validator.validateJsonString(jsonString),
        throwsA(
          isA<ArchiveValidationException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported archive format version'),
          ),
        ),
      );
    });

    test('payload exceeding 10MB throws ArchiveValidationException', () async {
      final hugeString = ' ' * (kMaxArchivePayloadBytes + 10);
      expect(
        () => validator.validateJsonString(hugeString),
        throwsA(
          isA<ArchiveValidationException>().having(
            (e) => e.message,
            'message',
            contains('exceeds maximum allowable size'),
          ),
        ),
      );
    });

    test('out-of-bounds MovementPattern throws ArchiveValidationException', () async {
      final rawBundle = await createValidRawBundle();
      final sets = (rawBundle['database'] as Map<String, dynamic>)['workoutSets'] as List;
      sets[0]['movementPattern'] = 999;
      rawBundle['checksum'] = await ZenithArchiveBundle.computeChecksum(rawBundle);
      final jsonString = jsonEncode(rawBundle);

      expect(
        () => validator.validateJsonString(jsonString),
        throwsA(
          isA<ArchiveValidationException>().having(
            (e) => e.message,
            'message',
            contains('out-of-bounds movementPattern'),
          ),
        ),
      );
    });

    test('out-of-bounds DayType throws ArchiveValidationException', () async {
      final rawBundle = await createValidRawBundle();
      final sessions = (rawBundle['database'] as Map<String, dynamic>)['workoutSessions'] as List;
      sessions[0]['dayType'] = 999;
      rawBundle['checksum'] = await ZenithArchiveBundle.computeChecksum(rawBundle);
      final jsonString = jsonEncode(rawBundle);

      expect(
        () => validator.validateJsonString(jsonString),
        throwsA(
          isA<ArchiveValidationException>().having(
            (e) => e.message,
            'message',
            contains('out-of-bounds dayType'),
          ),
        ),
      );
    });

    test('referential integrity violation throws ArchiveValidationException', () async {
      final rawBundle = await createValidRawBundle();
      final sets = (rawBundle['database'] as Map<String, dynamic>)['workoutSets'] as List;
      sets[0]['sessionId'] = 'non-existent-session-id';
      rawBundle['checksum'] = await ZenithArchiveBundle.computeChecksum(rawBundle);
      final jsonString = jsonEncode(rawBundle);

      expect(
        () => validator.validateJsonString(jsonString),
        throwsA(
          isA<ArchiveValidationException>().having(
            (e) => e.message,
            'message',
            contains('Referential integrity violation'),
          ),
        ),
      );
    });

    test('clamps physiological parameters (cycleDay 1..35, age 1..120)', () async {
      final rawBundle = await createValidRawBundle();
      final sensitive = (rawBundle['profile'] as Map<String, dynamic>)['sensitive'] as Map<String, dynamic>;
      final female = sensitive['femaleProfile'] as Map<String, dynamic>;
      female['cycleDay'] = 99; // should clamp to 35
      female['age'] = 200; // should clamp to 120
      rawBundle['checksum'] = await ZenithArchiveBundle.computeChecksum(rawBundle);
      final jsonString = jsonEncode(rawBundle);

      final bundle = await validator.validateJsonString(jsonString);
      final validatedFemale = bundle.profile.sensitive!['femaleProfile'] as Map<String, dynamic>;
      expect(validatedFemale['cycleDay'], equals(35));
      expect(validatedFemale['age'], equals(120));
    });

    test('unrecognized equipment identifier throws ArchiveValidationException', () async {
      final rawBundle = await createValidRawBundle();
      final nonSensitive = (rawBundle['profile'] as Map<String, dynamic>)['nonSensitive'] as Map<String, dynamic>;
      nonSensitive['availableEquipment'] = ['bodyweight', 'antiGravityBoots'];
      rawBundle['checksum'] = await ZenithArchiveBundle.computeChecksum(rawBundle);
      final jsonString = jsonEncode(rawBundle);

      expect(
        () => validator.validateJsonString(jsonString),
        throwsA(
          isA<ArchiveValidationException>().having(
            (e) => e.message,
            'message',
            contains('Unrecognized equipment identifier'),
          ),
        ),
      );
    });

    test('unrecognized experience level throws ArchiveValidationException', () async {
      final rawBundle = await createValidRawBundle();
      final nonSensitive = (rawBundle['profile'] as Map<String, dynamic>)['nonSensitive'] as Map<String, dynamic>;
      nonSensitive['experienceLevel'] = 'olympian';
      rawBundle['checksum'] = await ZenithArchiveBundle.computeChecksum(rawBundle);
      final jsonString = jsonEncode(rawBundle);

      expect(
        () => validator.validateJsonString(jsonString),
        throwsA(
          isA<ArchiveValidationException>().having(
            (e) => e.message,
            'message',
            contains('Unrecognized experience level'),
          ),
        ),
      );
    });
  });
}
