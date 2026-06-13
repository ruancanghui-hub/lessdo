import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../models/active_focus_session.dart';
import '../models/app_settings.dart';
import '../models/focus_session.dart';
import '../models/smart_task_parser.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';
import '../services/platform_coordinators.dart';

class RepositoryReadException implements Exception {
  RepositoryReadException(this.operation, this.cause);

  final String operation;
  final Object cause;

  @override
  String toString() => 'RepositoryReadException($operation)';
}

class RepositoryWriteException implements Exception {
  RepositoryWriteException(this.operation, this.cause);

  final String operation;
  final Object cause;

  @override
  String toString() => 'RepositoryWriteException($operation)';
}

class OperationPartialFailure implements Exception {
  OperationPartialFailure({
    required this.operation,
    required this.committed,
    required this.cause,
  });

  final String operation;
  final bool committed;
  final Object cause;

  @override
  String toString() =>
      'OperationPartialFailure($operation, committed: $committed)';
}

class OperationWarning {
  OperationWarning({
    required this.operation,
    Iterable<String> failedTaskIds = const [],
  }) : failedTaskIds = List.unmodifiable(failedTaskIds);

  final String operation;
  final List<String> failedTaskIds;
}

class AppController extends ChangeNotifier {
  AppController({
    required TaskRepository repository,
    required SettingsRepository settingsRepository,
    required NotificationCoordinator notifications,
    AuthenticationCoordinator? authentication,
    SharingCoordinator? sharing,
    DateTime Function()? now,
    String Function()? idFactory,
  }) : _repository = repository,
       _settingsRepository = settingsRepository,
       _notifications = notifications,
       _authentication = authentication ?? const _UnavailableAuthentication(),
       _sharing = sharing ?? const _UnavailableSharing(),
       _now = now ?? DateTime.now,
       _idFactory = idFactory ?? const Uuid().v4;

  final TaskRepository _repository;
  final SettingsRepository _settingsRepository;
  final NotificationCoordinator _notifications;
  final AuthenticationCoordinator _authentication;
  final SharingCoordinator _sharing;
  final DateTime Function() _now;
  final String Function() _idFactory;

  List<TaskList> _lists = const [];
  List<TaskItem> _tasks = const [];
  List<FocusSession> _sessions = const [];
  ActiveFocusSession? _activeFocus;
  AppSettings _settings = const AppSettings();
  List<OperationWarning> _operationWarnings = const [];
  Future<void> _operationQueue = Future.value();

  List<TaskList> get lists => _lists;

  List<TaskItem> get tasks => _tasks;

  List<FocusSession> get sessions => _sessions;

  List<FocusSession> get focusHistory => _sessions;

  ActiveFocusSession? get activeFocus => _activeFocus;

  AppSettings get settings => _settings;

  List<OperationWarning> get operationWarnings => _operationWarnings;

