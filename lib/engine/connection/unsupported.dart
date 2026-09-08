import 'package:drift/drift.dart';

/// Unsupported platform fallback executor.
QueryExecutor createDatabaseExecutor({
  bool inMemory = false,
  String dbName = 'zenith_sbee.sqlite',
}) {
  throw UnsupportedError('No database executor available for this platform.');
}
