import 'dart:io';

import 'package:lessdo/data/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<AppDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  return AppDatabase.open(
    databaseFactory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
}

Future<TestDatabasePath> createTestDatabasePath() async {
  final directory = await Directory.systemTemp.createTemp('lessdo_test_');
  return TestDatabasePath(
    directory: directory,
    path: p.join(directory.path, 'lessdo.sqlite3'),
  );
}

class TestDatabasePath {
  const TestDatabasePath({required this.directory, required this.path});

  final Directory directory;
  final String path;

  Future<void> delete() => directory.delete(recursive: true);
}

Map<String, Object?> validTaskRow({
  required String id,
  String listId = 'inbox',
}) {
  return {
    'id': id,
    'title': 'Test task',
    'list_id': listId,
    'created_at_utc': 1,
    'updated_at_utc': 1,
    'priority': 'normal',
    'repeat_rule': 'none',
    'sort_order': 0,
  };
}
