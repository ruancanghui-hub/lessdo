import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/app.dart';
import 'package:lessdo/controllers/app_controller.dart';
import 'package:lessdo/data/settings_repository.dart';
import 'package:lessdo/data/task_repository.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/app_settings.dart';
import 'package:lessdo/models/focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';
import 'package:lessdo/notifications/notification_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkflowHarness {
  WorkflowHarness._({required this.controller});

  final AppController controller;

  LessDoApp get widget => LessDoApp(store: controller);

  static Future<WorkflowHarness> create({
    List<TaskList> lists = const [],
    List<TaskItem> tasks = const [],
  }) async {
    const messages = MethodChannel('com.llfbandit.app_links/messages');
    const events = MethodChannel('com.llfbandit.app_links/events');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(messages, (_) async => null);
    messenger.setMockMethodCallHandler(events, (_) async => null);

    SharedPreferences.setMockInitialValues({});
    final settingsRepository = SettingsRepository(
      await SharedPreferences.getInstance(),
    );
    await settingsRepository.save(
      const AppSettings(hasCompletedOnboarding: true),
    );
    final repository = _MemoryRepository(lists: lists, tasks: tasks);
    final controller = AppController(
      repository: repository,
      settingsRepository: settingsRepository,
      notifications: const _Notifications(),
      now: () => DateTime.utc(2026, 6, 14, 9),
    );
    await controller.load();
    return WorkflowHarness._(controller: controller);
  }

  Future<void> dispose() async => controller.dispose();
}

class _MemoryRepository implements TaskRepository {
  _MemoryRepository({
    List<TaskList> lists = const [],
    List<TaskItem> tasks = const [],
  }) : lists = [
         const TaskList(id: 'inbox', name: 'Inbox', colorValue: 0xFF6C7685),
         ...lists.where((list) => list.id != 'inbox'),
       ],
       tasks = List.of(tasks);

  final List<TaskList> lists;
  final List<TaskItem> tasks;
  final List<FocusSession> history = [];
  ActiveFocusSession? activeFocus;

  @override
  Future<void> completeFocus(
    FocusSession session, {
    String? completedTaskId,
  }) async {
    history.insert(0, session);
    activeFocus = null;
    if (completedTaskId != null) {
      final index = tasks.indexWhere((task) => task.id == completedTaskId);
      if (index != -1) {
        tasks[index] = tasks[index].copyWith(
          completed: true,
          completedAt: session.completedAt,
          updatedAt: session.completedAt,
        );
      }
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    tasks.removeWhere((task) => task.id == taskId);
  }

  @override
  Future<RepositorySnapshot> deleteList(
    String listId,
    ListDeletionStrategy strategy,
  ) async {
    if (listId == 'inbox') throw StateError('Inbox cannot be deleted.');
    if (strategy == ListDeletionStrategy.moveToInbox) {
      for (var index = 0; index < tasks.length; index += 1) {
        if (tasks[index].listId == listId) {
          tasks[index] = tasks[index].copyWith(listId: 'inbox');
        }
      }
    } else {
      tasks.removeWhere((task) => task.listId == listId);
    }
    lists.removeWhere((list) => list.id == listId);
    return loadSnapshot();
  }

  @override
  Future<ActiveFocusSession?> loadActiveFocus() async => activeFocus;

  @override
  Future<List<FocusSession>> loadFocusHistory() async => List.of(history);

  @override
  Future<List<TaskList>> loadLists() async => List.of(lists);

  @override
  Future<RepositorySnapshot> loadSnapshot() async =>
      RepositorySnapshot(lists: List.of(lists), tasks: List.of(tasks));

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(tasks);

  @override
  Future<int> notificationIdFor({
    required String taskId,
    required String occurrenceKey,
  }) async => Object.hash(taskId, occurrenceKey) & 0x3fffffff;

  @override
  Future<TaskItem?> patchReminderSchedulingState(
    String taskId,
    bool failed,
  ) async {
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return null;
    tasks[index] = tasks[index].copyWith(reminderSchedulingFailed: failed);
    return tasks[index];
  }

  @override
  Future<void> saveActiveFocus(ActiveFocusSession? session) async {
    activeFocus = session;
  }

  @override
  Future<void> saveList(TaskList list) async {
    final index = lists.indexWhere((item) => item.id == list.id);
    if (index == -1) {
      lists.add(list);
    } else {
      lists[index] = list;
    }
  }

  @override
  Future<void> saveTask(TaskItem task) async {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
  }
}

class _Notifications implements NotificationCoordinatorContract {
  const _Notifications();

  @override
  Stream<NotificationAction> get actions => const Stream.empty();

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<NotificationAction?> launchAction() async => null;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.granted;

  @override
  Future<NotificationReconcileReport> reconcile() async =>
      NotificationReconcileReport(
        cancelledOrphanTaskIds: const [],
        scheduledMissingTaskIds: const [],
        failedTaskIds: const [],
      );

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.granted;

  @override
  Future<ReminderScheduleStatus> schedule(
    TaskItem task, {
    bool requestPermission = true,
  }) async => ReminderScheduleStatus.scheduled;

  @override
  Future<ReminderScheduleStatus> snooze(TaskItem task) async =>
      ReminderScheduleStatus.scheduled;
}
