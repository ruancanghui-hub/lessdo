import 'package:lessdo/data/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<AppDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  return AppDatabase.open(
    databaseFactory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
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
