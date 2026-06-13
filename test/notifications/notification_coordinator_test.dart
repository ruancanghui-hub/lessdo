import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lessdo/data/task_repository.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';
import 'package:lessdo/notifications/notification_coordinator.dart';
import 'package:lessdo/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test(
    'initialize registers callbacks without requesting permission',
    () async {
      final platform = _FakeNotificationPlatform();
      final coordinator = _coordinator(platform: platform);

      await coordinator.initialize();

      expect(platform.initializeCalls, 1);
      expect(platform.permissionRequests, 0);
    },
  );

  test('timezone lookup failure uses typed system-local fallback', () async {
    final result = await initializeNotificationTimeZone(
      lookupIdentifier: () async => throw StateError('unavailable'),
      systemOffset: () => const Duration(hours: 5, minutes: 30),
    );

    expect(result.warning, isA<NotificationTimeZoneFallbackWarning>());
    expect(result.location.name, 'System/LocalFallback');
    expect(
      result.location.currentTimeZone.offset,
      const Duration(hours: 5, minutes: 30),
    );
    expect(result.location.name, isNot('UTC'));
  });

  test(
    'permission status distinguishes first request from persisted denial',
    () {
      expect(
        resolveNotificationPermissionStatus(
          enabled: false,
          hasRequestedPermission: false,
        ),
        NotificationPermissionStatus.notDetermined,
      );
      expect(
        resolveNotificationPermissionStatus(
          enabled: false,
          hasRequestedPermission: true,
        ),
        NotificationPermissionStatus.denied,
      );
      expect(
        resolveNotificationPermissionStatus(
          enabled: true,
          hasRequestedPermission: true,
        ),
        NotificationPermissionStatus.granted,
      );
    },
  );

  test('monthly platform scheduling stays one-time to preserve anchor day', () {
    expect(
      notificationDateTimeComponents(RepeatRule.daily),
      DateTimeComponents.time,
    );
    expect(
      notificationDateTimeComponents(RepeatRule.weekly),
      DateTimeComponents.dayOfWeekAndTime,
    );
    expect(notificationDateTimeComponents(RepeatRule.monthly), isNull);
  });

  test(
    'monthly schedule preloads twelve stable one-time occurrences',
    () async {
      final location = tz.getLocation('Asia/Shanghai');
      final platform = _FakeNotificationPlatform()
        ..permissionStatus = NotificationPermissionStatus.granted;
      final coordinator = _coordinator(
        platform: platform,
        location: location,
        now: () => tz.TZDateTime(location, 2026, 1, 31, 19),
      );
      final task = _task(
        'task-1',
        reminderAt: tz.TZDateTime(location, 2026, 1, 31, 18, 45),
        repeatRule: RepeatRule.monthly,
      );

      await coordinator.schedule(task);

      expect(platform.scheduled, hasLength(12));
      expect(
        platform.scheduled.map((request) => request.id).toSet(),
        hasLength(12),
      );
      expect(
        platform.scheduled[0].scheduledDate,
        tz.TZDateTime(location, 2026, 2, 28, 18, 45),
      );
      expect(
        platform.scheduled[1].scheduledDate,
        tz.TZDateTime(location, 2026, 3, 31, 18, 45),
      );
      expect(
        platform.scheduled.every(
          (request) => request.repeatRule == RepeatRule.none,
        ),
        isTrue,
      );
    },
  );

  test(
    'reconcile fills a missing monthly occurrence from the twelve month set',
    () async {
      final location = tz.getLocation('Asia/Shanghai');
      final task = _task(
        'task-1',
        reminderAt: tz.TZDateTime(location, 2026, 1, 31, 18, 45),
        repeatRule: RepeatRule.monthly,
      );
      final expected = monthlyTaskNotifications(
        task: task,
        now: tz.TZDateTime(location, 2026, 1, 31, 19),
        location: location,
      );
      final platform = _FakeNotificationPlatform()
        ..permissionStatus = NotificationPermissionStatus.granted
        ..pending.addAll([
          for (final request in expected.skip(1))
            PendingNotification(id: request.id, payload: request.payload),
        ]);
      final coordinator = _coordinator(
        platform: platform,
        repository: _MemoryTaskRepository(tasks: [task]),
        location: location,
        now: () => tz.TZDateTime(location, 2026, 1, 31, 19),
      );

      await coordinator.reconcile();

      expect(platform.scheduled, hasLength(1));
      expect(platform.scheduled.single.id, expected.first.id);
      expect(
        platform.scheduled.single.scheduledDate,
        tz.TZDateTime(location, 2026, 2, 28, 18, 45),
      );
    },
  );

  test(
    'after the first monthly trigger the next month remains scheduled',
    () async {
      final location = tz.getLocation('Asia/Shanghai');
      final task = _task(
        'task-1',
        reminderAt: tz.TZDateTime(location, 2026, 1, 31, 18, 45),
        repeatRule: RepeatRule.monthly,
      );
      final initial = monthlyTaskNotifications(
        task: task,
        now: tz.TZDateTime(location, 2026, 1, 31, 19),
        location: location,
      );
      final platform = _FakeNotificationPlatform()
        ..permissionStatus = NotificationPermissionStatus.granted
        ..pending.addAll([
          for (final request in initial.skip(1))
            PendingNotification(id: request.id, payload: request.payload),
        ]);
      final coordinator = _coordinator(
        platform: platform,
        repository: _MemoryTaskRepository(tasks: [task]),
        location: location,
        now: () => tz.TZDateTime(location, 2026, 2, 28, 19),
      );

      await coordinator.reconcile();

      final march = initial[1];
      expect(platform.pending.any((pending) => pending.id == march.id), isTrue);
      expect(platform.scheduled, hasLength(1));
      expect(
        platform.scheduled.single.scheduledDate,
        tz.TZDateTime(location, 2027, 2, 28, 18, 45),
      );
    },
  );

  test(
    'permission is requested once only while status is not determined',
    () async {
      final platform = _FakeNotificationPlatform()
        ..permissionStatus = NotificationPermissionStatus.notDetermined
        ..requestedStatuses.addAll([
          NotificationPermissionStatus.denied,
          NotificationPermissionStatus.granted,
        ]);
      final coordinator = _coordinator(platform: platform);
      final task = _task('task-1');

      expect(
        await coordinator.schedule(task),
        ReminderScheduleStatus.permissionDenied,
      );
      expect(platform.scheduled, isEmpty);

      expect(
        await coordinator.schedule(task),
        ReminderScheduleStatus.permissionDenied,
      );
      expect(platform.permissionRequests, 1);
      expect(platform.scheduled, isEmpty);

      expect(
        await coordinator.requestPermission(),
        NotificationPermissionStatus.granted,
      );
      expect(
        await coordinator.schedule(task),
        ReminderScheduleStatus.scheduled,
      );
      expect(platform.permissionRequests, 2);
      expect(platform.scheduled.single.taskId, 'task-1');
    },
  );

  test('denied permission never triggers an automatic request', () async {
    final platform = _FakeNotificationPlatform()
      ..permissionStatus = NotificationPermissionStatus.denied;
    final coordinator = _coordinator(platform: platform);

    expect(
      await coordinator.schedule(_task('task-1')),
      ReminderScheduleStatus.permissionDenied,
    );
    expect(platform.permissionRequests, 0);
  });

  test(
    'reconcile cancels orphan and schedules missing without permission prompt',
    () async {
      final repository = _MemoryTaskRepository(
        tasks: [_task('missing'), _task('present')],
      );
      final platform = _FakeNotificationPlatform()
        ..permissionStatus = NotificationPermissionStatus.granted
        ..pending.addAll([
          PendingNotification(
            id: taskNotificationId('orphan'),
            payload: taskNotificationPayload('orphan'),
          ),
          PendingNotification(
            id: taskNotificationId('present'),
            payload: taskNotificationPayload('present'),
          ),
        ]);
      final coordinator = _coordinator(
        platform: platform,
        repository: repository,
      );

      final report = await coordinator.reconcile();

      expect(platform.permissionRequests, 0);
      expect(platform.cancelledIds, [taskNotificationId('orphan')]);
      expect(platform.scheduled.map((request) => request.taskId), ['missing']);
      expect(report.cancelledOrphanTaskIds, ['orphan']);
      expect(report.scheduledMissingTaskIds, ['missing']);
    },
  );

  test('reconcile marks a task when scheduling fails', () async {
    final repository = _MemoryTaskRepository(tasks: [_task('task-1')]);
    final platform = _FakeNotificationPlatform()
      ..permissionStatus = NotificationPermissionStatus.granted
      ..scheduleFailures.add('task-1');
    final coordinator = _coordinator(
      platform: platform,
      repository: repository,
    );

    final report = await coordinator.reconcile();

    expect(report.failedTaskIds, ['task-1']);
    expect(repository.tasks.single.reminderSchedulingFailed, isTrue);
  });

  test(
    'reconcile clears a persisted failure when every request is pending',
    () async {
      final task = _task('task-1').copyWith(reminderSchedulingFailed: true);
      final repository = _MemoryTaskRepository(tasks: [task]);
      final platform = _FakeNotificationPlatform()
        ..permissionStatus = NotificationPermissionStatus.granted
        ..pending.add(
          PendingNotification(
            id: taskNotificationId('task-1'),
            payload: taskNotificationPayload('task-1'),
          ),
        );
      final coordinator = _coordinator(
        platform: platform,
        repository: repository,
      );

      await coordinator.reconcile();

      expect(repository.tasks.single.reminderSchedulingFailed, isFalse);
    },
  );

  test('cancel removes both the task reminder and its snooze', () async {
    final platform = _FakeNotificationPlatform();
    final coordinator = _coordinator(platform: platform);

    await coordinator.cancel('task-1');

    expect(platform.cancelledIds, [
      taskNotificationId('task-1'),
      taskSnoozeNotificationId('task-1'),
    ]);
  });

  test('reconcile cancels an orphaned snooze', () async {
    final platform = _FakeNotificationPlatform()
      ..permissionStatus = NotificationPermissionStatus.granted
      ..pending.add(
        PendingNotification(
          id: taskSnoozeNotificationId('orphan'),
          payload: taskSnoozeNotificationPayload('orphan'),
        ),
      );
    final coordinator = _coordinator(platform: platform);

    await coordinator.reconcile();

    expect(platform.cancelledIds, [taskSnoozeNotificationId('orphan')]);
  });

  test(
    'reconcile does not treat a snooze as the recurring task reminder',
    () async {
      final repository = _MemoryTaskRepository(tasks: [_task('task-1')]);
      final platform = _FakeNotificationPlatform()
        ..permissionStatus = NotificationPermissionStatus.granted
        ..pending.add(
          PendingNotification(
            id: taskSnoozeNotificationId('task-1'),
            payload: taskSnoozeNotificationPayload('task-1'),
          ),
        );
      final coordinator = _coordinator(
        platform: platform,
        repository: repository,
      );

      await coordinator.reconcile();

      expect(platform.scheduled.map((request) => request.taskId), ['task-1']);
    },
  );

  test(
    'action stream parses complete snooze and default open actions',
    () async {
      final platform = _FakeNotificationPlatform();
      final coordinator = _coordinator(platform: platform);
      await coordinator.initialize();
      final actions = <NotificationAction>[];
      final subscription = coordinator.actions.listen(actions.add);
      addTearDown(subscription.cancel);

      platform.respond('complete', taskNotificationPayload('task-1'));
      platform.respond('snooze_10', taskNotificationPayload('task-2'));
      platform.respond(null, taskNotificationPayload('task-3'));
      await Future<void>.delayed(Duration.zero);

      expect(actions, [
        const NotificationAction.complete('task-1'),
        const NotificationAction.snooze10('task-2'),
        const NotificationAction.open('task-3'),
      ]);
    },
  );

  test('invalid action and launch payloads are ignored', () async {
    final platform = _FakeNotificationPlatform()
      ..launchResponse = const NotificationResponseData(
        actionId: null,
        payload: '{"type":"task","taskId":7}',
      );
    final coordinator = _coordinator(platform: platform);
    await coordinator.initialize();
    final actions = <NotificationAction>[];
    final subscription = coordinator.actions.listen(actions.add);
    addTearDown(subscription.cancel);

    platform.respond('complete', '');
    platform.respond('unknown', taskNotificationPayload('task-1'));
    platform.respond('complete', '{"type":"focus","taskId":"task-1"}');
    await Future<void>.delayed(Duration.zero);

    expect(actions, isEmpty);
    expect(await coordinator.launchAction(), isNull);
  });

  test('launch payload defaults to open action', () async {
    final platform = _FakeNotificationPlatform()
      ..launchResponse = NotificationResponseData(
        actionId: null,
        payload: taskNotificationPayload('task-1'),
      );
    final coordinator = _coordinator(platform: platform);

    await coordinator.initialize();

    expect(
      await coordinator.launchAction(),
      const NotificationAction.open('task-1'),
    );
  });

  test(
    'snooze schedules one-time reminder without changing repeat anchor',
    () async {
      final location = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(location, 2026, 3, 8, 1, 55);
      final task = _task(
        'task-1',
        reminderAt: tz.TZDateTime(location, 2026, 3, 7, 9),
        repeatRule: RepeatRule.daily,
      );
      final platform = _FakeNotificationPlatform()
        ..permissionStatus = NotificationPermissionStatus.granted;
      final coordinator = _coordinator(
        platform: platform,
        location: location,
        now: () => now,
      );

      await coordinator.snooze(task);

      expect(platform.scheduled.single.id, isNot(taskNotificationId('task-1')));
      expect(platform.scheduled.single.repeatRule, RepeatRule.none);
      expect(
        platform.scheduled.single.scheduledDate,
        tz.TZDateTime(location, 2026, 3, 8, 3, 5),
      );
      expect(task.repeatRule, RepeatRule.daily);
      expect(task.reminderAt, tz.TZDateTime(location, 2026, 3, 7, 9).toUtc());
    },
  );
}

