import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

/// Flushes [_fileSystem] after every transaction commit.
///
/// `IndexedDbFileSystem` caches writes in memory and persists them to
/// IndexedDB asynchronously "at some point" -- SQLite's own fsync (`xSync`)
/// is a no-op for this VFS, so nothing durably commits a write on its own.
/// Drift's own WASM delegate (`_WasmDelegate._runWithArgs`) does call
/// `flush()` after each statement, but only when `!isInTransaction` --
/// which is still `true` while the `COMMIT` statement itself runs (the flag
/// only flips to `false` *after* that statement returns), so the flush is
/// silently skipped for exactly the statement that matters most: the one
/// that ends a transaction. `SessionRepository.deleteSession()` runs inside
/// `db.transaction(...)`, so an aborted/discarded session's delete could
/// look like it succeeded (the transaction commits, the row disappears from
/// this session's queries) while never reaching IndexedDB at all --
/// resurrecting the "discarded" session on the next page load. Explicitly
/// flushing here closes that gap without depending on drift's internal
/// (buggy, as of drift 2.34.4) gating.
class _FlushOnCommitInterceptor extends QueryInterceptor {
  final IndexedDbFileSystem _fileSystem;

  _FlushOnCommitInterceptor(this._fileSystem);

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    await inner.send();
    await _fileSystem.flush();
  }
}

/// Web database connection constructor powered by WebAssembly SQLite.
///
/// Deliberately bypasses `WasmDatabase.open()`'s automatic OPFS/IndexedDB
/// probing (and the shared-worker architecture that comes with it) in favor
/// of directly managing an `IndexedDbFileSystem` this function keeps a
/// reference to -- that reference is what lets [_FlushOnCommitInterceptor]
/// force a flush after every transaction. `WasmDatabaseResult` (the return
/// type of `.open()`) exposes no such hook for any of the tiers it can
/// select, so there's no way to layer this fix on top of it. Zenith is a
/// single-tab, single-user app, so the multi-tab coordination and marginal
/// performance benefit of OPFS/shared-worker mode aren't worth trading away
/// a verified-correct persistence path for.
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
      final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
      final fileSystem = await IndexedDbFileSystem.open(dbName: dbName);
      sqlite3.registerVirtualFileSystem(fileSystem, makeDefault: true);

      final database = WasmDatabase(
        sqlite3: sqlite3,
        path: '/database',
        fileSystem: fileSystem,
      );
      return database.interceptWith(_FlushOnCommitInterceptor(fileSystem));
    } catch (error, stackTrace) {
      // Fallback to in-memory WASM database if IndexedDB is unavailable.
      // This must not be silent: a user's persisted training history can
      // otherwise appear to vanish (every write since going in-memory is
      // lost on reload) with nothing indicating why.
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
