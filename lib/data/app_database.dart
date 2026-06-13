import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqlite_api.dart';

class DatabaseIntegrityException implements Exception {
  DatabaseIntegrityException.results(Iterable<String> messages)
    : messages = List<String>.unmodifiable(messages),
      causeType = null,
      closeFailureType = null;

  DatabaseIntegrityException.queryFailure(Object error)
    : messages = const [],
      causeType = error.runtimeType.toString(),
      closeFailureType = null;

  DatabaseIntegrityException._({
    required this.messages,
    required this.causeType,
    required this.closeFailureType,
  });

  final List<String> messages;
  final String? causeType;
  final String? closeFailureType;

  DatabaseIntegrityException withCloseFailure(Object error) {
    return DatabaseIntegrityException._(
      messages: messages,
      causeType: causeType,
      closeFailureType: error.runtimeType.toString(),
    );
  }

  @override
  String toString() {
    final details = messages.isNotEmpty
        ? 'quick_check returned ${messages.join('; ')}'
        : 'quick_check failed with ${causeType ?? 'unknown error'}';
    final closeDetails = closeFailureType == null
        ? ''
        : '; close failed with $closeFailureType';
    return 'DatabaseIntegrityException: $details$closeDetails';
  }
}

class AppDatabase {
  AppDatabase._(
    this._database,
    Future<void> Function(Database database) closeDatabase,
  ) : _closeDatabase = (() => closeDatabase(_database));

  static const schemaVersion = 2;
  static const _databaseFileName = 'lessdo.sqlite3';

  final Database _database;
  final Future<void> Function() _closeDatabase;
  Future<void>? _closeFuture;

  static Future<AppDatabase> open({
    DatabaseFactory? databaseFactory,
    String? path,
    Future<List<String>> Function(Database database)? integrityCheck,
    Future<void> Function(Database database)? closeDatabase,
  }) async {
    final factory = databaseFactory ?? sqflite.databaseFactory;
    final databasePath = path ?? await _productionPath();
    final database = await factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        singleInstance: false,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );
    final appDatabase = AppDatabase._(
      database,
      closeDatabase ?? ((database) => database.close()),
    );

    try {
      await appDatabase._verifyIntegrity(integrityCheck ?? _quickCheck);
    } on DatabaseIntegrityException catch (error) {
      try {
        await appDatabase.close();
      } catch (closeError) {
        throw error.withCloseFailure(closeError);
      }
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
        reminder_local_date TEXT,
        reminder_local_hour INTEGER,
        reminder_local_minute INTEGER,
        reminder_time_zone_id TEXT,
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
      CREATE TABLE notification_ids (
        task_id TEXT NOT NULL,
        occurrence_key TEXT NOT NULL,
        notification_id INTEGER NOT NULL UNIQUE,
        PRIMARY KEY(task_id, occurrence_key)
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
    await database.execute('''
      CREATE TRIGGER protect_inbox_before_delete
      BEFORE DELETE ON task_lists
      WHEN OLD.id = 'inbox'
      BEGIN
        SELECT RAISE(ABORT, 'Inbox cannot be deleted');
      END
    ''');
    await database.insert('task_lists', {
      'id': 'inbox',
      'name': 'Inbox',
      'color_value': 0xFF6C7685,
      'kind': 'standard',
      'sort_order': 0,
    });
  }

  static Future<void> _upgradeSchema(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion >= 2) return;
    await database.execute('ALTER TABLE tasks ADD reminder_local_date TEXT');
    await database.execute('ALTER TABLE tasks ADD reminder_local_hour INTEGER');
    await database.execute(
      'ALTER TABLE tasks ADD reminder_local_minute INTEGER',
    );
    await database.execute('ALTER TABLE tasks ADD reminder_time_zone_id TEXT');
    await database.execute('''
      CREATE TABLE notification_ids (
        task_id TEXT NOT NULL,
        occurrence_key TEXT NOT NULL,
        notification_id INTEGER NOT NULL UNIQUE,
        PRIMARY KEY(task_id, occurrence_key)
      )
    ''');
    final rows = await database.query(
      'tasks',
      columns: ['id', 'reminder_at_utc'],
      where: 'reminder_at_utc IS NOT NULL',
    );
    for (final row in rows) {
      final local = DateTime.fromMicrosecondsSinceEpoch(
        row['reminder_at_utc']! as int,
        isUtc: true,
      ).toLocal();
      await database.update(
        'tasks',
        {
          'reminder_local_date':
              '${local.year.toString().padLeft(4, '0')}-'
              '${local.month.toString().padLeft(2, '0')}-'
              '${local.day.toString().padLeft(2, '0')}',
          'reminder_local_hour': local.hour,
          'reminder_local_minute': local.minute,
          'reminder_time_zone_id': 'legacy-system-local',
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  static Future<List<String>> _quickCheck(Database database) async {
    final rows = await database.rawQuery('PRAGMA quick_check');
    return [
      for (final row in rows)
        for (final value in row.values) value.toString(),
    ];
  }

  Future<void> _verifyIntegrity(
    Future<List<String>> Function(Database database) integrityCheck,
  ) async {
    late final List<String> messages;
    try {
      messages = await integrityCheck(_database);
    } catch (error) {
      throw DatabaseIntegrityException.queryFailure(error);
    }
    if (messages.length != 1 || messages.single != 'ok') {
      throw DatabaseIntegrityException.results(messages);
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

  Future<void> close() => _closeFuture ??= Future<void>.sync(_closeDatabase);
}
