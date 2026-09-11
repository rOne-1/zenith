import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

/// Web database connection constructor powered by WebAssembly SQLite and web workers.
QueryExecutor createDatabaseExecutor({
  bool inMemory = false,
  String dbName = 'zenith_sbee.sqlite',
}) {
  if (inMemory) {
    return LazyDatabase(() async {
      final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
      sqlite3.registerVirtualFileSystem(
        InMemoryFileSystem(),
        makeDefault: true,
      );
      return WasmDatabase.inMemory(sqlite3);
    });
  }

  return LazyDatabase(() async {
    try {
      final result = await WasmDatabase.open(
        databaseName: dbName,
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    } catch (error, stackTrace) {
      // Fallback to in-memory WASM database if workers or OPFS are
      // unavailable. This must not be silent: a user's persisted training
      // history can otherwise appear to vanish (every write since going
      // in-memory is lost on reload) with nothing indicating why.
      // ignore: avoid_print
      print(
        'Zenith: persistent web database unavailable, falling back to '
        'in-memory storage (data will not persist across reloads): '
        '$error\n$stackTrace',
      );
      final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
      sqlite3.registerVirtualFileSystem(
        InMemoryFileSystem(),
        makeDefault: true,
      );
      return WasmDatabase.inMemory(sqlite3);
    }
  });
}
