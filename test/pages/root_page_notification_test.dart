import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/app.dart';
import 'package:lessdo/controllers/app_controller.dart';
import 'package:lessdo/data/settings_repository.dart';
import 'package:lessdo/data/task_repository.dart';
import 'package:lessdo/l10n/app_localizations.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';
import 'package:lessdo/notifications/notification_coordinator.dart';
import 'package:lessdo/notifications/reminder_schedule.dart';
import 'package:lessdo/pages/root_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('RootPage opens the task requested by a notification action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(
      repository: _Repository(),
      settingsRepository: SettingsRepository(
        await SharedPreferences.getInstance(),
      ),
      notifications: _Notifications(),
      now: () => DateTime.utc(2026, 6, 13),
    );
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RootPage(
          store: controller,
          initialLink: () async => null,
          linkStream: const Stream.empty(),
        ),
      ),
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await controller.handleNotificationAction(
      const NotificationAction.open('task-1'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Task details'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('app resume reconciles reminder windows', (tester) async {
    const messages = MethodChannel('com.llfbandit.app_links/messages');
    const events = MethodChannel('com.llfbandit.app_links/events');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(messages, (_) async => null);
    messenger.setMockMethodCallHandler(events, (_) async => null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(messages, null);
      messenger.setMockMethodCallHandler(events, null);
    });

    SharedPreferences.setMockInitialValues({});
    final notifications = _Notifications();
    final controller = AppController(
      repository: _Repository(),
      settingsRepository: SettingsRepository(
        await SharedPreferences.getInstance(),
      ),
      notifications: notifications,
      now: () => DateTime.utc(2026, 6, 13),
    );
    addTearDown(controller.dispose);
    await controller.load();
    final reconcilesAfterLoad = notifications.reconcileCalls;
    await tester.pumpWidget(LessDoApp(store: controller));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(notifications.reconcileCalls, reconcilesAfterLoad + 1);
  });

  testWidgets('deep links are validated before task mutation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _Repository();
    final controller = AppController(
      repository: repository,
      settingsRepository: SettingsRepository(
        await SharedPreferences.getInstance(),
      ),
      notifications: _Notifications(),
      now: () => DateTime.utc(2026, 6, 13),
    );
    final links = StreamController<Uri>();
    addTearDown(links.close);
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RootPage(
          store: controller,
          initialLink: () async => null,
          linkStream: links.stream,
        ),
      ),
    );
    links.add(Uri.parse('lessdo://x-callback-url/delete'));
    await tester.pump();
    expect(controller.tasks, hasLength(1));

    links.add(
      Uri.parse('lessdo://x-callback-url/create?content=Validated%20task'),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.tasks, hasLength(2));
    expect(controller.tasks.last.title, 'Validated task');
  });
}

class _Notifications implements NotificationCoordinatorContract {
  int reconcileCalls = 0;

  @override
  Stream<NotificationAction> get actions => const Stream.empty();

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<NotificationAction?> launchAction() async => null;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.granted;

  @override
  Future<NotificationReconcileReport> reconcile() async {
    reconcileCalls += 1;
    return NotificationReconcileReport(
      cancelledOrphanTaskIds: const [],
      scheduledMissingTaskIds: const [],
      failedTaskIds: const [],
    );
  }

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

  @override
  Future<void> dispose() async {}
}

class _Repository implements TaskRepository {
  _Repository()
    : tasks = [
        TaskItem.create(
          id: 'task-1',
          title: 'Notification task',
          listId: 'inbox',
          createdAt: DateTime.utc(2026, 6, 13),
        ),
      ];

  final List<TaskItem> tasks;

  @override
  Future<RepositorySnapshot> loadSnapshot() async => RepositorySnapshot(
    lists: const [TaskList(id: 'inbox', name: 'Inbox', colorValue: 0)],
    tasks: tasks,
  );

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(tasks);

  @override
  Future<void> saveTask(TaskItem task) async {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
  }

  @override
  Future<TaskItem?> patchReminderSchedulingState(
    String taskId,
    bool failed,
  ) async => null;

  @override
  Future<int> notificationIdFor({
    required String taskId,
    required String occurrenceKey,
  }) async => stableNotificationId(
    NotificationIdNamespace.task,
    '$taskId:$occurrenceKey',
  );

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<List<TaskList>> loadLists() async => const [];

  @override
  Future<List<FocusSession>> loadFocusHistory() async => const [];

  @override
  Future<ActiveFocusSession?> loadActiveFocus() async => null;

  @override
  Future<void> saveList(TaskList list) async {}

  @override
  Future<RepositorySnapshot> deleteList(
    String listId,
    ListDeletionStrategy strategy,
  ) async => loadSnapshot();

  @override
  Future<void> saveActiveFocus(ActiveFocusSession? session) async {}

  @override
  Future<void> completeFocus(
    FocusSession history, {
    String? completedTaskId,
  }) async {}
}
