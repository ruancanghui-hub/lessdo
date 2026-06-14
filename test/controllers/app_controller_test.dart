import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/controllers/app_controller.dart';
import 'package:lessdo/data/settings_repository.dart';
import 'package:lessdo/data/task_repository.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/app_settings.dart';
import 'package:lessdo/models/focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';
import 'package:lessdo/notifications/notification_coordinator.dart';
import 'package:lessdo/notifications/reminder_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('failed repository save does not publish controller tasks', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = _ThrowingTaskRepository();
    final controller = AppController(
      repository: repository,
      settingsRepository: SettingsRepository(
        await SharedPreferences.getInstance(),
      ),
      notifications: _FakeNotificationCoordinator(),
      idFactory: () => 'task-1',
      now: () => DateTime.utc(2026),
    );
    await controller.load();
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    await expectLater(
      controller.addTask(title: 'Pay bill', listId: 'inbox'),
      throwsA(isA<RepositoryWriteException>()),
    );

    expect(controller.tasks, isEmpty);
    expect(notifications, 0);
  });

  test('settings repository and controller round trip every setting', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settingsRepository = SettingsRepository(preferences);
    final controller = AppController(
      repository: _MemoryTaskRepository(),
      settingsRepository: settingsRepository,
      notifications: _FakeNotificationCoordinator(),
    );
    const settings = AppSettings(
      themeId: 'dark',
      largeText: true,
      faceId: true,
      hasCompletedOnboarding: true,
      language: AppLanguage.simplifiedChinese,
    );

    await controller.load();
    await controller.updateSettings(settings);

    expect(controller.settings.toJson(), settings.toJson());
    expect((await settingsRepository.load()).toJson(), settings.toJson());
  });

  test(
    'queued settings transforms preserve concurrent field updates',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final settingsRepository = SettingsRepository(preferences);
      final controller = AppController(
        repository: _MemoryTaskRepository(),
        settingsRepository: settingsRepository,
        notifications: _FakeNotificationCoordinator(),
      );
      await controller.load();

      final themeUpdate = controller.updateSettingsWith(
        (current) => current.copyWith(themeId: 'dark'),
      );
      final textUpdate = controller.updateSettingsWith(
        (current) => current.copyWith(largeText: true),
      );
      await Future.wait([themeUpdate, textUpdate]);

      expect(controller.settings.themeId, 'dark');
      expect(controller.settings.largeText, isTrue);
      final persisted = await settingsRepository.load();
      expect(persisted.themeId, 'dark');
      expect(persisted.largeText, isTrue);
    },
  );

  test(
    'notification scheduling failure persists and publishes retry state',
    () async {
      final repository = _MemoryTaskRepository();
      final notifications = _FakeNotificationCoordinator()..failSchedule = true;
      final controller = await _controller(
        repository: repository,
        notifications: notifications,
      );

      final task = await controller.addTask(
        title: 'Pay bill',
        reminderAt: DateTime.utc(2026, 1, 2),
      );

      expect(task.reminderSchedulingFailed, isTrue);
      expect(controller.tasks.single.reminderSchedulingFailed, isTrue);
      expect(repository.tasks.single.reminderSchedulingFailed, isTrue);
      expect(controller.operationWarnings.single.operation, 'scheduleReminder');

      notifications.failSchedule = false;
      await controller.retryReminder(task.id);

      expect(controller.tasks.single.reminderSchedulingFailed, isFalse);
      expect(repository.tasks.single.reminderSchedulingFailed, isFalse);
      expect(notifications.scheduledTaskIds, ['task-1', 'task-1']);
    },
  );

  test(
    'permission denial marks reminder failed without scheduling and retry asks again',
    () async {
      final repository = _MemoryTaskRepository();
      final notifications = _FakeNotificationCoordinator()
        ..permissionGranted = false;
      final controller = await _controller(
        repository: repository,
        notifications: notifications,
      );

      final task = await controller.addTask(
        title: 'Pay bill',
        reminderAt: DateTime.utc(2026, 1, 2),
      );

      expect(notifications.permissionRequests, 1);
      expect(notifications.scheduledTaskIds, isEmpty);
      expect(task.reminderSchedulingFailed, isTrue);
      expect(repository.tasks.single.reminderSchedulingFailed, isTrue);
      expect(controller.operationWarnings.single.operation, 'scheduleReminder');

      notifications.permissionGranted = true;
      await controller.retryReminder(task.id);

      expect(notifications.permissionRequests, 2);
      expect(notifications.scheduledTaskIds, ['task-1']);
      expect(notifications.schedulePermissionRequests, [true, false]);
      expect(controller.tasks.single.reminderSchedulingFailed, isFalse);
    },
  );

  test(
    'failed reminder status persistence reports partial failure and reloads',
    () async {
      final repository = _FailSecondSaveTaskRepository();
      final controller = await _controller(
        repository: repository,
        notifications: _FakeNotificationCoordinator()..failSchedule = true,
      );

      await expectLater(
        controller.addTask(
          title: 'Pay bill',
          reminderAt: DateTime.utc(2026, 1, 2),
        ),
        throwsA(isA<OperationPartialFailure>()),
      );

      expect(controller.tasks.single.reminderSchedulingFailed, isFalse);
      expect(repository.loadSnapshotCalls, 2);
    },
  );

  test(
    'partial reminder failure keeps first committed save when reload fails',
    () async {
      final repository = _FailSecondSaveTaskRepository()
        ..failSnapshotAfterInitialLoad = true;
      final controller = await _controller(
        repository: repository,
        notifications: _FakeNotificationCoordinator()..failSchedule = true,
      );

      await expectLater(
        controller.addTask(
          title: 'Pay bill',
          reminderAt: DateTime.utc(2026, 1, 2),
        ),
        throwsA(isA<OperationPartialFailure>()),
      );

      expect(controller.tasks.single.title, 'Pay bill');
      expect(controller.tasks.single.reminderSchedulingFailed, isFalse);
    },
  );

  test(
    'deleteTasks uses transaction snapshot and cancellation failures warn',
    () async {
      final repository = _MemoryTaskRepository(
        lists: const [
          TaskList(id: 'inbox', name: 'Inbox', colorValue: 0),
          TaskList(id: 'work', name: 'Work', colorValue: 1, sortOrder: 1),
        ],
        tasks: [
          _task('task-1', listId: 'work'),
          _task('task-2', listId: 'work'),
        ],
      );
      final notifications = _FakeNotificationCoordinator()
        ..failedCancellationIds.add('task-2');
      final controller = await _controller(
        repository: repository,
        notifications: notifications,
      );
      repository.failReads = true;

      await controller.deleteList('work', ListDeletionStrategy.deleteTasks);

      expect(controller.lists.map((list) => list.id), ['inbox']);
      expect(controller.tasks, isEmpty);
      expect(repository.loadSnapshotCalls, 1);
      expect(notifications.cancelledTaskIds, ['task-1', 'task-2']);
      expect(controller.operationWarnings.single.failedTaskIds, ['task-2']);
    },
  );

  test(
    'moveToInbox keeps reminders and publishes transaction snapshot',
    () async {
      final repository = _MemoryTaskRepository(
        lists: const [
          TaskList(id: 'inbox', name: 'Inbox', colorValue: 0),
          TaskList(id: 'work', name: 'Work', colorValue: 1, sortOrder: 1),
        ],
        tasks: [_task('task-1', listId: 'work')],
      );
      final notifications = _FakeNotificationCoordinator();
      final controller = await _controller(
        repository: repository,
        notifications: notifications,
      );
      repository.failReads = true;

      await controller.deleteList('work', ListDeletionStrategy.moveToInbox);

      expect(controller.tasks.single.listId, 'inbox');
      expect(repository.loadSnapshotCalls, 1);
      expect(notifications.cancelledTaskIds, isEmpty);
    },
  );

  test(
    'completeFocus keeps completion when notification cancellation fails',
    () async {
      final repository = _MemoryTaskRepository(tasks: [_task('task-1')]);
      final notifications = _FakeNotificationCoordinator()
        ..failedCancellationIds.add('task-1');
      final controller = await _controller(
        repository: repository,
        notifications: notifications,
      );
      final history = FocusSession(
        id: 'history-1',
        taskId: 'task-1',
        taskTitle: 'Deep work',
        minutes: 1,
        completedAt: DateTime.utc(2026, 1, 1, 0, 1),
      );

      await controller.completeFocus(history, completedTaskId: 'task-1');

      expect(controller.tasks.single.completed, isTrue);
      expect(repository.tasks.single.completed, isTrue);
      expect(controller.operationWarnings.single.failedTaskIds, ['task-1']);
    },
  );

  test(
    'focus controller completion keeps history and warns on task reminder cancellation failure',
    () async {
      final repository = _MemoryTaskRepository(tasks: [_task('task-1')]);
      final notifications = _FakeNotificationCoordinator()
        ..failedCancellationIds.add('task-1');
      final controller = await _controller(
        repository: repository,
        notifications: notifications,
      );
      await controller.focusController.startCountUp(
        taskId: 'task-1',
        taskTitle: 'Deep work',
      );

      await controller.focusController.complete(completeTask: true);

      expect(controller.focusHistory, hasLength(1));
      expect(controller.tasks.single.completed, isTrue);
      expect(repository.tasks.single.completed, isTrue);
      expect(notifications.cancelledTaskIds, ['task-1']);
      expect(
        controller.operationWarnings.single.operation,
        'completeFocusReminder',
      );
      expect(controller.operationWarnings.single.failedTaskIds, ['task-1']);
    },
  );

  test('app load succeeds when expired focus cancellation fails', () async {
    final repository = _MemoryTaskRepository();
    await repository.saveActiveFocus(
      ActiveFocusSession.countdown(
        id: 'expired',
        startedAt: DateTime.utc(2025, 12, 31, 23, 58),
        duration: const Duration(minutes: 1),
      ),
    );
    final notifications = _FakeNotificationCoordinator()
      ..failedFocusCancellationIds.add('expired');

    final controller = await _controller(
      repository: repository,
      notifications: notifications,
    );

    expect(controller.activeFocus, isNull);
    expect(controller.focusHistory, hasLength(1));
    expect(controller.focusController.lastWarning?.sessionId, 'expired');
  });

  test(
    'task and list mutations serialize without orphaning reminders',
    () async {
      final saveStarted = Completer<void>();
      final allowSave = Completer<void>();
      final repository = _BlockingSaveTaskRepository(
        saveStarted: saveStarted,
        allowSave: allowSave,
        lists: const [
          TaskList(id: 'inbox', name: 'Inbox', colorValue: 0),
          TaskList(id: 'work', name: 'Work', colorValue: 1, sortOrder: 1),
        ],
      );
      final notifications = _FakeNotificationCoordinator();
      final controller = await _controller(
        repository: repository,
        notifications: notifications,
      );

      final addFuture = controller.addTask(
        title: 'Queued task',
        listId: 'work',
        reminderAt: DateTime.utc(2026, 1, 2),
      );
      await saveStarted.future;
      final deleteFuture = controller.deleteList(
        'work',
        ListDeletionStrategy.deleteTasks,
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.deleteListCalls, 0);

      allowSave.complete();
      final added = await addFuture;
      await deleteFuture;

      expect(added.id, 'task-1');
      expect(repository.tasks, isEmpty);
      expect(controller.tasks, isEmpty);
      expect(controller.lists.map((list) => list.id), ['inbox']);
      expect(notifications.scheduledTaskIds, ['task-1']);
      expect(notifications.cancelledTaskIds, ['task-1']);
    },
  );

  test('failed mutation does not poison the operation queue', () async {
    final repository = _FailFirstSaveTaskRepository();
    final controller = await _controller(
      repository: repository,
      notifications: _FakeNotificationCoordinator(),
    );

    final first = controller.addTask(title: 'Fails');
    final second = controller.addTask(title: 'Succeeds');

    await expectLater(first, throwsA(isA<RepositoryWriteException>()));
    final saved = await second;

    expect(saved.title, 'Succeeds');
    expect(controller.tasks.single.title, 'Succeeds');
  });

  test('warnings deduplicate and can be acknowledged', () async {
    final repository = _MemoryTaskRepository(tasks: [_task('task-1')]);
    final notifications = _FakeNotificationCoordinator()
      ..permissionGranted = false;
    final controller = await _controller(
      repository: repository,
      notifications: notifications,
    );

    await controller.retryReminder('task-1');
    await controller.retryReminder('task-1');

    expect(controller.operationWarnings, hasLength(1));
    expect(controller.operationWarnings.single.failedTaskIds, ['task-1']);

    controller.clearOperationWarnings();

    expect(controller.operationWarnings, isEmpty);
  });

  test('warnings retain only the most recent fifty entries', () async {
    final tasks = [
      for (var index = 0; index < 55; index++) _task('task-$index'),
    ];
    final controller = await _controller(
      repository: _MemoryTaskRepository(tasks: tasks),
      notifications: _FakeNotificationCoordinator()..permissionGranted = false,
    );

    for (final task in tasks) {
      await controller.retryReminder(task.id);
    }

    expect(controller.operationWarnings, hasLength(50));
    expect(controller.operationWarnings.first.failedTaskIds, ['task-5']);
    expect(controller.operationWarnings.last.failedTaskIds, ['task-54']);
  });

  test('notification complete action completes and cancels the task', () async {
    final repository = _MemoryTaskRepository(tasks: [_task('task-1')]);
    final notifications = _FakeNotificationCoordinator();
    final controller = await _controller(
      repository: repository,
      notifications: notifications,
    );

    await controller.handleNotificationAction(
      const NotificationAction.complete('task-1'),
    );

    expect(controller.tasks.single.completed, isTrue);
    expect(repository.tasks.single.completed, isTrue);
    expect(notifications.cancelledTaskIds, ['task-1']);
  });

  test('notification snooze action schedules a one-time snooze', () async {
    final repository = _MemoryTaskRepository(tasks: [_task('task-1')]);
    final notifications = _FakeNotificationCoordinator();
    final controller = await _controller(
      repository: repository,
      notifications: notifications,
    );

    await controller.handleNotificationAction(
      const NotificationAction.snooze10('task-1'),
    );

    expect(notifications.snoozedTaskIds, ['task-1']);
    expect(controller.tasks.single.repeatRule, RepeatRule.none);
  });

  test('notification open action emits a navigation task id', () async {
    final controller = await _controller(
      repository: _MemoryTaskRepository(tasks: [_task('task-1')]),
      notifications: _FakeNotificationCoordinator(),
    );

    final navigation = expectLater(
      controller.openTaskRequests,
      emits('task-1'),
    );
    await controller.handleNotificationAction(
      const NotificationAction.open('task-1'),
    );

    await navigation;
  });

  test('launch open action is buffered until RootPage subscribes', () async {
    final notifications = _FakeNotificationCoordinator()
      ..launchNotificationAction = const NotificationAction.open('task-1');
    final controller = await _controller(
      repository: _MemoryTaskRepository(tasks: [_task('task-1')]),
      notifications: notifications,
    );

    await expectLater(controller.openTaskRequests, emits('task-1'));
  });

  test('notification action reconciles reminders after handling', () async {
    final notifications = _FakeNotificationCoordinator();
    final controller = await _controller(
      repository: _MemoryTaskRepository(tasks: [_task('task-1')]),
      notifications: notifications,
    );
    final reconcilesAfterLoad = notifications.reconcileCalls;

    await controller.handleNotificationAction(
      const NotificationAction.open('task-1'),
    );

    expect(notifications.reconcileCalls, reconcilesAfterLoad + 1);
  });

  test(
    'reconcile recovery clears the controller reminder failure state',
    () async {
      final notifications = _FakeNotificationCoordinator()
        ..recoveredTaskIds.add('task-1');
      final controller = await _controller(
        repository: _MemoryTaskRepository(
          tasks: [_task('task-1').copyWith(reminderSchedulingFailed: true)],
        ),
        notifications: notifications,
      );

      expect(controller.tasks.single.reminderSchedulingFailed, isFalse);
    },
  );

  test(
    'external edit during reconcile is preserved by atomic state patch',
    () async {
      final repository = _MemoryTaskRepository(tasks: [_task('task-1')]);
      final notifications = _FakeNotificationCoordinator();
      final controller = await _controller(
        repository: repository,
        notifications: notifications,
      );
      final started = Completer<void>();
      final allow = Completer<void>();
      notifications
        ..nextReconcileStarted = started
        ..allowNextReconcile = allow
        ..failedTaskIds.add('task-1');

      final reconciling = controller.reconcileReminders();
      await started.future;
      await repository.saveTask(
        repository.tasks.single.copyWith(
          title: 'Edited during reconcile',
          completed: true,
          completedAt: DateTime.utc(2026, 6, 14),
        ),
      );
      allow.complete();
      await reconciling;

      final task = controller.tasks.single;
      expect(task.title, 'Edited during reconcile');
      expect(task.completed, isTrue);
      expect(task.reminderSchedulingFailed, isTrue);
    },
  );
}

