import 'dart:convert';
import 'package:sbee/sbee.dart';

import '../../armory/models/user_profile.dart';
import '../models/zenith_archive_bundle.dart';

/// Exception thrown when an archive bundle fails structural or semantic validation.
class ArchiveValidationException implements Exception {
  final String message;
  const ArchiveValidationException(this.message);

  @override
  String toString() => 'ArchiveValidationException: $message';
}

/// Comprehensive validator guarding archive deserialization against malformed payloads,
/// schema mismatches, CWE-20 injection, enum out-of-bounds, and physiological range violations.
class ArchiveValidator {
  const ArchiveValidator();

  /// Validates a raw JSON archive string and returns a sanitized, clamped [ZenithArchiveBundle].
  Future<ZenithArchiveBundle> validateJsonString(String rawJson) async {
    final byteLength = utf8.encode(rawJson).length;
    if (byteLength > kMaxArchivePayloadBytes) {
      throw ArchiveValidationException(
        'Archive payload exceeds maximum allowable size of 10MB ($byteLength bytes).',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      throw ArchiveValidationException('Malformed JSON payload: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ArchiveValidationException(
        'Archive root must be a JSON object.',
      );
    }

    return validateBundleMap(decoded);
  }

  /// Validates an in-memory JSON map against archive specifications.
  Future<ZenithArchiveBundle> validateBundleMap(
    Map<String, dynamic> rawMap,
  ) async {
    // 1. Schema and Version Check
    final schema = rawMap[r'$schema'] as String?;
    if (schema != kArchiveSchema) {
      throw ArchiveValidationException(
        'Invalid or unsupported schema: "$schema". Expected "$kArchiveSchema".',
      );
    }

    final version = rawMap['version'] as int?;
    if (version != kArchiveVersion) {
      throw ArchiveValidationException(
        'Unsupported archive format version: $version. Expected $kArchiveVersion.',
      );
    }

    // 2. Parse initial bundle structure
    final bundle = ZenithArchiveBundle.fromJson(rawMap);

    // 3. Checksum verification
    if (bundle.checksum.isEmpty) {
      throw const ArchiveValidationException('Archive missing checksum digest.');
    }

    final isValidChecksum = await ZenithArchiveBundle.verifyChecksum(bundle);
    if (!isValidChecksum) {
      throw const ArchiveValidationException(
        'Archive checksum mismatch. The payload may be corrupted or modified.',
      );
    }

    // 4. Validate and sanitize profile
    final sanitizedProfile = _validateAndSanitizeProfile(bundle.profile);

    // 5. Validate database relational tables and enum bounds
    _validateDatabaseTables(bundle.database);

    return ZenithArchiveBundle(
      schema: bundle.schema,
      version: bundle.version,
      exportedAt: bundle.exportedAt,
      appVersion: bundle.appVersion,
      checksum: bundle.checksum,
      profile: sanitizedProfile,
      preferences: bundle.preferences,
      database: bundle.database,
    );
  }

  ArchiveProfileBundle _validateAndSanitizeProfile(
    ArchiveProfileBundle profile,
  ) {
    // Validate availableEquipment enum strings
    final rawEquipment = profile.nonSensitive['availableEquipment'];
    if (rawEquipment != null) {
      if (rawEquipment is! List) {
        throw const ArchiveValidationException(
          'Profile availableEquipment must be a list of strings.',
        );
      }
      final validEquipmentNames = Equipment.values.map((e) => e.name).toSet();
      for (final item in rawEquipment) {
        if (item is! String || !validEquipmentNames.contains(item)) {
          throw ArchiveValidationException(
            'Unrecognized equipment identifier: "$item".',
          );
        }
      }
    }

    // Validate experienceLevel if present
    final rawExperienceLevel = profile.nonSensitive['experienceLevel'];
    if (rawExperienceLevel != null) {
      if (rawExperienceLevel is! String) {
        throw const ArchiveValidationException(
          'Profile experienceLevel must be a string.',
        );
      }
      final validLevels = ExperienceLevel.values.map((e) => e.name).toSet();
      if (!validLevels.contains(rawExperienceLevel)) {
        throw ArchiveValidationException(
          'Unrecognized experience level: "$rawExperienceLevel".',
        );
      }
    }

    // Clamp physiological variables if sensitive telemetry is present
    Map<String, dynamic>? clampedSensitive;
    if (profile.sensitive != null) {
      clampedSensitive = Map<String, dynamic>.from(profile.sensitive!);
      final rawFemale = clampedSensitive['femaleProfile'];
      if (rawFemale != null && rawFemale is Map) {
        final sanitizedFemale = Map<String, dynamic>.from(rawFemale);
        if (sanitizedFemale['cycleDay'] is num) {
          final day = (sanitizedFemale['cycleDay'] as num).toInt();
          sanitizedFemale['cycleDay'] = day.clamp(1, 35);
        }
        if (sanitizedFemale['age'] is num) {
          final age = (sanitizedFemale['age'] as num).toInt();
          sanitizedFemale['age'] = age.clamp(1, 120);
        }
        clampedSensitive['femaleProfile'] = sanitizedFemale;
      }
    }

    return ArchiveProfileBundle(
      nonSensitive: profile.nonSensitive,
      sensitive: clampedSensitive,
    );
  }

  void _validateDatabaseTables(ArchiveDatabaseBundle database) {
    final sessionIds = <String>{};
    for (final session in database.workoutSessions) {
      final id = session['id'];
      if (id is! String || id.isEmpty) {
        throw const ArchiveValidationException(
          'Workout session missing valid string ID.',
        );
      }
      sessionIds.add(id);

      // Validate DayType enum bounds if present
      final dayTypeOrdinal = session['dayType'];
      if (dayTypeOrdinal != null) {
        if (dayTypeOrdinal is! int ||
            dayTypeOrdinal < 0 ||
            dayTypeOrdinal >= DayType.values.length) {
          throw ArchiveValidationException(
            'Workout session "$id" contains out-of-bounds dayType: $dayTypeOrdinal.',
          );
        }
      }
    }

    for (final set in database.workoutSets) {
      final setId = set['id'];
      if (setId is! String || setId.isEmpty) {
        throw const ArchiveValidationException(
          'Workout set missing valid string ID.',
        );
      }

      final sessionId = set['sessionId'];
      if (sessionId is! String || sessionId.isEmpty) {
        throw ArchiveValidationException(
          'Workout set "$setId" missing valid sessionId.',
        );
      }

      // Referential integrity check against sessions
      if (sessionIds.isNotEmpty && !sessionIds.contains(sessionId)) {
        throw ArchiveValidationException(
          'Referential integrity violation: Workout set "$setId" references missing sessionId "$sessionId".',
        );
      }

      // Validate MovementPattern enum bounds
      final patternOrdinal = set['movementPattern'];
      if (patternOrdinal is! int ||
          patternOrdinal < 0 ||
          patternOrdinal >= MovementPattern.values.length) {
        throw ArchiveValidationException(
          'Workout set "$setId" contains out-of-bounds movementPattern: $patternOrdinal.',
        );
      }
    }
  }
}
