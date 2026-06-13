import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'data/app_database.dart';
import 'data/settings_repository.dart';
import 'data/sqlite_task_repository.dart';
import 'notifications/notification_coordinator.dart';
import 'services/notification_service.dart';
import 'services/platform_coordinators.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.open();
  final repository = SqliteTaskRepository(database);
  final preferences = await SharedPreferences.getInstance();
  final settingsRepository = SettingsRepository(preferences);
  final timeZone = await initializeNotificationTimeZone();
  if (timeZone.warning != null) {
    debugPrint('Notification timezone fallback: ${timeZone.warning!.cause}');
  }
  final notificationPlatform = NotificationService(preferences: preferences);
  final notifications = NotificationCoordinator(
    platform: notificationPlatform,
    repository: repository,
    location: timeZone.location,
    locationProvider: () async {
      final refreshed = await initializeNotificationTimeZone();
      if (refreshed.warning != null) {
        debugPrint(
          'Notification timezone fallback: ${refreshed.warning!.cause}',
        );
      }
      return refreshed.location;
    },
  );
  await notifications.initialize();

  final store = AppController(
    repository: repository,
    settingsRepository: settingsRepository,
    notifications: notifications,
    authentication: LocalAuthenticationCoordinator(),
    sharing: SharePlusCoordinator(),
  );
  await store.load();

  runApp(LessDoApp(store: store));
}