class _ThrowingTaskRepository extends _MemoryTaskRepository {
  @override
  Future<void> saveTask(TaskItem task) async {
    throw StateError('disk full');
  }
}

class _FailSecondSaveTaskRepository extends _MemoryTaskRepository {
  var saveCalls = 0;
  var patchCalls = 0;

  @override
  Future<void> saveTask(TaskItem task) async {
    saveCalls += 1;
    await super.saveTask(task);
  }

  @override
  Future<TaskItem?> patchReminderSchedulingState(
    String taskId,
    bool failed,
  ) async {
    patchCalls += 1;
    throw StateError('status write failed');
  }
}

class _FailFirstSaveTaskRepository extends _MemoryTaskRepository {
  var saveCalls = 0;

  @override
  Future<void> saveTask(TaskItem task) async {
    saveCalls += 1;
    if (saveCalls == 1) throw StateError('first write failed');
    await super.saveTask(task);
  }
}

class _BlockingSaveTaskRepository extends _MemoryTaskRepository {
  _BlockingSaveTaskRepository({
    required this.saveStarted,
    required this.allowSave,
    super.lists,
  });

  final Completer<void> saveStarted;
  final Completer<void> allowSave;
  var deleteListCalls = 0;

  @override
  Future<void> saveTask(TaskItem task) async {
    if (!saveStarted.isCompleted) saveStarted.complete();
    await allowSave.future;
    await super.saveTask(task);
  }

