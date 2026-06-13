import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/controllers/app_controller.dart';
import 'package:lessdo/data/settings_repository.dart';
import 'package:lessdo/data/task_repository.dart';
import 'package:lessdo/models/active_focus_session.dart';
import 'package:lessdo/models/app_settings.dart';
import 'package:lessdo/models/focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';
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
}

class _ThrowingTaskRepository extends _MemoryTaskRepository {
  @override
  Future<void> saveTask(TaskItem task) async {
    throw StateError('disk full');
  }
}

class _MemoryTaskRepository implements TaskRepository {
  final List<TaskList> _lists = [
    const TaskList(id: 'inbox', name: 'Inbox', colorValue: 0),
  ];
  final List<TaskItem> _tasks = [];
  final List<FocusSession> _history = [];
  ActiveFocusSession? _activeFocus;

  @override
  Future<void> completeFocus(
    FocusSession history, {
    String? completedTaskId,
  }) async {
    _history.insert(0, history);
    _activeFocus = null;
  }

  @override
  Future<void> deleteList(String listId, ListDeletionStrategy strategy) async {}

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
  }

  @override
  Future<ActiveFocusSession?> loadActiveFocus() async => _activeFocus;

  @override
  Future<List<FocusSession>> loadFocusHistory() async => List.of(_history);

  @override
  Future<List<TaskList>> loadLists() async => List.of(_lists);

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(_tasks);

  @override
  Future<void> saveActiveFocus(ActiveFocusSession? session) async {
    _activeFocus = session;
  }

  @override
  Future<void> saveList(TaskList list) async {}

  @override
  Future<void> saveTask(TaskItem task) async {
    _tasks.add(task);
  }
}

class _FakeNotificationCoordinator implements NotificationCoordinator {
  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> schedule(TaskItem task) async {}
}