NotificationCoordinator _coordinator({
  required _FakeNotificationPlatform platform,
  _MemoryTaskRepository? repository,
  tz.Location? location,
  DateTime Function()? now,
}) {
  return NotificationCoordinator(
    platform: platform,
    repository: repository ?? _MemoryTaskRepository(),
    location: location ?? tz.getLocation('Asia/Shanghai'),
    now: now ?? () => DateTime.utc(2026, 6, 13),
  );
}

TaskItem _task(
  String id, {
  DateTime? reminderAt,
  RepeatRule repeatRule = RepeatRule.none,
}) {
  return TaskItem.create(
    id: id,
    title: id,
    listId: 'inbox',
    createdAt: DateTime.utc(2026),
    reminderAt: reminderAt ?? DateTime.utc(2026, 6, 15),
    repeatRule: repeatRule,
  );
}

class _FakeNotificationPlatform implements NotificationPlatform {
  NotificationPermissionStatus permissionStatus =
      NotificationPermissionStatus.notDetermined;
  final List<NotificationPermissionStatus> requestedStatuses = [];
  final List<PendingNotification> pending = [];
  final List<ScheduledNotification> scheduled = [];
  final List<int> cancelledIds = [];
  final Set<String> scheduleFailures = {};
  NotificationResponseData? launchResponse;
  int initializeCalls = 0;
  int permissionRequests = 0;
  void Function(NotificationResponseData response)? _onResponse;

