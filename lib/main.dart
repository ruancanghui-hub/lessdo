import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'data/app_database.dart';
import 'data/settings_repository.dart';
import 'data/sqlite_task_repository.dart';
import 'services/notification_service.dart';
import 'services/platform_coordinators.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.open();
  final repository = SqliteTaskRepository(database);
  final settingsRepository = SettingsRepository(
    await SharedPreferences.getInstance(),
  );
  final notifications = NotificationService();
  await notifications.initialize();

  final store = AppController(
    repository: repository,
    settingsRepository: settingsRepository,
    notifications: NotificationServiceCoordinator(notifications),
    authentication: LocalAuthenticationCoordinator(),
    sharing: SharePlusCoordinator(),
  );
  await store.load();

  runApp(LessDoApp(store: store));
}
