import 'dart:convert';

import 'package:sqflite/sqlite_api.dart';

import '../models/active_focus_session.dart';
import '../models/focus_session.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';
import '../notifications/reminder_schedule.dart';
import 'app_database.dart';
import 'task_repository.dart';

class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository(this._database);

  final AppDatabase _database;

  @override
  Future<RepositorySnapshot> loadSnapshot() {
    return _database.transaction(_loadSnapshot);
  }

  @override
  Future<List<TaskList>> loadLists() async {
    final rows = await _database.rawQuery(
      'SELECT * FROM task_lists ORDER BY sort_order, id',
    );
    return List.unmodifiable(rows.map(_listFromRow));
  }

  @override
  Future<List<TaskItem>> loadTasks() async {
    final taskRows = await _database.rawQuery(
      'SELECT * FROM tasks ORDER BY sort_order, id',
    );
    if (taskRows.isEmpty) return const [];

    final subtaskRows = await _database.rawQuery(
      'SELECT * FROM subtasks ORDER BY task_id, sort_order, id',
    );
    final subtasksByTask = <String, List<SubTask>>{};
    for (final row in subtaskRows) {
      subtasksByTask
          .putIfAbsent(row['task_id']! as String, () => [])
          .add(_subtaskFromRow(row));
    }

    return List.unmodifiable(
      taskRows.map(
        (row) => _taskFromRow(
          row,
          List.unmodifiable(subtasksByTask[row['id']] ?? const []),
        ),
      ),
    );
  }

  @override
  Future<List<FocusSession>> loadFocusHistory() async {
    final rows = await _database.rawQuery(
      'SELECT * FROM focus_history ORDER BY completed_at_utc DESC, id',
    );
    return List.unmodifiable(rows.map(_focusFromRow));
  }

  @override
  Future<ActiveFocusSession?> loadActiveFocus() async {
    final rows = await _database.rawQuery(
      'SELECT payload_json FROM active_focus WHERE singleton = 1',
    );
    if (rows.isEmpty) return null;
    final stored = Map<String, Object?>.from(
      jsonDecode(rows.single['payload_json']! as String) as Map,
    );
    return ActiveFocusSession.fromJson({
      ...stored,
      'startedAt': _dateFromMicros(
        stored['startedAtUtc']! as int,
      ).toIso8601String(),
      'pausedAt': _optionalDateFromMicros(
        stored['pausedAtUtc'],
      )?.toIso8601String(),
      'targetAt': _optionalDateFromMicros(
        stored['targetAtUtc'],
      )?.toIso8601String(),
    });
  }

  @override
  Future<void> saveTask(TaskItem task) {
    return _database.transaction((transaction) async {
      await _writeTask(transaction, task);
    });
  }

  @override
  Future<TaskItem?> patchReminderSchedulingState(
    String taskId,
    bool failed,
  ) async {
    return _database.transaction((transaction) async {
      final updated = await transaction.update(
        'tasks',
        {'reminder_scheduling_failed': failed ? 1 : 0},
        where: 'id = ?',
        whereArgs: [taskId],
      );
      if (updated == 0) return null;
      final rows = await transaction.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
      final subtaskRows = await transaction.query(
        'subtasks',
        where: 'task_id = ?',
        whereArgs: [taskId],
        orderBy: 'sort_order, id',
      );
      return _taskFromRow(
        rows.single,
        List.unmodifiable(subtaskRows.map(_subtaskFromRow)),
      );
    });
  }

  @override
  Future<int> notificationIdFor({
    required String taskId,
    required String occurrenceKey,
  }) {
    return _database.transaction((transaction) async {
      final existing = await transaction.query(
        'notification_ids',
        columns: ['notification_id'],
        where: 'task_id = ? AND occurrence_key = ?',
        whereArgs: [taskId, occurrenceKey],
      );
      if (existing.isNotEmpty) {
        return existing.single['notification_id']! as int;
      }
      var candidate = stableNotificationId(
        NotificationIdNamespace.task,
        taskId,
      );
      while (true) {
        final collision = await transaction.query(
          'notification_ids',
          columns: ['notification_id'],
          where: 'notification_id = ?',
          whereArgs: [candidate],
          limit: 1,
        );
        if (collision.isEmpty) {
          await transaction.insert('notification_ids', {
            'task_id': taskId,
            'occurrence_key': occurrenceKey,
            'notification_id': candidate,
          });
          return candidate;
        }
        candidate = candidate == 0x3fffffff ? 1 : candidate + 1;
      }
    });
  }

  @override
  Future<void> deleteTask(String taskId) {
    return _database.transaction((transaction) async {
      await transaction.delete(
        'notification_ids',
        where: 'task_id = ?',
        whereArgs: [taskId],
      );
      await transaction.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
    });
  }

  @override
  Future<void> saveList(TaskList list) {
    return _database.transaction((transaction) async {
      await transaction.insert(
        'task_lists',
        _listToRow(list),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<RepositorySnapshot> deleteList(
    String listId,
    ListDeletionStrategy strategy,
  ) {
    if (listId == 'inbox') {
      throw ArgumentError.value(listId, 'listId', 'Inbox cannot be deleted.');
    }
    return _database.transaction((transaction) async {
      switch (strategy) {
        case ListDeletionStrategy.moveToInbox:
          await transaction.update(
            'tasks',
            {'list_id': 'inbox'},
            where: 'list_id = ?',
            whereArgs: [listId],
          );
        case ListDeletionStrategy.deleteTasks:
          await transaction.delete(
            'notification_ids',
            where: 'task_id IN (SELECT id FROM tasks WHERE list_id = ?)',
            whereArgs: [listId],
          );
          await transaction.delete(
            'tasks',
            where: 'list_id = ?',
            whereArgs: [listId],
          );
      }
      await transaction.delete(
        'task_lists',
        where: 'id = ?',
        whereArgs: [listId],
      );
      return _loadSnapshot(transaction);
    });
  }

  @override
  Future<void> saveActiveFocus(ActiveFocusSession? session) {
    return _database.transaction((transaction) async {
      if (session == null) {
        await transaction.delete('active_focus', where: 'singleton = 1');
        return;
      }
      await transaction.insert('active_focus', {
        'singleton': 1,
        'payload_json': jsonEncode(_activeFocusToRow(session)),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> completeFocus(FocusSession history, {String? completedTaskId}) {
    return _database.transaction((transaction) async {
      await transaction.insert('focus_history', _focusToRow(history));
      if (completedTaskId != null) {
        final updated = await transaction.update(
          'tasks',
          {
            'completed': 1,
            'completed_at_utc': _micros(history.completedAt),
            'updated_at_utc': _micros(history.completedAt),
          },
          where: 'id = ?',
          whereArgs: [completedTaskId],
        );
        if (updated != 1) {
          throw StateError('Task $completedTaskId does not exist.');
        }
      }
      await transaction.delete('active_focus', where: 'singleton = 1');
    });
  }

  Future<void> _writeTask(Transaction transaction, TaskItem task) async {
    await transaction.insert(
      'tasks',
      _taskToRow(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    for (var index = 0; index < task.subtasks.length; index++) {
      await transaction.insert(
        'subtasks',
        _subtaskToRow(task.id, task.subtasks[index], index),
      );
    }
  }

  Future<RepositorySnapshot> _loadSnapshot(DatabaseExecutor executor) async {
    final listRows = await executor.query(
      'task_lists',
      orderBy: 'sort_order, id',
    );
    final taskRows = await executor.query('tasks', orderBy: 'sort_order, id');
    final subtaskRows = await executor.query(
      'subtasks',
      orderBy: 'task_id, sort_order, id',
    );
    final subtasksByTask = <String, List<SubTask>>{};
    for (final row in subtaskRows) {
      subtasksByTask
          .putIfAbsent(row['task_id']! as String, () => [])
          .add(_subtaskFromRow(row));
    }
    return RepositorySnapshot(
      lists: listRows.map(_listFromRow),
      tasks: taskRows.map(
        (row) => _taskFromRow(
          row,
          List.unmodifiable(subtasksByTask[row['id']] ?? const []),
        ),
      ),
    );
  }
}

Map<String, Object?> _listToRow(TaskList list) => {
  'id': list.id,
  'name': list.name,
  'color_value': list.colorValue,
  'kind': list.kind.name,
  'sort_order': list.sortOrder,
};

TaskList _listFromRow(Map<String, Object?> row) => TaskList(
  id: row['id']! as String,
  name: row['name']! as String,
  colorValue: row['color_value']! as int,
  kind: ListKind.values.byName(row['kind']! as String),
  sortOrder: row['sort_order']! as int,
);

Map<String, Object?> _taskToRow(TaskItem task) => {
  'id': task.id,
  'title': task.title,
  'list_id': task.listId,
  'created_at_utc': _micros(task.createdAt),
  'updated_at_utc': _micros(task.updatedAt),
  'due_at_utc': _optionalMicros(task.dueAt),
  'reminder_at_utc': _optionalMicros(task.reminderAt),
  'reminder_local_date': task.reminderAnchor?.localDate,
  'reminder_local_hour': task.reminderAnchor?.hour,
  'reminder_local_minute': task.reminderAnchor?.minute,
  'reminder_time_zone_id': task.reminderAnchor?.timeZoneId,
  'notes': task.notes,
  'priority': task.priority.name,
  'repeat_rule': task.repeatRule.name,
  'category': task.category,
  'sort_order': task.sortOrder,
  'completed': task.completed ? 1 : 0,
  'completed_at_utc': _optionalMicros(task.completedAt),
  'reminder_scheduling_failed': task.reminderSchedulingFailed ? 1 : 0,
};

TaskItem _taskFromRow(Map<String, Object?> row, List<SubTask> subtasks) {
  final localDate = row['reminder_local_date'] as String?;
  final localParts = localDate?.split('-').map(int.parse).toList();
  return TaskItem(
    id: row['id']! as String,
    title: row['title']! as String,
    listId: row['list_id']! as String,
    createdAt: _dateFromMicros(row['created_at_utc']! as int),
    updatedAt: _dateFromMicros(row['updated_at_utc']! as int),
    dueAt: _optionalDateFromMicros(row['due_at_utc']),
    reminderAt: _optionalDateFromMicros(row['reminder_at_utc']),
    reminderAnchor: localParts == null
        ? null
        : ReminderAnchor(
            year: localParts[0],
            month: localParts[1],
            day: localParts[2],
            hour: row['reminder_local_hour']! as int,
            minute: row['reminder_local_minute']! as int,
            timeZoneId: row['reminder_time_zone_id'] as String?,
          ),
    notes: row['notes']! as String,
    priority: TaskPriority.values.byName(row['priority']! as String),
    repeatRule: RepeatRule.values.byName(row['repeat_rule']! as String),
    category: row['category']! as String,
    subtasks: subtasks,
    completed: row['completed'] == 1,
    completedAt: _optionalDateFromMicros(row['completed_at_utc']),
    sortOrder: row['sort_order']! as int,
    reminderSchedulingFailed: row['reminder_scheduling_failed'] == 1,
  );
}

Map<String, Object?> _subtaskToRow(
  String taskId,
  SubTask subtask,
  int sortOrder,
) => {
  'id': subtask.id,
  'task_id': taskId,
  'title': subtask.title,
  'completed': subtask.completed ? 1 : 0,
  'sort_order': sortOrder,
};

SubTask _subtaskFromRow(Map<String, Object?> row) => SubTask(
  id: row['id']! as String,
  title: row['title']! as String,
  completed: row['completed'] == 1,
);

Map<String, Object?> _focusToRow(FocusSession session) => {
  'id': session.id,
  'task_id': session.taskId,
  'task_title_snapshot': session.taskTitle,
  'mode': session.mode.name,
  'duration_seconds': session.durationSeconds,
  'completed_at_utc': _micros(session.completedAt),
};

FocusSession _focusFromRow(Map<String, Object?> row) {
  final durationSeconds = row['duration_seconds']! as int;
  return FocusSession(
    id: row['id']! as String,
    taskId: row['task_id'] as String?,
    taskTitle: row['task_title_snapshot']! as String,
    minutes: durationSeconds ~/ 60,
    mode: FocusMode.values.byName(row['mode']! as String),
    durationSeconds: durationSeconds,
    completedAt: _dateFromMicros(row['completed_at_utc']! as int),
  );
}

Map<String, Object?> _activeFocusToRow(ActiveFocusSession session) => {
  'id': session.id,
  'taskId': session.taskId,
  'taskTitle': session.taskTitle,
  'mode': session.mode.name,
  'startedAtUtc': _micros(session.startedAt),
  'pausedAtUtc': _optionalMicros(session.pausedAt),
  'targetAtUtc': _optionalMicros(session.targetAt),
  'durationSeconds': session.durationSeconds,
  'accumulatedPausedMicroseconds': session.accumulatedPaused.inMicroseconds,
};

int _micros(DateTime value) => value.toUtc().microsecondsSinceEpoch;

int? _optionalMicros(DateTime? value) => value == null ? null : _micros(value);

DateTime _dateFromMicros(int value) =>
    DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true);

DateTime? _optionalDateFromMicros(Object? value) =>
    value == null ? null : _dateFromMicros(value as int);
