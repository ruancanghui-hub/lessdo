import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/controllers/app_controller.dart';
import 'package:lessdo/data/settings_repository.dart';
import 'package:lessdo/data/task_repository.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';
import 'package:lessdo/notifications/notification_coordinator.dart';
import 'package:lessdo/pages/focus_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'lifecycle resume renders absolute time and completes only once',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final clock = _MutableClock(DateTime.utc(2026, 6, 13, 8));
      final notifications = _Notifications();
      final store = AppController(
        repository: _Repository(),
        settingsRepository: SettingsRepository(
          await SharedPreferences.getInstance(),
        ),
        notifications: notifications,
        now: clock.now,
        idFactory: () => 'focus-1',
      );
      addTearDown(store.dispose);
      await store.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FocusPage(store: store)),
        ),
      );

      await tester.runAsync(
        () => store.focusController.startPomodoro(const Duration(minutes: 25)),
      );
      await tester.pump();
      clock.advance(const Duration(minutes: 10));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(store.focusController.handleLifecycleResume);
      await tester.pump();

      expect(find.text('15:00'), findsOneWidget);

      clock.advance(const Duration(minutes: 20));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(store.focusController.handleLifecycleResume);
      await tester.pump();

      expect(store.sessions, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _Repository implements TaskRepository {
  ActiveFocusSession? active;
  final List<FocusSession> history = [];

  @override
  Future<void> completeFocus(
    FocusSession history, {
    String? completedTaskId,
  }) async {
    this.history.insert(0, history);
    active = null;
  }

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<RepositorySnapshot> deleteList(
    String listId,
    ListDeletionStrategy strategy,
  ) async => loadSnapshot();

  @override
  Future<ActiveFocusSession?> loadActiveFocus() async => active;

  @override
  Future<List<FocusSession>> loadFocusHistory() async => List.of(history);

  @override
  Future<List<TaskList>> loadLists() async => const [
    TaskList(id: 'inbox', name: 'Inbox', colorValue: 0),
  ];

  @override
  Future<RepositorySnapshot> loadSnapshot() async =>
      RepositorySnapshot(lists: await loadLists(), tasks: const []);

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
  Future<void> saveActiveFocus(ActiveFocusSession? session) async {
    active = session;
  }

  @override
  Future<void> saveList(TaskList list) async {}

  @override
  Future<void> saveTask(TaskItem task) async {}
}

class _MutableClock {
  _MutableClock(this._value);

  DateTime _value;

  DateTime now() => _value;

  void advance(Duration duration) {
    _value = _value.add(duration);
  }
}

class _Notifications
    implements
        NotificationCoordinatorContract,
        FocusNotificationCoordinatorContract {
  @override
  Stream<NotificationAction> get actions => const Stream.empty();

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelFocus(String sessionId) async {}

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
  Future<void> scheduleFocus(
    ActiveFocusSession session, {
    bool requestPermission = true,
  }) async {}

  @override
  Future<ReminderScheduleStatus> snooze(TaskItem task) async =>
      ReminderScheduleStatus.scheduled;
}
