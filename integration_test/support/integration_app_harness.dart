import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lessdo/app.dart';
import 'package:lessdo/controllers/app_controller.dart';
import 'package:lessdo/data/app_database.dart';
import 'package:lessdo/data/settings_repository.dart';
import 'package:lessdo/data/sqlite_task_repository.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/notifications/notification_coordinator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntegrationAppHarness {
  IntegrationAppHarness._({
    required this.database,
    required this.repository,
    required this.settingsRepository,
    required this.notifications,
    required this.controller,
    required this.databasePath,
  });

  final AppDatabase database;
  final SqliteTaskRepository repository;
  final SettingsRepository settingsRepository;
  final String databasePath;
  TestNotificationCoordinator notifications;
  AppController controller;

  Widget get app => LessDoApp(store: controller);

  static Future<IntegrationAppHarness> create({
    NotificationPermissionStatus permission =
        NotificationPermissionStatus.granted,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    final directory = await getTemporaryDirectory();
    final databasePath = p.join(
      directory.path,
      'lessdo-integration-${DateTime.now().microsecondsSinceEpoch}.sqlite3',
    );
    final database = await AppDatabase.open(path: databasePath);
    final repository = SqliteTaskRepository(database);
    final settingsRepository = SettingsRepository(preferences);
    final notifications = TestNotificationCoordinator(permission);
    final controller = _controller(
      repository,
      settingsRepository,
      notifications,
    );
    await controller.load();
    return IntegrationAppHarness._(
      database: database,
      repository: repository,
      settingsRepository: settingsRepository,
      notifications: notifications,
      controller: controller,
      databasePath: databasePath,
    );
  }

  Future<void> restart() async {
    controller.dispose();
    notifications = TestNotificationCoordinator(notifications.permission);
    controller = _controller(repository, settingsRepository, notifications);
    await controller.load();
  }

  Future<void> close() async {
    controller.dispose();
    await database.close();
    final file = File(databasePath);
    if (await file.exists()) await file.delete();
  }

  static AppController _controller(
    SqliteTaskRepository repository,
    SettingsRepository settingsRepository,
    TestNotificationCoordinator notifications,
  ) {
    var nextId = DateTime.now().microsecondsSinceEpoch;
    return AppController(
      repository: repository,
      settingsRepository: settingsRepository,
      notifications: notifications,
      idFactory: () => 'integration-${nextId++}',
    );
  }
}

class TestNotificationCoordinator
    implements
        NotificationCoordinatorContract,
        FocusNotificationCoordinatorContract {
  TestNotificationCoordinator(this.permission);

  NotificationPermissionStatus permission;
  int permissionRequests = 0;
  int reconcileCalls = 0;
  final _actions = StreamController<NotificationAction>.broadcast();

  @override
  Stream<NotificationAction> get actions => _actions.stream;

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelFocus(String sessionId) async {}

  @override
  Future<void> dispose() => _actions.close();

  @override
  Future<NotificationAction?> launchAction() async => null;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async => permission;

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
  Future<NotificationPermissionStatus> requestPermission() async {
    permissionRequests += 1;
    return permission;
  }

  @override
  Future<ReminderScheduleStatus> schedule(
    TaskItem task, {
    bool requestPermission = true,
  }) async {
    if (permission == NotificationPermissionStatus.notDetermined &&
        requestPermission) {
      await this.requestPermission();
    }
    return permission == NotificationPermissionStatus.granted
        ? ReminderScheduleStatus.scheduled
        : ReminderScheduleStatus.permissionDenied;
  }

  @override
  Future<void> scheduleFocus(
    ActiveFocusSession session, {
    bool requestPermission = true,
  }) async {}

  @override
  Future<ReminderScheduleStatus> snooze(TaskItem task) async =>
      permission == NotificationPermissionStatus.granted
      ? ReminderScheduleStatus.scheduled
      : ReminderScheduleStatus.permissionDenied;
}
