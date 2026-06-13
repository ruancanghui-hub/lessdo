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
}

class NotificationReconcileReport {
  NotificationReconcileReport({
    required Iterable<String> cancelledOrphanTaskIds,
    required Iterable<String> scheduledMissingTaskIds,
    required Iterable<String> failedTaskIds,
  }) : cancelledOrphanTaskIds = List.unmodifiable(cancelledOrphanTaskIds),
       scheduledMissingTaskIds = List.unmodifiable(scheduledMissingTaskIds),
       failedTaskIds = List.unmodifiable(failedTaskIds);

  final List<String> cancelledOrphanTaskIds;
  final List<String> scheduledMissingTaskIds;
  final List<String> failedTaskIds;
}

class NotificationCoordinator implements NotificationCoordinatorContract {
  NotificationCoordinator({
    required NotificationPlatform platform,
    required TaskRepository repository,
    required tz.Location location,
    DateTime Function()? now,
  }) : _platform = platform,
       _repository = repository,
       _location = location,
       _now = now ?? DateTime.now;

  final NotificationPlatform _platform;
  final TaskRepository _repository;
  final tz.Location _location;
  final DateTime Function() _now;
  final StreamController<NotificationAction> _actions =
      StreamController<NotificationAction>.broadcast();
  NotificationResponseData? _launchResponse;

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

  @override
  Future<ReminderScheduleStatus> schedule(
    TaskItem task, {
    bool requestPermission = true,
  }) async {
    var permission = await _platform.getPermissionStatus();
    if (permission != NotificationPermissionStatus.granted &&
        requestPermission) {
      permission = await _platform.requestPermission();
    }
    if (permission != NotificationPermissionStatus.granted) {
      return ReminderScheduleStatus.permissionDenied;
    }
    return _scheduleTask(task);
  }

  @override
  Future<void> cancel(String taskId) async {
    Object? firstError;
    try {
      await _platform.cancel(taskNotificationId(taskId));
    } catch (error) {
      firstError = error;
    }
    try {
      await _platform.cancel(taskSnoozeNotificationId(taskId));
    } catch (error) {
      firstError ??= error;
    }
    if (firstError != null) throw firstError;
  }

  @override
  Future<ReminderScheduleStatus> snooze(TaskItem task) async {
    final permission = await _platform.getPermissionStatus();
    if (permission != NotificationPermissionStatus.granted) {
      return ReminderScheduleStatus.permissionDenied;
    }
    final scheduledDate = tz.TZDateTime.from(
      _now().add(const Duration(minutes: 10)),
      _location,
    );
    await _platform.schedule(
      _notificationFor(
        task,
        scheduledDate: scheduledDate,
        repeatRule: RepeatRule.none,
        id: taskSnoozeNotificationId(task.id),
        payload: taskSnoozeNotificationPayload(task.id),
      ),
    );
    return ReminderScheduleStatus.scheduled;
  }

  @override
  Future<NotificationAction?> launchAction() async =>
      _parseResponse(_launchResponse);

