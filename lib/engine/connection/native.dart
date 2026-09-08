import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Native (IO) database connection constructor for Android, iOS, Windows, macOS, and Linux.
QueryExecutor createDatabaseExecutor({
  bool inMemory = false,
  String dbName = 'zenith_sbee.sqlite',
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
