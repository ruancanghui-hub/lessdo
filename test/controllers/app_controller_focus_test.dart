import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/controllers/app_controller.dart';
import 'package:lessdo/data/settings_repository.dart';
import 'package:lessdo/data/sqlite_task_repository.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/services/platform_coordinators.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

void main() {
  test('addSession persists non-pomodoro mode and exact duration', () async {
    SharedPreferences.setMockInitialValues({});
    final database = await openTestDatabase();
    addTearDown(database.close);
    final store = AppController(
      repository: SqliteTaskRepository(database),
      settingsRepository: SettingsRepository(
        await SharedPreferences.getInstance(),
      ),
      notifications: _FakeNotificationCoordinator(),
      idFactory: () => 'focus-1',
      now: () => DateTime.utc(2026),
    );
    await store.load();

    await store.addSession(
      title: 'Open focus',
      mode: FocusMode.countUp,
      durationSeconds: 73,
    );

    expect(store.sessions.single.mode, FocusMode.countUp);
    expect(store.sessions.single.durationSeconds, 73);
  });
}

class _FakeNotificationCoordinator implements NotificationCoordinator {
  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> schedule(TaskItem task) async {}
}