  @override
  Future<RepositorySnapshot> deleteList(
    String listId,
    ListDeletionStrategy strategy,
  ) async {
    deleteListCalls += 1;
    return super.deleteList(listId, strategy);
  }
}

class _MemoryTaskRepository implements TaskRepository {
  _MemoryTaskRepository({List<TaskList>? lists, List<TaskItem>? tasks})
    : _lists = List.of(
        lists ?? const [TaskList(id: 'inbox', name: 'Inbox', colorValue: 0)],
      ),
      _tasks = List.of(tasks ?? const []);

  final List<TaskList> _lists;
  final List<TaskItem> _tasks;
  final List<FocusSession> _history = [];
  ActiveFocusSession? _activeFocus;
  final Map<String, int> _notificationIds = {};
  bool failReads = false;
  bool failSnapshotAfterInitialLoad = false;
  int loadSnapshotCalls = 0;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  @override
  Future<void> completeFocus(
    FocusSession history, {
    String? completedTaskId,
  }) async {
    _history.insert(0, history);
    _activeFocus = null;
    if (completedTaskId != null) {
      final index = _tasks.indexWhere((task) => task.id == completedTaskId);
      _tasks[index] = _tasks[index].copyWith(
        completed: true,
        completedAt: history.completedAt,
        updatedAt: history.completedAt,
      );
    }
  }