  void clearOperationWarnings() {
    if (_operationWarnings.isEmpty) return;
    _operationWarnings = const [];
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final values = await Future.wait<Object?>([
        _repository.loadSnapshot(),
        _repository.loadFocusHistory(),
        _repository.loadActiveFocus(),
        _settingsRepository.load(),
      ]);
      _publishSnapshot(values[0]! as RepositorySnapshot);
      _sessions = List.unmodifiable(values[1]! as List<FocusSession>);
      _activeFocus = values[2] as ActiveFocusSession?;
      _settings = values[3]! as AppSettings;
      notifyListeners();
    } catch (error) {
      throw RepositoryReadException('load', error);
    }
  }

  TaskList listById(String id) => _lists.firstWhere((list) => list.id == id);

  TaskItem taskById(String id) => _tasks.firstWhere((task) => task.id == id);

  List<TaskItem> tasksForList(String listId) =>
      List.unmodifiable(_tasks.where((task) => task.listId == listId));

  List<TaskItem> get todayTasks => List.unmodifiable(
    _tasks.where(
      (task) =>
          !task.completed &&
          !task.overdue &&
          task.dueToday &&
          listById(task.listId).kind != ListKind.grocery,
    ),
  );

  List<TaskItem> get overdueTasks =>
      List.unmodifiable(_tasks.where((task) => task.overdue));

  Future<TaskItem> addTask({
    String? title,
    String? text,
    String listId = 'inbox',
    DateTime? dueAt,
    DateTime? reminderAt,
  }) {
    return _enqueueMutation(
      () => _addTask(
        title: title,
        text: text,
        listId: listId,
        dueAt: dueAt,
        reminderAt: reminderAt,
      ),
    );
  }

  Future<TaskItem> _addTask({
    String? title,
    String? text,
    required String listId,
    DateTime? dueAt,
    DateTime? reminderAt,
  }) async {
    final input = title ?? text;
    if (input == null) {
      throw ArgumentError('A task title is required.');
    }
    final parsed = SmartTaskParser(now: _now).parse(input);
    final list = listById(listId);
    final task = TaskItem.create(
      id: _idFactory(),
      title: parsed.title,
      listId: listId,
      createdAt: _now(),
      dueAt: dueAt ?? parsed.dueAt,
      reminderAt: reminderAt ?? parsed.reminderAt,
      category: list.kind == ListKind.grocery ? 'Other' : '',
      sortOrder: _nextTaskSortOrder(),
    );

    return _saveTaskAndSync(task);
  }

  Future<void> saveTask(TaskItem task) =>
      _enqueueMutation(() => _saveTaskAndSync(task));

  Future<void> toggleTask(String id) => _enqueueMutation(() => _toggleTask(id));

  Future<void> _toggleTask(String id) async {
    final task = taskById(id);
    final now = _now();
    await _saveTaskAndSync(
      task.copyWith(
        completed: !task.completed,
        completedAt: task.completed ? null : now,
        clearCompletedAt: task.completed,
        updatedAt: now,
      ),
    );
  }

  Future<void> deleteTask(String id) => _enqueueMutation(() => _deleteTask(id));

  Future<void> _deleteTask(String id) async {
    await _write('deleteTask', () => _repository.deleteTask(id));
    _tasks = List.unmodifiable(_tasks.where((task) => task.id != id));
    notifyListeners();
    await _cancelWithWarning('deleteTaskReminder', [id]);
  }

  Future<TaskList> addList({
    required String name,
    required int colorValue,
    required ListKind kind,
  }) {
    return _enqueueMutation(
      () => _addList(name: name, colorValue: colorValue, kind: kind),
    );
  }

  Future<TaskList> _addList({
    required String name,
    required int colorValue,
    required ListKind kind,
  }) async {
    final list = TaskList(
      id: _idFactory(),
      name: name,
      colorValue: colorValue,
      kind: kind,
      sortOrder: _nextListSortOrder(),
    );
    await _write('saveList', () => _repository.saveList(list));
    _lists = _sortedLists([..._lists, list]);
    notifyListeners();
    return list;
  }

  Future<void> updateList(TaskList list) =>
      _enqueueMutation(() => _updateList(list));

  Future<void> _updateList(TaskList list) async {
    await _write('saveList', () => _repository.saveList(list));
    final replaced = [
      for (final item in _lists)
        if (item.id == list.id) list else item,
    ];
    if (!replaced.any((item) => item.id == list.id)) {
      replaced.add(list);
    }
    _lists = _sortedLists(replaced);
    notifyListeners();
  }

  Future<void> deleteList(String listId, ListDeletionStrategy strategy) =>
      _enqueueMutation(() => _deleteList(listId, strategy));

  Future<void> _deleteList(String listId, ListDeletionStrategy strategy) async {
    final deletedTaskIds = strategy == ListDeletionStrategy.deleteTasks
        ? _tasks
              .where((task) => task.listId == listId)
              .map((task) => task.id)
              .toList()
        : const <String>[];
    late final RepositorySnapshot snapshot;
    try {
      snapshot = await _repository.deleteList(listId, strategy);
    } catch (error) {
      throw RepositoryWriteException('deleteList', error);
    }
    _publishSnapshot(snapshot);
    notifyListeners();
    await _cancelWithWarning('deleteListReminders', deletedTaskIds);
  }

  Future<void> updateSettings(AppSettings value) async {
    await _write('saveSettings', () => _settingsRepository.save(value));
    _settings = value;
    notifyListeners();
  }

  Future<bool> updateFaceId(bool enabled) async {
    if (enabled && !await authenticate()) return false;
    await updateSettings(_settings.copyWith(faceId: enabled));
    return true;
  }

  Future<bool> authenticate() => _authentication.authenticate();

  Future<void> shareList(TaskList list) {
    final openTasks = tasksForList(list.id)
        .where((task) => !task.completed)
        .map((task) => '○ ${task.title}')
        .join('\n');
    return _sharing.share(
      title: '${list.name} · LessDo',
      text: '${list.name}\n\n$openTasks\n\nShared from LessDo',
    );
  }

  Future<void> saveActiveFocus(ActiveFocusSession? session) =>
      _enqueueMutation(() => _saveActiveFocus(session));

  Future<void> _saveActiveFocus(ActiveFocusSession? session) async {
    await _write('saveActiveFocus', () => _repository.saveActiveFocus(session));
    _activeFocus = session;
    notifyListeners();
  }

  Future<void> completeFocus(FocusSession history, {String? completedTaskId}) {
    return _enqueueMutation(
      () => _completeFocus(history, completedTaskId: completedTaskId),
    );
  }

  Future<void> _completeFocus(
    FocusSession history, {
    String? completedTaskId,
  }) async {
    await _write(
      'completeFocus',
      () =>
          _repository.completeFocus(history, completedTaskId: completedTaskId),
    );
    _sessions = List.unmodifiable([history, ..._sessions]);
    _activeFocus = null;
    if (completedTaskId != null) {
      _tasks = List.unmodifiable([
        for (final task in _tasks)
          if (task.id == completedTaskId)
            task.copyWith(
              completed: true,
              completedAt: history.completedAt,
              updatedAt: history.completedAt,
            )
          else
            task,
      ]);
    }
    notifyListeners();
    if (completedTaskId != null) {
      await _cancelWithWarning('completeFocusReminder', [completedTaskId]);
    }
  }

  Future<void> addSession({
    required String title,
    required FocusMode mode,
    required int durationSeconds,
  }) => _enqueueMutation(
    () => _completeFocus(
      FocusSession(
        id: _idFactory(),
        taskTitle: title,
        minutes: durationSeconds ~/ 60,
        mode: mode,
        durationSeconds: durationSeconds,
        completedAt: _now(),
      ),
    ),
  );

  Future<void> retryReminder(String taskId) =>
      _enqueueMutation(() => _retryReminder(taskId));

  Future<void> _retryReminder(String taskId) async {
    final task = taskById(taskId);
    if (task.reminderAt == null || task.completed) return;
    try {
      await _scheduleReminder(task);
    } catch (_) {
      _recordWarning('scheduleReminder', [task.id]);
      return;
    }
    if (task.reminderSchedulingFailed) {
      await _persistReminderState(
        task.copyWith(reminderSchedulingFailed: false),
        operation: 'clearReminderFailure',
        committedTask: task,
      );
    }
  }

  Future<TaskItem> _saveTaskAndSync(TaskItem task) async {
    await _write('saveTask', () => _repository.saveTask(task));
    if (task.reminderAt == null || task.completed) {
      _publishTask(task);
      notifyListeners();
      await _cancelWithWarning('cancelReminder', [task.id]);
      return task;
    }

    try {
      await _scheduleReminder(task);
    } catch (_) {
      final failedTask = task.copyWith(reminderSchedulingFailed: true);
      await _persistReminderState(
        failedTask,
        operation: 'persistReminderFailure',
        committedTask: task,
      );
      _recordWarning('scheduleReminder', [task.id]);
      return failedTask;
    }

    if (task.reminderSchedulingFailed) {
      final clearedTask = task.copyWith(reminderSchedulingFailed: false);
      await _persistReminderState(
        clearedTask,
        operation: 'clearReminderFailure',
        committedTask: task,
      );
      return clearedTask;
    }
    _publishTask(task);
    notifyListeners();
    return task;
  }

  Future<void> _persistReminderState(
    TaskItem task, {
    required String operation,
    required TaskItem committedTask,
  }) async {
    try {
      await _repository.saveTask(task);
    } catch (error) {
      try {
        _publishSnapshot(await _repository.loadSnapshot());
        notifyListeners();
      } catch (_) {
        _publishTask(committedTask);
        notifyListeners();
      }
      throw OperationPartialFailure(
        operation: operation,
        committed: true,
        cause: error,
      );
    }
    _publishTask(task);
    notifyListeners();
  }

  Future<void> _cancelWithWarning(
    String operation,
    Iterable<String> taskIds,
  ) async {
    final failedIds = <String>[];
    for (final taskId in taskIds) {
      try {
        await _notifications.cancel(taskId);
      } catch (_) {
        failedIds.add(taskId);
      }
    }
    if (failedIds.isNotEmpty) {
      _recordWarning(operation, failedIds);
    }
  }

  void _recordWarning(String operation, Iterable<String> failedTaskIds) {
    final normalizedIds = failedTaskIds.toSet().toList()..sort();
    final duplicate = _operationWarnings.any(
      (warning) =>
          warning.operation == operation &&
          listEquals(warning.failedTaskIds, normalizedIds),
    );
    if (duplicate) return;
    final warnings = [
      ..._operationWarnings,
      OperationWarning(operation: operation, failedTaskIds: normalizedIds),
    ];
    _operationWarnings = List.unmodifiable(
      warnings.length > 50 ? warnings.sublist(warnings.length - 50) : warnings,
    );
    notifyListeners();
  }

  Future<void> _scheduleReminder(TaskItem task) async {
    if (!await _notifications.requestPermission()) {
      throw StateError('Notification permission denied.');
    }
    await _notifications.schedule(task);
  }

  Future<T> _enqueueMutation<T>(Future<T> Function() operation) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  void _publishSnapshot(RepositorySnapshot snapshot) {
    _lists = List.unmodifiable(snapshot.lists);
    _tasks = List.unmodifiable(snapshot.tasks);
  }

  void _publishTask(TaskItem task) {
    final replaced = [
      for (final item in _tasks)
        if (item.id == task.id) task else item,
    ];
    if (!replaced.any((item) => item.id == task.id)) {
      replaced.add(task);
    }
    _tasks = _sortedTasks(replaced);
  }

  Future<void> _write(String operation, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      throw RepositoryWriteException(operation, error);
    }
  }

  int _nextTaskSortOrder() => _tasks.fold(
    0,
    (maximum, task) => task.sortOrder >= maximum ? task.sortOrder + 1 : maximum,
  );

  int _nextListSortOrder() => _lists.fold(
    0,
    (maximum, list) => list.sortOrder >= maximum ? list.sortOrder + 1 : maximum,
  );

  List<TaskItem> _sortedTasks(Iterable<TaskItem> values) {
    final sorted = values.toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    return List.unmodifiable(sorted);
  }

  List<TaskList> _sortedLists(Iterable<TaskList> values) {
    final sorted = values.toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    return List.unmodifiable(sorted);
  }
}

class _UnavailableAuthentication implements AuthenticationCoordinator {
  const _UnavailableAuthentication();

  @override
  Future<bool> authenticate() async => false;
}

class _UnavailableSharing implements SharingCoordinator {
  const _UnavailableSharing();

  @override
  Future<void> share({required String title, required String text}) async {}
}
