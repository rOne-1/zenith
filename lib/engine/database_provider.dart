import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import 'connection/connection.dart' as conn;

/// Database file name for Zenith persistence.
const String kZenithDatabaseFileName = 'zenith_sbee.sqlite';

/// Creates a [QueryExecutor] appropriate for the current execution context.
QueryExecutor createDatabaseExecutor({
  bool inMemory = false,
  String dbName = kZenithDatabaseFileName,
}) {
  return conn.createDatabaseExecutor(inMemory: inMemory, dbName: dbName);
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
