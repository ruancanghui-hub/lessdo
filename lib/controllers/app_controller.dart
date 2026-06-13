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

abstract interface class NotificationCoordinator {
  Future<void> schedule(TaskItem task);

  Future<void> cancel(String taskId);
}

abstract interface class AuthenticationCoordinator {
  Future<bool> authenticate();
}

abstract interface class SharingCoordinator {
  Future<void> share({required String title, required String text});
}

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

  List<TaskList> get lists => _lists;

  List<TaskItem> get tasks => _tasks;

  List<FocusSession> get sessions => _sessions;

  List<FocusSession> get focusHistory => _sessions;

  ActiveFocusSession? get activeFocus => _activeFocus;

  AppSettings get settings => _settings;

  Future<void> load() async {
    try {
      final values = await Future.wait<Object?>([
        _repository.loadLists(),
        _repository.loadTasks(),
        _repository.loadFocusHistory(),
        _repository.loadActiveFocus(),
        _settingsRepository.load(),
      ]);
      _lists = List.unmodifiable(values[0]! as List<TaskList>);
      _tasks = List.unmodifiable(values[1]! as List<TaskItem>);
      _sessions = List.unmodifiable(values[2]! as List<FocusSession>);
      _activeFocus = values[3] as ActiveFocusSession?;
      _settings = values[4]! as AppSettings;
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

    await _write('saveTask', () => _repository.saveTask(task));
    _tasks = _sortedTasks([..._tasks, task]);
    notifyListeners();
    await _syncNotification(task);
    return task;
  }

  Future<void> saveTask(TaskItem task) async {
    await _write('saveTask', () => _repository.saveTask(task));
    final replaced = [
      for (final item in _tasks)
        if (item.id == task.id) task else item,
    ];
    if (!replaced.any((item) => item.id == task.id)) {
      replaced.add(task);
    }
    _tasks = _sortedTasks(replaced);
    notifyListeners();
    await _syncNotification(task);
  }

  Future<void> toggleTask(String id) async {
    final task = taskById(id);
    final now = _now();
    await saveTask(
      task.copyWith(
        completed: !task.completed,
        completedAt: task.completed ? null : now,
        clearCompletedAt: task.completed,
        updatedAt: now,
      ),
    );
  }

  Future<void> deleteTask(String id) async {
    await _write('deleteTask', () => _repository.deleteTask(id));
    _tasks = List.unmodifiable(_tasks.where((task) => task.id != id));
    notifyListeners();
    await _notifications.cancel(id);
  }

  Future<TaskList> addList({
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

  Future<void> updateList(TaskList list) async {
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

  Future<void> deleteList(String listId, ListDeletionStrategy strategy) async {
    await _write('deleteList', () => _repository.deleteList(listId, strategy));
    try {
      final values = await Future.wait([
        _repository.loadLists(),
        _repository.loadTasks(),
      ]);
      _lists = List.unmodifiable(values[0] as List<TaskList>);
      _tasks = List.unmodifiable(values[1] as List<TaskItem>);
      notifyListeners();
    } catch (error) {
      throw RepositoryReadException('reloadAfterDeleteList', error);
    }
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

  Future<void> saveActiveFocus(ActiveFocusSession? session) async {
    await _write('saveActiveFocus', () => _repository.saveActiveFocus(session));
    _activeFocus = session;
    notifyListeners();
  }

  Future<void> completeFocus(
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
  }

  Future<void> addSession({
    required String title,
    required FocusMode mode,
    required int durationSeconds,
  }) {
    return completeFocus(
      FocusSession(
        id: _idFactory(),
        taskTitle: title,
        minutes: durationSeconds ~/ 60,
        mode: mode,
        durationSeconds: durationSeconds,
        completedAt: _now(),
      ),
    );
  }

  Future<void> _syncNotification(TaskItem task) {
    if (task.reminderAt == null || task.completed) {
      return _notifications.cancel(task.id);
    }
    return _notifications.schedule(task);
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
