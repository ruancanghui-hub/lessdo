import 'dart:async';
import 'dart:convert';

import 'package:timezone/timezone.dart' as tz;

import '../data/task_repository.dart';
import '../models/task_item.dart';
import 'reminder_schedule.dart';

enum NotificationPermissionStatus { notDetermined, denied, granted }

enum ReminderScheduleStatus { scheduled, noOccurrence, permissionDenied }

enum NotificationActionType { open, complete, snooze10 }

class NotificationAction {
  const NotificationAction._(this.type, this.taskId);
  const NotificationAction.open(String taskId)
    : this._(NotificationActionType.open, taskId);
  const NotificationAction.complete(String taskId)
    : this._(NotificationActionType.complete, taskId);
  const NotificationAction.snooze10(String taskId)
    : this._(NotificationActionType.snooze10, taskId);

  final NotificationActionType type;
  final String taskId;

  @override
  bool operator ==(Object other) =>
      other is NotificationAction &&
      other.type == type &&
      other.taskId == taskId;

  @override
  int get hashCode => Object.hash(type, taskId);
}

class NotificationResponseData {
  const NotificationResponseData({required this.actionId, this.payload});
  final String? actionId;
  final String? payload;
}

class PendingNotification {
  const PendingNotification({required this.id, this.payload});
  final int id;
  final String? payload;
}

class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.taskId,
    required this.title,
    required this.body,
    required this.payload,
    required this.scheduledDate,
    required this.repeatRule,
  });

  final int id;
  final String taskId;
  final String title;
  final String body;
  final String payload;
  final tz.TZDateTime scheduledDate;
  final RepeatRule repeatRule;
}

abstract interface class NotificationPlatform {
  Future<void> initialize({
    required void Function(NotificationResponseData response) onResponse,
  });
  Future<NotificationPermissionStatus> getPermissionStatus();
  Future<NotificationPermissionStatus> requestPermission();
  Future<void> schedule(ScheduledNotification notification);
  Future<void> cancel(int notificationId);
  Future<List<PendingNotification>> pendingNotifications();
  Future<NotificationResponseData?> launchNotificationResponse();
}

abstract interface class NotificationCoordinatorContract {
  Stream<NotificationAction> get actions;
  Future<NotificationPermissionStatus> permissionStatus();
  Future<NotificationPermissionStatus> requestPermission();
  Future<ReminderScheduleStatus> schedule(
    TaskItem task, {
    bool requestPermission,
  });
  Future<void> cancel(String taskId);
  Future<ReminderScheduleStatus> snooze(TaskItem task);
  Future<NotificationAction?> launchAction();
  Future<NotificationReconcileReport> reconcile();
  Future<void> dispose();
}

class NotificationReconcileReport {
  NotificationReconcileReport({
    required Iterable<String> cancelledOrphanTaskIds,
    required Iterable<String> scheduledMissingTaskIds,
    required Iterable<String> failedTaskIds,
    Iterable<String> recoveredTaskIds = const [],
    Iterable<String> capacityLimitedTaskIds = const [],
  }) : cancelledOrphanTaskIds = _sorted(cancelledOrphanTaskIds),
       scheduledMissingTaskIds = _sorted(scheduledMissingTaskIds),
       failedTaskIds = _sorted(failedTaskIds),
       recoveredTaskIds = _sorted(recoveredTaskIds),
       capacityLimitedTaskIds = _sorted(capacityLimitedTaskIds);

  final List<String> cancelledOrphanTaskIds;
  final List<String> scheduledMissingTaskIds;
  final List<String> failedTaskIds;
  final List<String> recoveredTaskIds;
  final List<String> capacityLimitedTaskIds;

  static List<String> _sorted(Iterable<String> values) =>
      List.unmodifiable(values.toSet().toList()..sort());
}

