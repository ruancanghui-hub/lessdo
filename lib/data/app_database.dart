import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqlite_api.dart';

class DatabaseIntegrityException implements Exception {
  const DatabaseIntegrityException(this.result);

  final Object? result;

  @override
  String toString() =>
      'DatabaseIntegrityException: quick_check returned '
      '${result ?? 'no result'}';
}

class AppDatabase {
  AppDatabase._(this._database);

  static const schemaVersion = 1;
  static const _databaseFileName = 'lessdo.sqlite3';

  final Database _database;
  bool _closed = false;

  static Future<AppDatabase> open({
    DatabaseFactory? databaseFactory,
    String? path,
  }) async {
    final factory = databaseFactory ?? sqflite.databaseFactory;
    final databasePath = path ?? await _productionPath();
    final database = await factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createSchema,
      ),
    );
    final appDatabase = AppDatabase._(database);

    try {
      await appDatabase._verifyIntegrity();
    } catch (_) {
      await appDatabase.close();
      rethrow;
    }

    return appDatabase;
  }

  static Future<String> _productionPath() async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, _databaseFileName);
  }

  static Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE task_lists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL CHECK(length(trim(name)) > 0),
        color_value INTEGER NOT NULL,
        kind TEXT NOT NULL CHECK(kind IN ('standard', 'grocery')),
        sort_order INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        list_id TEXT NOT NULL REFERENCES task_lists(id),
        created_at_utc INTEGER NOT NULL,
        updated_at_utc INTEGER NOT NULL,
        due_at_utc INTEGER,
        reminder_at_utc INTEGER,
        notes TEXT NOT NULL DEFAULT '',
        priority TEXT NOT NULL,
        repeat_rule TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        sort_order INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        completed_at_utc INTEGER,
        reminder_scheduling_failed INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await database.execute('''
      CREATE TABLE subtasks (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        completed INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE focus_history (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        task_title_snapshot TEXT NOT NULL,
        mode TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        completed_at_utc INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE active_focus (
        singleton INTEGER PRIMARY KEY CHECK(singleton = 1),
        payload_json TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX idx_tasks_list_order '
      'ON tasks(list_id, completed, sort_order)',
    );
    await database.execute(
      'CREATE INDEX idx_tasks_due ON tasks(completed, due_at_utc)',
    );
    await database.execute(
      'CREATE INDEX idx_tasks_reminder '
      'ON tasks(completed, reminder_at_utc)',
    );
    await database.insert('task_lists', {
      'id': 'inbox',
      'name': 'Inbox',
      'color_value': 0xFF6C7685,
      'kind': 'standard',
      'sort_order': 0,
    });
  }

  Future<void> _verifyIntegrity() async {
    final rows = await _database.rawQuery('PRAGMA quick_check');
    final result = rows.length == 1 ? rows.single.values.singleOrNull : null;
    if (result != 'ok') {
      throw DatabaseIntegrityException(result);
    }
  }

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) {
    return _database.rawQuery(sql, arguments);
  }

  Future<int> rawDelete(String sql, [List<Object?>? arguments]) {
    return _database.rawDelete(sql, arguments);
  }

  Future<int> insert(String table, Map<String, Object?> values) {
    return _database.insert(table, values);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction transaction) action) {
    return _database.transaction(action);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _database.close();
  }
}