  @override
  Future<RepositorySnapshot> deleteList(
    String listId,
    ListDeletionStrategy strategy,
  ) async {
    if (strategy == ListDeletionStrategy.deleteTasks) {
      _tasks.removeWhere((task) => task.listId == listId);
    } else {
      for (var index = 0; index < _tasks.length; index++) {
        if (_tasks[index].listId == listId) {
          _tasks[index] = _tasks[index].copyWith(listId: 'inbox');
        }
      }
    }
    _lists.removeWhere((list) => list.id == listId);
    return RepositorySnapshot(lists: _lists, tasks: _tasks);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
  }

  @override
  Future<ActiveFocusSession?> loadActiveFocus() async => _activeFocus;

  @override
  Future<List<FocusSession>> loadFocusHistory() async => List.of(_history);

  @override
  Future<List<TaskList>> loadLists() async {
    if (failReads) throw StateError('read disabled');
    return List.of(_lists);
  }

  @override
  Future<RepositorySnapshot> loadSnapshot() async {
    loadSnapshotCalls += 1;
    if (failSnapshotAfterInitialLoad && loadSnapshotCalls > 1) {
      throw StateError('snapshot unavailable');
    }
    return RepositorySnapshot(lists: _lists, tasks: _tasks);
  }

  @override
  Future<List<TaskItem>> loadTasks() async {
    if (failReads) throw StateError('read disabled');
    return List.of(_tasks);
  }

