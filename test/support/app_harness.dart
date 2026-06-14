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

class AppHarness {
  AppHarness._(this.controller);

  final AppController controller;

  LessDoApp get widget => LessDoApp(store: controller);

  static Future<AppHarness> create({AppSettings? settings}) async {
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
    if (settings != null) await settingsRepository.save(settings);
    final controller = AppController(
      repository: _EmptyRepository(),
      settingsRepository: settingsRepository,
      notifications: const _Notifications(),
      now: () => DateTime.utc(2026, 6, 14),
    );
    await controller.load();
    return AppHarness._(controller);
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

class _EmptyRepository implements TaskRepository {
  static const inbox = TaskList(
    id: 'inbox',
    name: 'Inbox',
    colorValue: 0xFF2E7BF6,
  );

  @override
  Future<void> completeFocus(
    FocusSession history, {
    String? completedTaskId,
  }) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<RepositorySnapshot> deleteList(
    String listId,
    ListDeletionStrategy strategy,
  ) async => loadSnapshot();

  @override
  Future<ActiveFocusSession?> loadActiveFocus() async => null;

  @override
  Future<List<FocusSession>> loadFocusHistory() async => const [];

  @override
  Future<List<TaskList>> loadLists() async => const [inbox];

  @override
  Future<RepositorySnapshot> loadSnapshot() async =>
      RepositorySnapshot(lists: const [inbox], tasks: const []);

  @override
  Future<List<TaskItem>> loadTasks() async => const [];

  @override
  Future<int> notificationIdFor({
    required String taskId,
    required String occurrenceKey,
  }) async => 1;

  @override
  Future<TaskItem?> patchReminderSchedulingState(
    String taskId,
    bool failed,
  ) async => null;

  @override
  Future<void> saveActiveFocus(ActiveFocusSession? session) async {}

  @override
  Future<void> saveList(TaskList list) async {}

  @override
  Future<void> saveTask(TaskItem task) async {}
}
