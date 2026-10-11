import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Canonical schema URI for Zenith data archives.
const String kArchiveSchema = 'zenith://data-archive/v1';

/// Supported schema format version.
const int kArchiveVersion = 1;

/// Maximum allowable payload size (10MB) to protect against decompression bombs (CWE-20).
const int kMaxArchivePayloadBytes = 10 * 1024 * 1024;

/// Canonical container representing non-sensitive and sensitive user profile settings.
@immutable
class ArchiveProfileBundle {
  final Map<String, dynamic> nonSensitive;
  final Map<String, dynamic>? sensitive;

  const ArchiveProfileBundle({
    required this.nonSensitive,
    this.sensitive,
  });

  Map<String, dynamic> toJson() => {
    'nonSensitive': nonSensitive,
    if (sensitive != null) 'sensitive': sensitive,
  };

  factory ArchiveProfileBundle.fromJson(Map<String, dynamic> json) {
    return ArchiveProfileBundle(
      nonSensitive: Map<String, dynamic>.from(
        json['nonSensitive'] as Map? ?? {},
      ),
      sensitive: json['sensitive'] != null
          ? Map<String, dynamic>.from(json['sensitive'] as Map)
          : null,
    );
  }
}

/// Container representing non-sensitive user preferences and onboarding state.
@immutable
class ArchivePreferencesBundle {
  final String? activeDistrictId;
  final bool hasCompletedOnboarding;

  const ArchivePreferencesBundle({
    this.activeDistrictId,
    required this.hasCompletedOnboarding,
  });

  Map<String, dynamic> toJson() => {
    'activeDistrictId': activeDistrictId,
    'hasCompletedOnboarding': hasCompletedOnboarding,
  };

  factory ArchivePreferencesBundle.fromJson(Map<String, dynamic> json) {
    return ArchivePreferencesBundle(
      activeDistrictId: json['activeDistrictId'] as String?,
      hasCompletedOnboarding:
          json['hasCompletedOnboarding'] as bool? ?? true,
    );
  }
}

/// Container representing all relational Drift database tables in JSON format.
@immutable
class ArchiveDatabaseBundle {
  final List<Map<String, dynamic>> workoutSessions;
  final List<Map<String, dynamic>> workoutSets;
  final List<Map<String, dynamic>> exerciseProgressions;
  final List<Map<String, dynamic>> statusAchieved;

  const ArchiveDatabaseBundle({
    this.workoutSessions = const [],
    this.workoutSets = const [],
    this.exerciseProgressions = const [],
    this.statusAchieved = const [],
  });

  Map<String, dynamic> toJson() => {
    'workoutSessions': workoutSessions,
    'workoutSets': workoutSets,
    'exerciseProgressions': exerciseProgressions,
    'statusAchieved': statusAchieved,
  };

  factory ArchiveDatabaseBundle.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parseList(dynamic rawList) {
      if (rawList is! List) return [];
      return rawList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return ArchiveDatabaseBundle(
      workoutSessions: parseList(json['workoutSessions']),
      workoutSets: parseList(json['workoutSets']),
      exerciseProgressions: parseList(json['exerciseProgressions']),
      statusAchieved: parseList(json['statusAchieved']),
    );
  }
}

/// The top-level strongly typed Zenith Data Archive bundle.
@immutable
class ZenithArchiveBundle {
  final String schema;
  final int version;
  final DateTime exportedAt;
  final String appVersion;
  final String checksum;
  final ArchiveProfileBundle profile;
  final ArchivePreferencesBundle preferences;
  final ArchiveDatabaseBundle database;

  const ZenithArchiveBundle({
    this.schema = kArchiveSchema,
    this.version = kArchiveVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.checksum,
    required this.profile,
    required this.preferences,
    required this.database,
  });

  /// Serializes the bundle to a standard JSON map.
  Map<String, dynamic> toJson() => {
    r'$schema': schema,
    'version': version,
    'exportedAt': exportedAt.toIso8601String(),
    'appVersion': appVersion,
    'checksum': checksum,
    'profile': profile.toJson(),
    'preferences': preferences.toJson(),
    'database': database.toJson(),
  };

  /// Constructs a [ZenithArchiveBundle] from a JSON map.
  factory ZenithArchiveBundle.fromJson(Map<String, dynamic> json) {
    return ZenithArchiveBundle(
      schema: json[r'$schema'] as String? ?? '',
      version: json['version'] as int? ?? 0,
      exportedAt: json['exportedAt'] != null
          ? DateTime.parse(json['exportedAt'] as String)
          : DateTime.now(),
      appVersion: json['appVersion'] as String? ?? '0.0.0',
      checksum: json['checksum'] as String? ?? '',
      profile: ArchiveProfileBundle.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map? ?? {}),
      ),
      preferences: ArchivePreferencesBundle.fromJson(
        Map<String, dynamic>.from(json['preferences'] as Map? ?? {}),
      ),
      database: ArchiveDatabaseBundle.fromJson(
        Map<String, dynamic>.from(json['database'] as Map? ?? {}),
      ),
    );
  }

  /// Exports the bundle as a formatted JSON string.
  String toExportJsonString({bool pretty = true}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toJson());
    }
    return jsonEncode(toJson());
  }

  /// Produces a canonical string representation with keys recursively sorted,
  /// excluding the 'checksum' field, ensuring deterministic SHA-256 calculation.
  static String canonicalizeJsonString(Map<String, dynamic> jsonMap) {
    final canonicalMap = _canonicalize(jsonMap);
    return jsonEncode(canonicalMap);
  }

  static Object? _canonicalize(Object? object) {
    if (object is Map) {
      final sortedKeys = object.keys.map((k) => k.toString()).toList()..sort();
      final sortedMap = <String, Object?>{};
      for (final key in sortedKeys) {
        if (key == 'checksum') continue; // Exclude checksum from its own digest
        sortedMap[key] = _canonicalize(object[key]);
      }
      return sortedMap;
    } else if (object is List) {
      return object.map(_canonicalize).toList();
    } else {
      return object;
    }
  }

  /// Computes a SHA-256 hex checksum over canonicalized JSON contents.
  static Future<String> computeChecksum(Map<String, dynamic> jsonMap) async {
    final canonical = canonicalizeJsonString(jsonMap);
    final algorithm = Sha256();
    final hash = await algorithm.hash(utf8.encode(canonical));
    return hash.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Verifies whether the archive bundle's checksum matches the computed digest.
  static Future<bool> verifyChecksum(ZenithArchiveBundle bundle) async {
    final computed = await computeChecksum(bundle.toJson());
    return computed.toLowerCase() == bundle.checksum.toLowerCase();
  }
}