class NotificationCoordinator implements NotificationCoordinatorContract {
  NotificationCoordinator({
    required NotificationPlatform platform,
    required TaskRepository repository,
    required tz.Location location,
    Future<tz.Location> Function()? locationProvider,
    DateTime Function()? now,
    this.maxPending = 64,
  }) : _platform = platform,
       _repository = repository,
       _location = location,
       _locationProvider = locationProvider,
       _now = now ?? DateTime.now;

  final NotificationPlatform _platform;
  final TaskRepository _repository;
  final Future<tz.Location> Function()? _locationProvider;
  final DateTime Function() _now;
  final int maxPending;
  final StreamController<NotificationAction> _actions =
      StreamController<NotificationAction>.broadcast();
  tz.Location _location;
  NotificationResponseData? _launchResponse;
  Future<void> _reconcileQueue = Future.value();
  bool _disposed = false;

  @override
  Stream<NotificationAction> get actions => _actions.stream;

  Future<void> initialize() async {
    await _platform.initialize(onResponse: _handleResponse);
    _launchResponse = await _platform.launchNotificationResponse();
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() =>
      _platform.getPermissionStatus();

  @override
  Future<NotificationPermissionStatus> requestPermission() =>
      _platform.requestPermission();

  Future<void> _refreshLocation() async {
    final provider = _locationProvider;
    if (provider != null) _location = await provider();
  }

  @override
  Future<ReminderScheduleStatus> schedule(
    TaskItem task, {
    bool requestPermission = true,
  }) async {
    var permission = await _platform.getPermissionStatus();
    if (permission == NotificationPermissionStatus.notDetermined &&
        requestPermission) {
      permission = await _platform.requestPermission();
    }
    if (permission != NotificationPermissionStatus.granted) {
      return ReminderScheduleStatus.permissionDenied;
    }
    await _refreshLocation();
    final report = await _queueReconcile(overrideTask: task);
    if (_candidatesFor(task, now: _now()).isEmpty) {
      return ReminderScheduleStatus.noOccurrence;
    }
    if (report.failedTaskIds.contains(task.id)) {
      throw StateError('Reminder scheduling failed for ${task.id}.');
    }
    return ReminderScheduleStatus.scheduled;
  }

  @override
  Future<void> cancel(String taskId) async {
    Object? firstError;
    final ids = <int>{
      for (final pending in await _platform.pendingNotifications())
        if (_parseTaskActionPayload(pending.payload) == taskId) pending.id,
    };
    for (final id in ids) {
      try {
        await _platform.cancel(id);
      } catch (error) {
        firstError ??= error;
      }
    }
    if (firstError != null) throw firstError;
  }

  @override
  Future<ReminderScheduleStatus> snooze(TaskItem task) async {
    if (await _platform.getPermissionStatus() !=
        NotificationPermissionStatus.granted) {
      return ReminderScheduleStatus.permissionDenied;
    }
    await _refreshLocation();
    final date = tz.TZDateTime.from(
      _now().add(const Duration(minutes: 10)),
      _location,
    );
    final occurrenceKey = 'snooze:${date.toUtc().microsecondsSinceEpoch}';
    await _repository.notificationIdFor(
      taskId: task.id,
      occurrenceKey: task.repeatRule.name,
    );
    final id = await _repository.notificationIdFor(
      taskId: task.id,
      occurrenceKey: occurrenceKey,
    );
    await _platform.schedule(
      _notification(
        task,
        id: id,
        date: date,
        repeatRule: RepeatRule.none,
        payload: _notificationPayload(
          task,
          type: 'task_snooze',
          occurrenceKey: occurrenceKey,
          date: date,
          repeatRule: RepeatRule.none,
        ),
      ),
    );
    return ReminderScheduleStatus.scheduled;
  }

  @override
  Future<NotificationAction?> launchAction() async {
    final response = _launchResponse;
    _launchResponse = null;
    return _parseResponse(response);
  }

  @override
  Future<NotificationReconcileReport> reconcile() => _queueReconcile();

  Future<NotificationReconcileReport> _queueReconcile({
    TaskItem? overrideTask,
  }) {
    final completer = Completer<NotificationReconcileReport>();
    _reconcileQueue = _reconcileQueue.then((_) async {
      try {
        completer.complete(await _reconcile(overrideTask: overrideTask));
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<NotificationReconcileReport> _reconcile({
    TaskItem? overrideTask,
  }) async {
    await _refreshLocation();
    final loadedTasks = await _repository.loadTasks();
    final tasks = overrideTask == null
        ? loadedTasks
        : [
            for (final task in loadedTasks)
              if (task.id == overrideTask.id) overrideTask else task,
            if (!loadedTasks.any((task) => task.id == overrideTask.id))
              overrideTask,
          ];
    final activeTaskIds = tasks
        .where((task) => !task.completed)
        .map((task) => task.id)
        .toSet();
    final pending = await _platform.pendingNotifications();
    final activeSnoozeCount = pending
        .where(
          (item) => activeTaskIds.contains(
            _parseTaskPayload(item.payload, acceptedType: 'task_snooze'),
          ),
        )
        .length;
    final availableReminderSlots = (maxPending - activeSnoozeCount).clamp(
      0,
      maxPending,
    );
    final plans = <_TaskPlan>[];
    for (final task in tasks) {
      final candidates = _candidatesFor(task, now: _now());
      if (candidates.isNotEmpty) plans.add(_TaskPlan(task, candidates));
    }

    final first = [for (final plan in plans) plan.candidates.first]
      ..sort(_compareCandidate);
    final selected = first.take(availableReminderSlots).toList();
    final selectedTaskIds = selected.map((item) => item.task.id).toSet();
    final capacity = plans
        .where((plan) => !selectedTaskIds.contains(plan.task.id))
        .map((plan) => plan.task.id)
        .toSet();
    final remaining = availableReminderSlots - selected.length;
    if (remaining > 0) {
      final extras = <_Candidate>[
        for (final plan in plans)
          if (selectedTaskIds.contains(plan.task.id))
            ...plan.candidates.skip(1),
      ]..sort(_compareCandidate);
      selected.addAll(extras.take(remaining));
    }

    final expected = await _materialize(selected);
    final expectedById = {for (final item in expected) item.id: item};
    final pendingExpectedIds = <int>{};
    final cancelled = <String>{};
    for (final item in pending) {
      final taskId = parseTaskNotificationPayload(item.payload);
      if (taskId != null) {
        final expectedItem = expectedById[item.id];
        if (expectedItem == null || expectedItem.payload != item.payload) {
          await _platform.cancel(item.id);
          cancelled.add(taskId);
        } else {
          pendingExpectedIds.add(item.id);
        }
        continue;
      }
      final snoozeTaskId = _parseTaskPayload(
        item.payload,
        acceptedType: 'task_snooze',
      );
      if (snoozeTaskId != null && !activeTaskIds.contains(snoozeTaskId)) {
        await _platform.cancel(item.id);
        cancelled.add(snoozeTaskId);
      }
    }

    final permission = await _platform.getPermissionStatus();
    final scheduled = <String>{};
    final failed = <String>{};
    final expectedByTask = <String, List<ScheduledNotification>>{};
    for (final item in expected) {
      expectedByTask.putIfAbsent(item.taskId, () => []).add(item);
    }
    for (final plan in plans) {
      if (capacity.contains(plan.task.id)) continue;
      final missing = expectedByTask[plan.task.id]!
          .where((item) => !pendingExpectedIds.contains(item.id))
          .toList();
      if (missing.isEmpty) continue;
      if (permission != NotificationPermissionStatus.granted) {
        failed.add(plan.task.id);
        continue;
      }
      try {
        for (final item in missing) {
          await _platform.schedule(item);
        }
        scheduled.add(plan.task.id);
      } catch (_) {
        failed.add(plan.task.id);
      }
    }
    final recovered = <String>{
      for (final plan in plans)
        if (plan.task.reminderSchedulingFailed &&
            !failed.contains(plan.task.id))
          plan.task.id,
    };
    return NotificationReconcileReport(
      cancelledOrphanTaskIds: cancelled,
      scheduledMissingTaskIds: scheduled,
      failedTaskIds: failed,
      recoveredTaskIds: recovered,
      capacityLimitedTaskIds: capacity,
    );
  }

  List<_Candidate> _candidatesFor(TaskItem task, {required DateTime now}) {
    if (task.completed || task.reminderAt == null) return const [];
    final anchor =
        task.reminderAnchor ??
        ReminderAnchor.fromLocal(
          tz.TZDateTime.from(task.reminderAt!, _location),
        );
    final occurrences = reminderOccurrencesForAnchor(
      anchor: anchor,
      repeatRule: task.repeatRule,
      now: now,
      location: _location,
      monthlyCount: maxPending,
    );
    return [
      for (var index = 0; index < occurrences.length; index++)
        _Candidate(
          task: task,
          occurrenceKey: task.repeatRule == RepeatRule.monthly
              ? 'monthly:${_localKey(occurrences[index])}'
              : task.repeatRule.name,
          date: occurrences[index],
          repeatRule: task.repeatRule == RepeatRule.monthly
              ? RepeatRule.none
              : task.repeatRule,
        ),
    ];
  }

  Future<List<ScheduledNotification>> _materialize(
    Iterable<_Candidate> candidates,
  ) async {
    final result = <ScheduledNotification>[];
    for (final candidate in candidates) {
      final id = await _repository.notificationIdFor(
        taskId: candidate.task.id,
        occurrenceKey: candidate.occurrenceKey,
      );
      result.add(
        _notification(
          candidate.task,
          id: id,
          date: candidate.date,
          repeatRule: candidate.repeatRule,
          payload: _notificationPayload(
            candidate.task,
            type: 'task',
            occurrenceKey: candidate.occurrenceKey,
            date: candidate.date,
            repeatRule: candidate.repeatRule,
          ),
        ),
      );
    }
    return result;
  }

  String _notificationPayload(
    TaskItem task, {
    required String type,
    required String occurrenceKey,
    required tz.TZDateTime date,
    required RepeatRule repeatRule,
  }) {
    return jsonEncode({
      'version': 2,
      'type': type,
      'taskId': task.id,
      'occurrenceKey': occurrenceKey,
      'scheduledUtc': date.toUtc().microsecondsSinceEpoch,
      'repeatRule': repeatRule.name,
      'title': task.title,
      'body': task.notes.isEmpty ? 'LessDo reminder' : task.notes,
      'timeZone': _location.name,
    });
  }

  ScheduledNotification _notification(
    TaskItem task, {
    required int id,
    required tz.TZDateTime date,
    required RepeatRule repeatRule,
    required String payload,
  }) {
    return ScheduledNotification(
      id: id,
      taskId: task.id,
      title: task.title,
      body: task.notes.isEmpty ? 'LessDo reminder' : task.notes,
      payload: payload,
      scheduledDate: date,
      repeatRule: repeatRule,
    );
  }

  void _handleResponse(NotificationResponseData response) {
    final action = _parseResponse(response);
    if (action != null && !_disposed) _actions.add(action);
  }

  NotificationAction? _parseResponse(NotificationResponseData? response) {
    if (response == null) return null;
    final taskId = _parseTaskActionPayload(response.payload);
    if (taskId == null) return null;
    return switch (response.actionId) {
      null || '' => NotificationAction.open(taskId),
      'complete' => NotificationAction.complete(taskId),
      'snooze_10' => NotificationAction.snooze10(taskId),
      _ => null,
    };
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _actions.close();
  }
}

class _TaskPlan {
  const _TaskPlan(this.task, this.candidates);
  final TaskItem task;
  final List<_Candidate> candidates;
}

class _Candidate {
  const _Candidate({
    required this.task,
    required this.occurrenceKey,
    required this.date,
    required this.repeatRule,
  });
  final TaskItem task;
  final String occurrenceKey;
  final tz.TZDateTime date;
  final RepeatRule repeatRule;
}

int _compareCandidate(_Candidate first, _Candidate second) {
  final date = first.date.compareTo(second.date);
  if (date != 0) return date;
  final task = first.task.id.compareTo(second.task.id);
  if (task != 0) return task;
  return first.occurrenceKey.compareTo(second.occurrenceKey);
}

String _localKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}T'
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

int taskNotificationId(String taskId) =>
    stableNotificationId(NotificationIdNamespace.task, taskId);

int taskSnoozeNotificationId(String taskId) =>
    stableNotificationId(NotificationIdNamespace.task, 'snooze:$taskId');

int taskMonthlyNotificationId(String taskId, DateTime occurrence) =>
    stableNotificationId(
      NotificationIdNamespace.task,
      'monthly:$taskId:${occurrence.toUtc().microsecondsSinceEpoch}',
    );

String taskNotificationPayload(String taskId) =>
    jsonEncode({'type': 'task', 'taskId': taskId});

String taskMonthlyNotificationPayload(String taskId, DateTime occurrence) =>
    jsonEncode({
      'type': 'task_monthly',
      'taskId': taskId,
      'occurrenceUtc': occurrence.toUtc().toIso8601String(),
    });

String taskSnoozeNotificationPayload(String taskId) =>
    jsonEncode({'type': 'task_snooze', 'taskId': taskId});

String? parseTaskNotificationPayload(String? payload) =>
    _parseTaskPayload(payload, acceptedType: 'task') ??
    _parseMonthlyTaskPayload(payload);

String? _parseTaskActionPayload(String? payload) =>
    parseTaskNotificationPayload(payload) ??
    _parseTaskPayload(payload, acceptedType: 'task_snooze');

String? _parseMonthlyTaskPayload(String? payload) {
  final decoded = _decodePayload(payload);
  if (decoded == null ||
      decoded['type'] != 'task_monthly' ||
      decoded['occurrenceUtc'] is! String) {
    return null;
  }
  return _validTaskId(decoded['taskId']);
}

String? _parseTaskPayload(String? payload, {required String acceptedType}) {
  final decoded = _decodePayload(payload);
  if (decoded == null || decoded['type'] != acceptedType) return null;
  return _validTaskId(decoded['taskId']);
}

Map<String, Object?>? _decodePayload(String? payload) {
  if (payload == null || payload.length > 4096) return null;
  try {
    final value = jsonDecode(payload);
    return value is Map ? Map<String, Object?>.from(value) : null;
  } catch (_) {
    return null;
  }
}

String? _validTaskId(Object? value) {
  if (value is! String || value.isEmpty || value.length > 256) return null;
  return value;
}

List<ScheduledNotification> monthlyTaskNotifications({
  required TaskItem task,
  required DateTime now,
  required tz.Location location,
}) {
  if (task.reminderAt == null || task.completed) return const [];
  final anchor =
      task.reminderAnchor ??
      ReminderAnchor.fromLocal(tz.TZDateTime.from(task.reminderAt!, location));
  final occurrences = reminderOccurrencesForAnchor(
    anchor: anchor,
    repeatRule: RepeatRule.monthly,
    now: now,
    location: location,
    monthlyCount: 12,
  );
  return [
    for (final occurrence in occurrences)
      ScheduledNotification(
        id: taskMonthlyNotificationId(task.id, occurrence),
        taskId: task.id,
        title: task.title,
        body: task.notes.isEmpty ? 'LessDo reminder' : task.notes,
        payload: taskMonthlyNotificationPayload(task.id, occurrence),
        scheduledDate: occurrence,
        repeatRule: RepeatRule.none,
      ),
  ];
}
