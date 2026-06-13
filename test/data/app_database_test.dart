import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/data/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() async => database = await openTestDatabase());
  tearDown(() => database.close());

  test('creates only the protected Inbox on first launch', () async {
    final rows = await database.rawQuery(
      'SELECT id, name FROM task_lists ORDER BY sort_order',
    );

    expect(rows, [
      {'id': 'inbox', 'name': 'Inbox'},
    ]);
    expect(await database.rawQuery('SELECT id FROM tasks'), isEmpty);
  });

  test('creates the complete version 2 schema', () async {
    final rows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );

    expect(rows.map((row) => row['name']), [
      'active_focus',
      'focus_history',
      'notification_ids',
      'subtasks',
      'task_lists',
      'tasks',
    ]);
  });

  test('upgrades version 1 without losing tasks', () async {
    final testPath = await createTestDatabasePath();
    final legacy = await databaseFactoryFfi.openDatabase(
      testPath.path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE task_lists (
              id TEXT PRIMARY KEY, name TEXT NOT NULL, color_value INTEGER NOT NULL,
              kind TEXT NOT NULL, sort_order INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE tasks (
              id TEXT PRIMARY KEY, title TEXT NOT NULL, list_id TEXT NOT NULL,
              created_at_utc INTEGER NOT NULL, updated_at_utc INTEGER NOT NULL,
              due_at_utc INTEGER, reminder_at_utc INTEGER, notes TEXT NOT NULL,
              priority TEXT NOT NULL, repeat_rule TEXT NOT NULL, category TEXT NOT NULL,
              sort_order INTEGER NOT NULL, completed INTEGER NOT NULL,
              completed_at_utc INTEGER, reminder_scheduling_failed INTEGER NOT NULL
            )
          ''');
          await db.insert('task_lists', {
            'id': 'inbox',
            'name': 'Inbox',
            'color_value': 0,
            'kind': 'standard',
            'sort_order': 0,
          });
          await db.insert('tasks', {
            ...validTaskRow(id: 'legacy'),
            'notes': '',
            'category': '',
            'completed': 0,
            'reminder_scheduling_failed': 0,
          });
        },
      ),
    );
    await legacy.close();

    final upgraded = await AppDatabase.open(
      databaseFactory: databaseFactoryFfi,
      path: testPath.path,
    );

    expect(
      await upgraded.rawQuery('SELECT title FROM tasks WHERE id = ?', [
        'legacy',
      ]),
      [
        {'title': validTaskRow(id: 'legacy')['title']},
      ],
    );
    expect(await upgraded.rawQuery('SELECT * FROM notification_ids'), isEmpty);
    final columns = await upgraded.rawQuery('PRAGMA table_info(tasks)');
    expect(
      columns.map((row) => row['name']),
      containsAll([
        'reminder_local_date',
        'reminder_local_hour',
        'reminder_local_minute',
      ]),
    );

    await upgraded.close();
    await testPath.delete();
  });

  test('rolls back all records when a transaction fails', () async {
    await expectLater(
      database.transaction((txn) async {
        await txn.insert('tasks', validTaskRow(id: 'task-1'));
        await txn.insert('tasks', validTaskRow(id: 'task-2'));
        throw StateError('stop');
      }),
      throwsStateError,
    );

    expect(await database.rawQuery('SELECT id FROM tasks'), isEmpty);
  });

  test('foreign keys prevent an orphaned task', () async {
    await expectLater(
      database.insert('tasks', validTaskRow(id: 'task-1', listId: 'missing')),
      throwsA(anything),
    );
  });

  test('quick check reports a healthy database', () async {
    final rows = await database.rawQuery('PRAGMA quick_check');

    expect(rows, [
      {'quick_check': 'ok'},
    ]);
  });

  test('deleting a task cascades to its subtasks', () async {
    await database.insert('tasks', validTaskRow(id: 'task-1'));
    await database.insert('subtasks', {
      'id': 'subtask-1',
      'task_id': 'task-1',
      'title': 'Nested task',
      'sort_order': 0,
    });

    await database.rawDelete('DELETE FROM tasks WHERE id = ?', ['task-1']);

    expect(await database.rawQuery('SELECT id FROM subtasks'), isEmpty);
  });

  test('creates explicit task query indexes', () async {
    final rows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' "
      "AND name LIKE 'idx_tasks_%' ORDER BY name",
    );

    expect(rows.map((row) => row['name']), [
      'idx_tasks_due',
      'idx_tasks_list_order',
      'idx_tasks_reminder',
    ]);
  });

  test('closing one same-path database leaves the other usable', () async {
    final testPath = await createTestDatabasePath();
    final first = await AppDatabase.open(
      databaseFactory: databaseFactoryFfi,
      path: testPath.path,
    );
    final second = await AppDatabase.open(
      databaseFactory: databaseFactoryFfi,
      path: testPath.path,
    );

    await first.close();

    expect(await second.rawQuery('SELECT id FROM task_lists'), [
      {'id': 'inbox'},
    ]);

    await second.close();
    await testPath.delete();
  });

  test('protected Inbox cannot be deleted', () async {
    await expectLater(
      database.rawDelete("DELETE FROM task_lists WHERE id = 'inbox'"),
      throwsA(anything),
    );

    expect(await database.rawQuery('SELECT id FROM task_lists'), [
      {'id': 'inbox'},
    ]);
  });

  test('close is safe to call more than once', () async {
    await database.close();
    await database.close();
  });

  test('concurrent close calls share one underlying close future', () async {
    final closeCompleter = Completer<void>();
    var closeCalls = 0;
    final closeTestDatabase = await AppDatabase.open(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      closeDatabase: (database) async {
        closeCalls += 1;
        await closeCompleter.future;
        await database.close();
      },
    );

    final firstClose = closeTestDatabase.close();
    final secondClose = closeTestDatabase.close();

    expect(identical(firstClose, secondClose), isTrue);
    expect(closeCalls, 1);

    closeCompleter.complete();
    await Future.wait([firstClose, secondClose]);
  });

  test('failed close remains failed on later calls', () async {
    final closeError = StateError('close failed');
    var closeCalls = 0;
    final closeTestDatabase = await AppDatabase.open(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      closeDatabase: (database) async {
        closeCalls += 1;
        await database.close();
        throw closeError;
      },
    );

    final firstClose = closeTestDatabase.close();
    final secondClose = closeTestDatabase.close();

    expect(identical(firstClose, secondClose), isTrue);
    await expectLater(firstClose, throwsA(same(closeError)));
    await expectLater(secondClose, throwsA(same(closeError)));
    expect(closeCalls, 1);
  });

  test('runs the injected integrity check during startup', () async {
    var integrityChecks = 0;
    final checkedDatabase = await AppDatabase.open(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      integrityCheck: (_) async {
        integrityChecks += 1;
        return ['ok'];
      },
    );

    expect(integrityChecks, 1);

    await checkedDatabase.close();
  });

  test(
    'non-ok integrity results preserve messages and the database file',
    () async {
      final testPath = await createTestDatabasePath();
      var closeCalls = 0;

      await expectLater(
        AppDatabase.open(
          databaseFactory: databaseFactoryFfi,
          path: testPath.path,
          integrityCheck: (_) async => [
            'page 2 is never used',
            'row 3 missing from index',
          ],
          closeDatabase: (database) async {
            closeCalls += 1;
            await database.close();
          },
        ),
        throwsA(
          isA<DatabaseIntegrityException>().having(
            (error) => error.messages,
            'messages',
            ['page 2 is never used', 'row 3 missing from index'],
          ),
        ),
      );

      expect(closeCalls, 1);
      expect(File(testPath.path).existsSync(), isTrue);

      await testPath.delete();
    },
  );

  test(
    'integrity query errors become safe typed errors and close the database',
    () async {
      final testPath = await createTestDatabasePath();
      var closeCalls = 0;

      await expectLater(
        AppDatabase.open(
          databaseFactory: databaseFactoryFfi,
          path: testPath.path,
          integrityCheck: (_) async {
            throw ArgumentError('private task title');
          },
          closeDatabase: (database) async {
            closeCalls += 1;
            await database.close();
          },
        ),
        throwsA(
          isA<DatabaseIntegrityException>()
              .having((error) => error.causeType, 'causeType', 'ArgumentError')
              .having(
                (error) => error.toString(),
                'safe diagnostic',
                isNot(contains('private task title')),
              ),
        ),
      );

      expect(closeCalls, 1);
      expect(File(testPath.path).existsSync(), isTrue);

      await testPath.delete();
    },
  );
}
