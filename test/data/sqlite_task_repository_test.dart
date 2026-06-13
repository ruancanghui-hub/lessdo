import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/data/app_database.dart';
import 'package:lessdo/data/sqlite_task_repository.dart';
import 'package:lessdo/data/task_repository.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';

import '../support/test_database.dart';

void main() {
  late AppDatabase database;
  late SqliteTaskRepository repository;

  setUp(() async {
    database = await openTestDatabase();
    repository = SqliteTaskRepository(database);
  });

  tearDown(() => database.close());

  test('new repository is empty except for Inbox', () async {
    expect(await repository.loadTasks(), isEmpty);
    expect((await repository.loadLists()).map((list) => list.id), ['inbox']);
  });

  test('save and load preserve every list, task, and subtask field', () async {
    const list = TaskList(
      id: 'work',
      name: 'Work',
      colorValue: 0xFF123456,
      kind: ListKind.grocery,
      sortOrder: 7,
    );
    final task = TaskItem(
      id: 'task-1',
      title: 'Ship release',
      listId: list.id,
      createdAt: DateTime.utc(2026, 6, 13, 1, 2, 3, 4, 5),
      updatedAt: DateTime.utc(2026, 6, 14, 2, 3, 4, 5, 6),
      dueAt: DateTime.utc(2026, 6, 15, 3, 4, 5, 6, 7),
      reminderAt: DateTime.utc(2026, 6, 15, 2, 4, 5, 6, 8),
      notes: 'All fields survive SQLite.',
      priority: TaskPriority.high,
      repeatRule: RepeatRule.monthly,
      category: 'Release',
      subtasks: const [
        SubTask(id: 'subtask-2', title: 'Second', completed: true),
        SubTask(id: 'subtask-1', title: 'First'),
      ],
      completed: true,
      completedAt: DateTime.utc(2026, 6, 16, 4, 5, 6, 7, 9),
      sortOrder: 11,
      reminderSchedulingFailed: true,
    );

    await repository.saveList(list);
    await repository.saveTask(task);

    final loadedList = (await repository.loadLists()).last;
    final loadedTask = (await repository.loadTasks()).single;
    expect(loadedList.toJson(), list.toJson());
    expect(loadedTask.toJson(), task.toJson());
  });

  test(
    'atomic reminder failure patch preserves concurrent task edits',
    () async {
      final original = _task('task-1');
      await repository.saveTask(original);
      await repository.saveTask(
        original.copyWith(
          title: 'Edited while reconciling',
          completed: true,
          completedAt: DateTime.utc(2026, 6, 14),
        ),
      );

      await repository.patchReminderSchedulingState('task-1', true);

      final loaded = (await repository.loadTasks()).single;
      expect(loaded.title, 'Edited while reconciling');
      expect(loaded.completed, isTrue);
      expect(loaded.reminderSchedulingFailed, isTrue);
    },
  );

  test(
    'collision allocation is distinct and stable after repository restart',
    () async {
      final first = await repository.notificationIdFor(
        taskId: 'task-83969',
        occurrenceKey: 'daily',
      );
      final second = await repository.notificationIdFor(
        taskId: 'task-120024',
        occurrenceKey: 'daily',
      );
      final restarted = SqliteTaskRepository(database);

      expect(first, isNot(second));
      expect(
        await restarted.notificationIdFor(
          taskId: 'task-83969',
          occurrenceKey: 'daily',
        ),
        first,
      );
      expect(
        await restarted.notificationIdFor(
          taskId: 'task-120024',
          occurrenceKey: 'daily',
        ),
        second,
      );
    },
  );

  test('failed multi-row save rolls back task and subtasks', () async {
    final original = TaskItem.create(
      id: 'task-1',
      title: 'Original',
      listId: 'inbox',
      createdAt: DateTime.utc(2026),
      subtasks: const [SubTask(id: 'original-subtask', title: 'Keep me')],
    );
    await repository.saveTask(original);

    final invalidReplacement = original.copyWith(
      title: 'Replacement',
      subtasks: const [
        SubTask(id: 'duplicate', title: 'One'),
        SubTask(id: 'duplicate', title: 'Two'),
      ],
    );

    await expectLater(
      repository.saveTask(invalidReplacement),
      throwsA(anything),
    );

    expect((await repository.loadTasks()).single.toJson(), original.toJson());
  });

  test('updating a list preserves its existing tasks', () async {
    const original = TaskList(
      id: 'work',
      name: 'Work',
      colorValue: 1,
      sortOrder: 1,
    );
    await repository.saveList(original);
    await repository.saveTask(_task('task-1', listId: original.id));

    await repository.saveList(
      original.copyWith(name: 'Renamed', colorValue: 2),
    );

    expect((await repository.loadLists()).last.name, 'Renamed');
    expect((await repository.loadTasks()).single.listId, original.id);
  });

  test('deleting a list can atomically move its tasks to Inbox', () async {
    await repository.saveList(
      const TaskList(id: 'work', name: 'Work', colorValue: 1, sortOrder: 1),
    );
    await repository.saveTask(_task('task-1', listId: 'work'));

    final snapshot = await repository.deleteList(
      'work',
      ListDeletionStrategy.moveToInbox,
    );

    expect(snapshot.tasks.single.listId, 'inbox');
    expect(snapshot.lists.map((list) => list.id), ['inbox']);
  });

  test('deleting a list can atomically delete its tasks', () async {
    await repository.saveList(
      const TaskList(id: 'work', name: 'Work', colorValue: 1, sortOrder: 1),
    );
    await repository.saveTask(_task('task-1', listId: 'work'));

    final snapshot = await repository.deleteList(
      'work',
      ListDeletionStrategy.deleteTasks,
    );

    expect(snapshot.tasks, isEmpty);
    expect(snapshot.lists.map((list) => list.id), ['inbox']);
  });

  test('concurrent writes load in explicit deterministic order', () async {
    await Future.wait([
      repository.saveTask(_task('third', sortOrder: 30)),
      repository.saveTask(_task('first', sortOrder: 10)),
      repository.saveTask(_task('second', sortOrder: 20)),
    ]);

    expect((await repository.loadTasks()).map((task) => task.id), [
      'first',
      'second',
      'third',
    ]);
  });

  test('active focus and focus history preserve all fields', () async {
    final active = ActiveFocusSession.pomodoro(
      id: 'active-1',
      taskId: 'task-1',
      taskTitle: 'Deep work',
      startedAt: DateTime.utc(2026, 6, 13, 8),
      duration: const Duration(minutes: 25),
    ).pause(DateTime.utc(2026, 6, 13, 8, 10));
    final history = FocusSession(
      id: 'history-1',
      taskId: 'task-1',
      taskTitle: 'Deep work',
      minutes: 17,
      mode: FocusMode.countdown,
      durationSeconds: 1025,
      completedAt: DateTime.utc(2026, 6, 13, 8, 20, 0, 0, 321),
    );

    await repository.saveActiveFocus(active);
    expect((await repository.loadActiveFocus())?.toJson(), active.toJson());

    await repository.completeFocus(history);

    expect(await repository.loadActiveFocus(), isNull);
    expect(
      (await repository.loadFocusHistory()).single.toJson(),
      history.toJson(),
    );
  });

  test('completeFocus atomically completes its optional task', () async {
    await repository.saveTask(_task('task-1'));
    await repository.saveActiveFocus(
      ActiveFocusSession.countUp(
        id: 'active-1',
        taskId: 'task-1',
        taskTitle: 'Deep work',
        startedAt: DateTime.utc(2026, 6, 13, 8),
      ),
    );
    final history = FocusSession(
      id: 'history-1',
      taskId: 'task-1',
      taskTitle: 'Deep work',
      minutes: 1,
      mode: FocusMode.countUp,
      durationSeconds: 73,
      completedAt: DateTime.utc(2026, 6, 13, 8, 1, 13),
    );

    await repository.completeFocus(history, completedTaskId: 'task-1');

    final task = (await repository.loadTasks()).single;
    expect(task.completed, isTrue);
    expect(task.completedAt, history.completedAt);
    expect(await repository.loadActiveFocus(), isNull);
    expect(
      (await repository.loadFocusHistory()).single.toJson(),
      history.toJson(),
    );
  });

  test(
    'completeFocus rolls back task and active focus when history fails',
    () async {
      await repository.saveTask(_task('task-1'));
      final active = ActiveFocusSession.countUp(
        id: 'active-1',
        taskId: 'task-1',
        taskTitle: 'Deep work',
        startedAt: DateTime.utc(2026, 6, 13, 8),
      );
      await repository.saveActiveFocus(active);
      final history = FocusSession(
        id: 'history-1',
        taskId: 'task-1',
        taskTitle: 'Deep work',
        minutes: 1,
        completedAt: DateTime.utc(2026, 6, 13, 8, 1),
      );
      await repository.completeFocus(history);
      await repository.saveActiveFocus(active);

      await expectLater(
        repository.completeFocus(history, completedTaskId: 'task-1'),
        throwsA(anything),
      );

      expect((await repository.loadTasks()).single.completed, isFalse);
      expect((await repository.loadActiveFocus())?.toJson(), active.toJson());
      expect(await repository.loadFocusHistory(), hasLength(1));
    },
  );
}

TaskItem _task(String id, {String listId = 'inbox', int sortOrder = 0}) {
  return TaskItem.create(
    id: id,
    title: id,
    listId: listId,
    createdAt: DateTime.utc(2026),
    sortOrder: sortOrder,
  );
}
