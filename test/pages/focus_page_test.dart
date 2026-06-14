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
  testWidgets('resume refresh renders absolute time and completes only once', (
    tester,
  ) async {
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
    await tester.runAsync(store.focusController.handleLifecycleResume);
    await tester.pump();

    expect(find.text('15:00'), findsOneWidget);

    clock.advance(const Duration(minutes: 20));
    await tester.runAsync(store.focusController.handleLifecycleResume);
    await tester.pump();

    expect(store.sessions, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rapid double start persists only one session', (tester) async {
    final harness = await _Harness.create();
    addTearDown(harness.store.dispose);
    await tester.pumpWidget(harness.widget);

    await tester.tap(find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.runAsync(
      () => _waitUntil(() => !harness.store.focusController.isMutating),
    );

    expect(harness.repository.activeSaveCalls, 1);
    expect(harness.store.focusController.activeSession, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('all focus actions are disabled while completion is pending', (
    tester,
  ) async {
    final harness = await _Harness.create(withTask: true);
    addTearDown(harness.store.dispose);
    await harness.store.focusController.startCountUp(
      taskId: 'task-1',
      taskTitle: 'Write tests',
    );
    harness.repository.blockNextComplete();
    await tester.pumpWidget(harness.widget);

    await tester.tap(find.text('End session'));
    await tester.pump();
    await tester.runAsync(() => harness.repository.completeStarted!.future);
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Pause'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Reset'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'End session'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Complete “Write tests”'),
          )
          .onPressed,
      isNull,
    );

    harness.repository.allowComplete!.complete();
    await tester.runAsync(
      () => _waitUntil(() => !harness.store.focusController.isMutating),
    );
    expect(harness.repository.history, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed start shows an error and enables retry', (tester) async {
    final harness = await _Harness.create();
    addTearDown(harness.store.dispose);
    harness.repository.failNextActiveSave = true;
    await tester.pumpWidget(harness.widget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.runAsync(
      () => _waitUntil(() => !harness.store.focusController.isMutating),
    );
    await tester.pump();

    expect(find.text('Could not update the focus session.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Start'))
          .onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _Repository implements TaskRepository {
  _Repository({this.withTask = false});

  final bool withTask;
  ActiveFocusSession? active;
  final List<FocusSession> history = [];
  int activeSaveCalls = 0;
  bool failNextActiveSave = false;
  Completer<void>? completeStarted;
  Completer<void>? allowComplete;

  void blockNextComplete() {
    completeStarted = Completer<void>();
    allowComplete = Completer<void>();
  }

  @override
  Future<void> completeFocus(
    FocusSession history, {
    String? completedTaskId,
  }) async {
    completeStarted?.complete();
    final allow = allowComplete;
    if (allow != null) await allow.future;
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
  Future<RepositorySnapshot> loadSnapshot() async => RepositorySnapshot(
    lists: await loadLists(),
    tasks: withTask ? [_task()] : const [],
  );

  @override
  Future<List<TaskItem>> loadTasks() async => withTask ? [_task()] : const [];

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
    activeSaveCalls += 1;
    if (failNextActiveSave) {
      failNextActiveSave = false;
      throw StateError('save failed');
    }
    active = session;
  }

  @override
  Future<void> saveList(TaskList list) async {}

  @override
  Future<void> saveTask(TaskItem task) async {}
}

class _Harness {
  _Harness(this.store, this.repository);

  final AppController store;
  final _Repository repository;

  Widget get widget => MaterialApp(
    home: Scaffold(body: FocusPage(store: store)),
  );

  static Future<_Harness> create({bool withTask = false}) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _Repository(withTask: withTask);
    final store = AppController(
      repository: repository,
      settingsRepository: SettingsRepository(
        await SharedPreferences.getInstance(),
      ),
      notifications: _Notifications(),
      now: () => DateTime.utc(2026, 6, 13, 8),
      idFactory: () => 'focus-1',
    );
    await store.load();
    return _Harness(store, repository);
  }
}

Future<void> _waitUntil(bool Function() condition) async {
  while (!condition()) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

TaskItem _task() => TaskItem.create(
  id: 'task-1',
  title: 'Write tests',
  listId: 'inbox',
  createdAt: DateTime.utc(2026),
);

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