  @override
  Future<void> saveActiveFocus(ActiveFocusSession? session) async {
    _activeFocus = session;
  }

  @override
  Future<void> saveList(TaskList list) async {}

  @override
  Future<void> saveTask(TaskItem task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
  }

  @override
  Future<TaskItem?> patchReminderSchedulingState(
    String taskId,
    bool failed,
  ) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return null;
    _tasks[index] = _tasks[index].copyWith(reminderSchedulingFailed: failed);
    return _tasks[index];
  }

  @override
  Future<int> notificationIdFor({
    required String taskId,
    required String occurrenceKey,
  }) async => _notificationIds.putIfAbsent(
    '$taskId|$occurrenceKey',
    () => stableNotificationId(
      NotificationIdNamespace.task,
      '$taskId:$occurrenceKey',
    ),
  );
}

class _FakeNotificationCoordinator
    implements
        NotificationCoordinatorContract,
        FocusNotificationCoordinatorContract {
  bool failSchedule = false;
  bool permissionGranted = true;
  int permissionRequests = 0;
  final Set<String> failedCancellationIds = {};
  final Set<String> failedFocusCancellationIds = {};
  final List<String> scheduledTaskIds = [];
  final List<String> cancelledTaskIds = [];
  final List<String> snoozedTaskIds = [];
  final List<bool> schedulePermissionRequests = [];
  final StreamController<NotificationAction> actionController =
      StreamController<NotificationAction>.broadcast();
  NotificationAction? launchNotificationAction;
  int reconcileCalls = 0;
  final Set<String> recoveredTaskIds = {};
  final Set<String> failedTaskIds = {};
  Completer<void>? nextReconcileStarted;
  Completer<void>? allowNextReconcile;

  @override
  Stream<NotificationAction> get actions => actionController.stream;

  @override
  Future<void> cancel(String taskId) async {
    cancelledTaskIds.add(taskId);
    if (failedCancellationIds.contains(taskId)) {
      throw StateError('cancel failed');
    }
  }

  @override
  Future<void> cancelFocus(String sessionId) async {
    if (failedFocusCancellationIds.contains(sessionId)) {
      throw StateError('focus cancel failed');
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    permissionRequests += 1;
    return permissionGranted
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  @override
  Future<ReminderScheduleStatus> schedule(
    TaskItem task, {
    bool requestPermission = true,
  }) async {
    schedulePermissionRequests.add(requestPermission);
    if (requestPermission) {
      final permission = await this.requestPermission();
      if (permission != NotificationPermissionStatus.granted) {
        return ReminderScheduleStatus.permissionDenied;
      }
    }
    scheduledTaskIds.add(task.id);
    if (failSchedule) throw StateError('schedule failed');
    return ReminderScheduleStatus.scheduled;
  }

  @override
  Future<void> scheduleFocus(
    ActiveFocusSession session, {
    bool requestPermission = true,
  }) async {}

  @override
  Future<ReminderScheduleStatus> snooze(TaskItem task) async {
    snoozedTaskIds.add(task.id);
    return ReminderScheduleStatus.scheduled;
  }

  @override
  Future<NotificationAction?> launchAction() async => launchNotificationAction;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      permissionGranted
      ? NotificationPermissionStatus.granted
      : NotificationPermissionStatus.denied;

  @override
  Future<NotificationReconcileReport> reconcile() async {
    reconcileCalls += 1;
    if (nextReconcileStarted case final started?) {
      nextReconcileStarted = null;
      if (!started.isCompleted) started.complete();
      final allow = allowNextReconcile;
      allowNextReconcile = null;
      if (allow != null) await allow.future;
    }
    return NotificationReconcileReport(
      cancelledOrphanTaskIds: const [],
      scheduledMissingTaskIds: const [],
      failedTaskIds: failedTaskIds,
      recoveredTaskIds: recoveredTaskIds,
    );
  }

  @override
  Future<void> dispose() async {
    await actionController.close();
  }
}

Future<AppController> _controller({
  required _MemoryTaskRepository repository,
  required _FakeNotificationCoordinator notifications,
}) async {
  SharedPreferences.setMockInitialValues({});
  final controller = AppController(
    repository: repository,
    settingsRepository: SettingsRepository(
      await SharedPreferences.getInstance(),
    ),
    notifications: notifications,
    idFactory: () => 'task-1',
    now: () => DateTime.utc(2026),
  );
  await controller.load();
  return controller;
}

TaskItem _task(String id, {String listId = 'inbox'}) {
  return TaskItem.create(
    id: id,
    title: id,
    listId: listId,
    createdAt: DateTime.utc(2026),
    reminderAt: DateTime.utc(2026, 1, 2),
  );
}
