import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/controllers/focus_session_controller.dart';
import 'package:lessdo/data/task_repository.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';
import 'package:lessdo/notifications/notification_coordinator.dart';

void main() {
  late _MemoryRepository repository;
  late _FocusNotifications notifications;
  late MutableClock clock;
  late FocusSessionController controller;
  var nextId = 0;

  setUp(() {
    repository = _MemoryRepository();
    notifications = _FocusNotifications();
    clock = MutableClock(DateTime.utc(2026, 6, 13, 8));
    controller = FocusSessionController(
      repository: repository,
      notifications: notifications,
      clock: clock.now,
      idFactory: () => 'focus-${++nextId}',
    );
  });

  test('background time advances countdown from absolute clock', () async {
    await controller.startCountdown(const Duration(minutes: 25));

    clock.advance(const Duration(minutes: 10));

    expect(controller.remaining, const Duration(minutes: 15));
    expect(controller.elapsed, const Duration(minutes: 10));
  });

  test('restores active session after controller recreation', () async {
    await controller.startPomodoro(const Duration(minutes: 25));

    final restored = FocusSessionController(
      repository: repository,
      notifications: notifications,
      clock: clock.now,
      idFactory: () => 'unused',
    );
    await restored.load();

    expect(restored.isRunning, isTrue);
    expect(restored.remaining, const Duration(minutes: 25));
    expect(restored.activeSession?.mode, FocusMode.pomodoro);
  });

  test('completion is single-flight and idempotent', () async {
    await controller.startCountdown(const Duration(minutes: 1));
    clock.advance(const Duration(minutes: 1));

    await Future.wait([controller.complete(), controller.complete()]);
    await controller.handleLifecycleResume();

    expect(await repository.loadFocusHistory(), hasLength(1));
    expect(repository.completeCalls, 1);
    expect(controller.activeSession, isNull);
  });

  test('pause and resume persist absolute timer state', () async {
    await controller.startCountdown(const Duration(minutes: 10));
    clock.advance(const Duration(minutes: 2));

    await controller.pause();
    clock.advance(const Duration(minutes: 5));
    expect(controller.remaining, const Duration(minutes: 8));

    await controller.resume();
    clock.advance(const Duration(minutes: 3));
    expect(controller.remaining, const Duration(minutes: 5));
    expect(
      repository.savedActive.last?.targetAt,
      DateTime.utc(2026, 6, 13, 8, 15),
    );
  });

  test('count up completion stores actual elapsed duration', () async {
    await controller.startCountUp(taskTitle: 'Open focus');
    clock.advance(const Duration(seconds: 73));

    await controller.complete();

    final history = (await repository.loadFocusHistory()).single;
    expect(history.mode, FocusMode.countUp);
    expect(history.durationSeconds, 73);
    expect(history.minutes, 1);
  });

  test(
    'timed sessions schedule and state changes cancel notifications',
    () async {
      await controller.startPomodoro(const Duration(minutes: 25));
      final sessionId = controller.activeSession!.id;
      expect(notifications.scheduled, [sessionId]);

      await controller.pause();
      expect(notifications.cancelled, [sessionId]);

      await controller.resume();
      expect(notifications.scheduled, [sessionId, sessionId]);

      await controller.reset();
      expect(notifications.cancelled, [sessionId, sessionId]);
      expect(repository.savedActive.last, isNull);
    },
  );

  test(
    'completion atomically records history and optionally completes task',
    () async {
      repository.tasks.add(_task('task-1'));
      await controller.startCountUp(taskId: 'task-1', taskTitle: 'Write tests');
      clock.advance(const Duration(minutes: 4));

      await controller.complete(completeTask: true);

      expect(repository.completeCalls, 1);
      expect(repository.completedTaskIds, ['task-1']);
      expect(repository.tasks.single.completed, isTrue);
      expect(notifications.cancelled, [controller.lastCompletedSessionId]);
    },
  );

  test(
    'expired restoration and repeated lifecycle events create one history',
    () async {
      await controller.startCountdown(const Duration(minutes: 1));
      clock.advance(const Duration(minutes: 2));

      final restored = FocusSessionController(
        repository: repository,
        notifications: notifications,
        clock: clock.now,
        idFactory: () => 'unused',
      );
      await Future.wait([
        restored.load(),
        restored.handleLifecycleResume(),
        restored.handleLifecycleResume(),
      ]);

      expect(repository.completeCalls, 1);
      expect(await repository.loadFocusHistory(), hasLength(1));
    },
  );

  test('cancel clears persisted state without creating history', () async {
    await controller.startCountUp();
    final sessionId = controller.activeSession!.id;

    await controller.cancel();

    expect(repository.savedActive.last, isNull);
    expect(await repository.loadFocusHistory(), isEmpty);
    expect(notifications.cancelled, [sessionId]);
  });
}

class MutableClock {
  MutableClock(this._value);

  DateTime _value;

  DateTime now() => _value;

  void advance(Duration duration) {
    _value = _value.add(duration);
  }
}

class _MemoryRepository implements TaskRepository {
  final List<TaskItem> tasks = [];
  final List<FocusSession> history = [];
  final List<ActiveFocusSession?> savedActive = [];
  final List<String> completedTaskIds = [];
  ActiveFocusSession? active;
  int completeCalls = 0;

  @override
  Future<void> completeFocus(
    FocusSession history, {
    String? completedTaskId,
  }) async {
    completeCalls += 1;
    this.history.insert(0, history);
    active = null;
    if (completedTaskId != null) {
      completedTaskIds.add(completedTaskId);
      final index = tasks.indexWhere((task) => task.id == completedTaskId);
      if (index == -1) throw StateError('Task not found.');
      tasks[index] = tasks[index].copyWith(
        completed: true,
        completedAt: history.completedAt,
        updatedAt: history.completedAt,
      );
    }
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
  Future<List<TaskList>> loadLists() async => const [];

  @override
  Future<RepositorySnapshot> loadSnapshot() async =>
      RepositorySnapshot(lists: const [], tasks: tasks);

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(tasks);

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
    savedActive.add(session);
  }

  @override
  Future<void> saveList(TaskList list) async {}

  @override
  Future<void> saveTask(TaskItem task) async {}
}

class _FocusNotifications
    implements
        NotificationCoordinatorContract,
        FocusNotificationCoordinatorContract {
  final List<String> scheduled = [];
  final List<String> cancelled = [];

  @override
  Stream<NotificationAction> get actions => const Stream.empty();

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelFocus(String sessionId) async {
    cancelled.add(sessionId);
  }

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
  }) async {
    scheduled.add(session.id);
  }

  @override
  Future<ReminderScheduleStatus> snooze(TaskItem task) async =>
      ReminderScheduleStatus.scheduled;
}

TaskItem _task(String id) => TaskItem.create(
  id: id,
  title: 'Write tests',
  listId: 'inbox',
  createdAt: DateTime.utc(2026),
);
