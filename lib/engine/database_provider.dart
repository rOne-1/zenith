import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sbee/sbee.dart';

/// Database file name for Zenith persistence.
const String kZenithDatabaseFileName = 'zenith_sbee.sqlite';

/// Creates a [QueryExecutor] appropriate for the current execution context.
///
/// In test environments or when [inMemory] is `true`, uses [NativeDatabase.memory].
/// In production, constructs a file-backed [LazyDatabase] pointing to the app's
/// documents directory.
QueryExecutor createDatabaseExecutor({
  bool inMemory = false,
  String dbName = kZenithDatabaseFileName,
}) {
  if (inMemory || Platform.environment.containsKey('FLUTTER_TEST')) {
    return NativeDatabase.memory();
  }

  return LazyDatabase(() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, dbName));
    return NativeDatabase.createInBackground(dbFile);
  });
}

/// Provider for the primary [SbeeDatabase] instance.
final sbeeDatabaseProvider = Provider<SbeeDatabase>((ref) {
  final executor = createDatabaseExecutor();
  final db = SbeeDatabase(executor);
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for the [SessionRepository] backed by Drift.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final db = ref.watch(sbeeDatabaseProvider);
  return DriftSessionRepository(db);
});

/// Provider for the [ProgressionRepository] backed by Drift.
final progressionRepositoryProvider = Provider<ProgressionRepository>((ref) {
  final db = ref.watch(sbeeDatabaseProvider);
  return DriftProgressionRepository(db);
});
