import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/focus_session.dart';
import '../models/smart_task_parser.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class AppStore extends ChangeNotifier {
  AppStore({
    required StorageService storage,
    required NotificationService notifications,
  }) : _storage = storage,
       _notifications = notifications;

  static const _tasksKey = 'lessdo_tasks_v1';
  static const _listsKey = 'lessdo_lists_v1';
  static const _settingsKey = 'lessdo_settings_v1';
  static const _sessionsKey = 'lessdo_sessions_v1';

  final StorageService _storage;
  final NotificationService _notifications;
  final _uuid = const Uuid();
  final _localAuth = LocalAuthentication();

  List<TaskList> lists = [];
  List<TaskItem> tasks = [];
  List<FocusSession> sessions = [];
  AppSettings settings = const AppSettings();

  Future<void> load() async {
    final storedLists = _storage.readList(_listsKey);
    final storedTasks = _storage.readList(_tasksKey);
    final storedSettings = _storage.readMap(_settingsKey);
    final storedSessions = _storage.readList(_sessionsKey);

    lists = storedLists.isEmpty
        ? _seedLists()
        : storedLists.map(TaskList.fromJson).toList();
    tasks = storedTasks.isEmpty
        ? _seedTasks()
        : storedTasks.map(TaskItem.fromJson).toList();
    settings = storedSettings == null
        ? const AppSettings()
        : AppSettings.fromJson(storedSettings);
    sessions = storedSessions.map(FocusSession.fromJson).toList();

    await _persistAll();
    notifyListeners();
  }

  TaskList listById(String id) => lists.firstWhere((list) => list.id == id);

  TaskItem taskById(String id) => tasks.firstWhere((task) => task.id == id);

  List<TaskItem> tasksForList(String listId) =>
      tasks.where((task) => task.listId == listId).toList();

  List<TaskItem> get todayTasks => tasks
      .where(
        (task) =>
            !task.completed &&
            !task.overdue &&
            task.dueToday &&
            listById(task.listId).kind != ListKind.grocery,
      )
      .toList();

  List<TaskItem> get overdueTasks =>
      tasks.where((task) => task.overdue).toList();

  Future<TaskItem> addTask({
    required String text,
    String listId = 'inbox',
    DateTime? dueAt,
    DateTime? reminderAt,
  }) async {
    final parsed = SmartTaskParser(now: DateTime.now).parse(text);
    final list = listById(listId);
    final task = TaskItem.create(
      id: _uuid.v4(),
      title: parsed.title,
      listId: listId,
      createdAt: DateTime.now(),
      dueAt: dueAt ?? parsed.dueAt,
      reminderAt: reminderAt ?? parsed.reminderAt,
      category: list.kind == ListKind.grocery ? 'Other' : '',
    );
    tasks = [...tasks, task];
    await _saveTasks();
    if (task.reminderAt != null) {
      await _notifications.requestPermission();
      await _notifications.schedule(task);
    }
    notifyListeners();
    return task;
  }

  Future<void> saveTask(TaskItem task) async {
    tasks = [
      for (final item in tasks)
        if (item.id == task.id) task else item,
    ];
    await _saveTasks();
    if (task.reminderAt == null || task.completed) {
      await _notifications.cancel(task.id);
    } else {
      await _notifications.requestPermission();
      await _notifications.schedule(task);
    }
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    final task = taskById(id);
    await saveTask(
      task.copyWith(
        completed: !task.completed,
        completedAt: task.completed ? null : DateTime.now(),
        clearCompletedAt: task.completed,
      ),
    );
  }

  Future<void> deleteTask(String id) async {
    tasks = tasks.where((task) => task.id != id).toList();
    await _notifications.cancel(id);
    await _saveTasks();
    notifyListeners();
  }

  Future<TaskList> addList({
    required String name,
    required int colorValue,
    required ListKind kind,
  }) async {
    final list = TaskList(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      kind: kind,
    );
    lists = [...lists, list];
    await _saveLists();
    notifyListeners();
    return list;
  }

  Future<void> updateList(TaskList list) async {
    lists = [
      for (final item in lists)
        if (item.id == list.id) list else item,
    ];
    await _saveLists();
    notifyListeners();
  }

  Future<void> shareList(TaskList list) async {
    final openTasks = tasksForList(list.id)
        .where((task) => !task.completed)
        .map((task) => '○ ${task.title}')
        .join('\n');
    await SharePlus.instance.share(
      ShareParams(
        title: '${list.name} · LessDo',
        text: '${list.name}\n\n$openTasks\n\nShared from LessDo',
      ),
    );
  }

  Future<bool> updateFaceId(bool enabled) async {
    if (enabled) {
      if (!await authenticate()) return false;
    }
    await updateSettings(settings.copyWith(faceId: enabled));
    return true;
  }

  Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      return _localAuth.authenticate(
        localizedReason: 'Unlock LessDo',
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> updateSettings(AppSettings value) async {
    settings = value;
    await _storage.writeMap(_settingsKey, settings.toJson());
    notifyListeners();
  }

  Future<void> addSession({required String title, required int minutes}) async {
    sessions = [
      FocusSession(
        id: _uuid.v4(),
        taskTitle: title,
        minutes: minutes,
        durationSeconds: minutes * 60,
        completedAt: DateTime.now(),
      ),
      ...sessions,
    ];
    await _storage.writeList(
      _sessionsKey,
      sessions.map((item) => item.toJson()).toList(),
    );
    notifyListeners();
  }

  Future<void> _persistAll() async {
    await Future.wait([
      _saveLists(),
      _saveTasks(),
      _storage.writeMap(_settingsKey, settings.toJson()),
      _storage.writeList(
        _sessionsKey,
        sessions.map((item) => item.toJson()).toList(),
      ),
    ]);
  }

  Future<void> _saveLists() => _storage.writeList(
    _listsKey,
    lists.map((item) => item.toJson()).toList(),
  );

  Future<void> _saveTasks() => _storage.writeList(
    _tasksKey,
    tasks.map((item) => item.toJson()).toList(),
  );

  List<TaskList> _seedLists() => const [
    TaskList(id: 'inbox', name: 'Inbox', colorValue: 0xFF6C7685),
    TaskList(id: 'work', name: 'Work', colorValue: 0xFF2E7BF6),
    TaskList(id: 'personal', name: 'Personal', colorValue: 0xFF50B978),
    TaskList(id: 'product', name: 'Product', colorValue: 0xFF9B51E0),
    TaskList(
      id: 'grocery',
      name: 'Grocery',
      colorValue: 0xFFFF765C,
      kind: ListKind.grocery,
    ),
  ];

  List<TaskItem> _seedTasks() {
    final now = DateTime.now();
    DateTime at(int dayOffset, int hour, [int minute = 0]) =>
        DateTime(now.year, now.month, now.day + dayOffset, hour, minute);

    return [
      TaskItem(
        id: _uuid.v4(),
        title: 'Pay electricity bill',
        listId: 'personal',
        createdAt: now,
        dueAt: at(-1, 18),
        reminderAt: at(-1, 8),
        notes: 'Pay before the late fee is applied.',
        priority: TaskPriority.high,
        repeatRule: RepeatRule.monthly,
      ),
      TaskItem(
        id: _uuid.v4(),
        title: 'Team meeting',
        listId: 'work',
        createdAt: now,
        dueAt: at(0, 9, 30),
        reminderAt: at(0, 9, 30),
        notes: 'Review launch milestones with the team.',
        repeatRule: RepeatRule.weekly,
        subtasks: [
          SubTask(id: _uuid.v4(), title: 'Open project notes', completed: true),
          SubTask(id: _uuid.v4(), title: 'Prepare blockers'),
        ],
      ),
      TaskItem(
        id: _uuid.v4(),
        title: 'Buy coffee',
        listId: 'personal',
        createdAt: now,
        dueAt: at(0, 17),
      ),
      TaskItem(
        id: _uuid.v4(),
        title: 'Finish PRD draft',
        listId: 'work',
        createdAt: now,
        dueAt: at(0, 18),
        reminderAt: at(0, 14),
        notes: 'Finish scope, success metrics, and roadmap.',
        priority: TaskPriority.high,
        subtasks: [
          SubTask(id: _uuid.v4(), title: 'Review MVP scope', completed: true),
          SubTask(id: _uuid.v4(), title: 'Confirm roadmap'),
        ],
      ),
      TaskItem(
        id: _uuid.v4(),
        title: 'Review onboarding flow',
        listId: 'product',
        createdAt: now,
        dueAt: at(0, 19),
      ),
      TaskItem(
        id: _uuid.v4(),
        title: 'Milk',
        listId: 'grocery',
        createdAt: now,
        dueAt: at(0, 18),
        category: 'Dairy',
      ),
      TaskItem(
        id: _uuid.v4(),
        title: 'Avocados',
        listId: 'grocery',
        createdAt: now,
        dueAt: at(0, 18),
        category: 'Produce',
      ),
    ];
  }
}