  @override
  Future<NotificationReconcileReport> reconcile() async {
    final tasks = await _repository.loadTasks();
    final now = _now();
    final effectiveTasks = <String, TaskItem>{};
    final activeTaskIds = <String>{};
    for (final task in tasks) {
      if (task.completed) continue;
      activeTaskIds.add(task.id);
      if (task.reminderAt == null) continue;
      final occurrence = nextReminderOccurrence(
        anchor: task.reminderAt!,
        repeatRule: task.repeatRule,
        now: now,
        location: _location,
      );
      if (occurrence != null) effectiveTasks[task.id] = task;
    }

    final pending = await _platform.pendingNotifications();
    final pendingTaskIds = <String>{};
    final cancelled = <String>[];
    for (final notification in pending) {
      final taskId = parseTaskNotificationPayload(notification.payload);
      if (taskId != null) {
        if (!effectiveTasks.containsKey(taskId)) {
          await _platform.cancel(notification.id);
          cancelled.add(taskId);
        } else {
          pendingTaskIds.add(taskId);
        }
        continue;
      }
      final snoozedTaskId = _parseTaskPayload(
        notification.payload,
        acceptedType: 'task_snooze',
      );
      if (snoozedTaskId != null && !activeTaskIds.contains(snoozedTaskId)) {
        await _platform.cancel(notification.id);
        cancelled.add(snoozedTaskId);
      }
    }

    final permission = await _platform.getPermissionStatus();
    final scheduled = <String>[];
    final failed = <String>[];
    for (final entry in effectiveTasks.entries) {
      if (pendingTaskIds.contains(entry.key)) continue;
      if (permission != NotificationPermissionStatus.granted) {
        await _setSchedulingFailed(entry.value, failed: true);
        failed.add(entry.key);
        continue;
      }
      try {
        final result = await _scheduleTask(entry.value);
        if (result == ReminderScheduleStatus.scheduled) {
          scheduled.add(entry.key);
          await _setSchedulingFailed(entry.value, failed: false);
        }
      } catch (_) {
        await _setSchedulingFailed(entry.value, failed: true);
        failed.add(entry.key);
      }
    }

    cancelled.sort();
    scheduled.sort();
    failed.sort();
    return NotificationReconcileReport(
      cancelledOrphanTaskIds: cancelled,
      scheduledMissingTaskIds: scheduled,
      failedTaskIds: failed,
    );
  }

  Future<ReminderScheduleStatus> _scheduleTask(TaskItem task) async {
    final reminderAt = task.reminderAt;
    if (reminderAt == null || task.completed) {
      return ReminderScheduleStatus.noOccurrence;
    }
    final occurrence = nextReminderOccurrence(
      anchor: reminderAt,
      repeatRule: task.repeatRule,
      now: _now(),
      location: _location,
    );
    if (occurrence == null) return ReminderScheduleStatus.noOccurrence;
    await _platform.schedule(
      _notificationFor(
        task,
        scheduledDate: occurrence,
        repeatRule: task.repeatRule,
      ),
    );
    return ReminderScheduleStatus.scheduled;
  }

  ScheduledNotification _notificationFor(
    TaskItem task, {
    required tz.TZDateTime scheduledDate,
    required RepeatRule repeatRule,
    int? id,
    String? payload,
  }) {
    return ScheduledNotification(
      id: id ?? taskNotificationId(task.id),
      taskId: task.id,
      title: task.title,
      body: task.notes.isEmpty ? 'LessDo reminder' : task.notes,
      payload: payload ?? taskNotificationPayload(task.id),
      scheduledDate: scheduledDate,
      repeatRule: repeatRule,
    );
  }

  Future<void> _setSchedulingFailed(
    TaskItem task, {
    required bool failed,
  }) async {
    if (task.reminderSchedulingFailed == failed) return;
    await _repository.saveTask(task.copyWith(reminderSchedulingFailed: failed));
  }

  void _handleResponse(NotificationResponseData response) {
    final action = _parseResponse(response);
    if (action != null) _actions.add(action);
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
}

int taskNotificationId(String taskId) =>
    stableNotificationId(NotificationIdNamespace.task, taskId);

int taskSnoozeNotificationId(String taskId) =>
    stableNotificationId(NotificationIdNamespace.task, 'snooze:$taskId');

String taskNotificationPayload(String taskId) =>
    jsonEncode({'type': 'task', 'taskId': taskId});

String taskSnoozeNotificationPayload(String taskId) =>
    jsonEncode({'type': 'task_snooze', 'taskId': taskId});

String? parseTaskNotificationPayload(String? payload) {
  return _parseTaskPayload(payload, acceptedType: 'task');
}

String? _parseTaskActionPayload(String? payload) {
  final taskId = _parseTaskPayload(payload, acceptedType: 'task');
  return taskId ?? _parseTaskPayload(payload, acceptedType: 'task_snooze');
}

String? _parseTaskPayload(String? payload, {required String acceptedType}) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic> ||
        decoded.length != 2 ||
        decoded['type'] != acceptedType) {
      return null;
    }
    final taskId = decoded['taskId'];
    return taskId is String && taskId.isNotEmpty ? taskId : null;
  } on FormatException {
    return null;
  }
}