  @override
  Future<void> initialize({
    required void Function(NotificationResponseData response) onResponse,
  }) async {
    initializeCalls += 1;
    _onResponse = onResponse;
  }

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async =>
      permissionStatus;

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    permissionRequests += 1;
    permissionStatus = requestedStatuses.removeAt(0);
    return permissionStatus;
  }

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    scheduled.add(notification);
    if (scheduleFailures.contains(notification.taskId)) {
      throw StateError('schedule failed');
    }
  }

  @override
  Future<void> cancel(int notificationId) async {
    cancelledIds.add(notificationId);
  }

  @override
  Future<List<PendingNotification>> pendingNotifications() async =>
      List.unmodifiable(pending);

  @override
  Future<NotificationResponseData?> launchNotificationResponse() async =>
      launchResponse;

  void respond(String? actionId, String? payload) {
    _onResponse!(
      NotificationResponseData(actionId: actionId, payload: payload),
    );
  }
}

class _MemoryTaskRepository implements TaskRepository {
  _MemoryTaskRepository({List<TaskItem> tasks = const []})
    : tasks = List.of(tasks);

  final List<TaskItem> tasks;

  @override
  Future<RepositorySnapshot> loadSnapshot() async => RepositorySnapshot(
    lists: const [TaskList(id: 'inbox', name: 'Inbox', colorValue: 0)],
    tasks: tasks,
  );

  @override
  Future<List<TaskItem>> loadTasks() async => List.unmodifiable(tasks);

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
