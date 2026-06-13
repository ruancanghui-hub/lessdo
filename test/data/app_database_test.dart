import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/data/app_database.dart';

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

  test('creates the complete version 1 schema', () async {
    final rows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );

    expect(rows.map((row) => row['name']), [
      'active_focus',
      'focus_history',
      'subtasks',
      'task_lists',
      'tasks',
    ]);
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

  test('close is safe to call more than once', () async {
    await database.close();
    await database.close();
  });
}
