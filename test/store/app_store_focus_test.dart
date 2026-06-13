import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/services/notification_service.dart';
import 'package:lessdo/services/storage_service.dart';
import 'package:lessdo/store/app_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('addSession persists non-pomodoro mode and exact duration', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(
      storage: await StorageService.create(),
      notifications: NotificationService(),
    );

    await store.addSession(
      title: 'Open focus',
      mode: FocusMode.countUp,
      durationSeconds: 73,
    );

    expect(store.sessions.single.mode, FocusMode.countUp);
    expect(store.sessions.single.durationSeconds, 73);
  });
}
