import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/models/app_settings.dart';
import 'package:lessdo/models/focus_session.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';

void main() {
  group('TaskItem', () {
    test('create rejects an empty title', () {
      expect(
        () => TaskItem.create(
          id: 'task-1',
          title: '   ',
          listId: 'inbox',
          createdAt: DateTime(2026, 6, 13, 10),
        ),
        throwsFormatException,
      );
    });

    test('create trims title and normalizes persisted times to UTC', () {
      final task = TaskItem.create(
        id: 'task-1',
        title: '  Ship release  ',
        listId: 'inbox',
        createdAt: DateTime(2026, 6, 13, 10),
        dueAt: DateTime(2026, 6, 14, 15, 30),
        updatedAt: DateTime(2026, 6, 13, 11),
      );
      final json = task.toJson();

      expect(task.title, 'Ship release');
      expect(DateTime.parse(json['createdAt']! as String).isUtc, isTrue);
      expect(DateTime.parse(json['dueAt']! as String).isUtc, isTrue);
      expect(DateTime.parse(json['updatedAt']! as String).isUtc, isTrue);
    });

    test('date status can be evaluated against an injected now', () {
      final task = TaskItem.create(
        id: 'task-1',
        title: 'Pay bill',
        listId: 'inbox',
        createdAt: DateTime.utc(2026, 6, 12),
        dueAt: DateTime.utc(2026, 6, 13, 9),
      );

      expect(task.isDueTodayAt(DateTime.utc(2026, 6, 13, 10)), isTrue);
      expect(task.isOverdueAt(DateTime.utc(2026, 6, 14, 10)), isTrue);
    });
  });

  group('TaskList and AppSettings', () {
    test('new fields survive JSON round trips', () {
      const list = TaskList(
        id: 'inbox',
        name: 'Inbox',
        colorValue: 0xFF000000,
        sortOrder: 4,
      );
      const settings = AppSettings(
        largeText: true,
        faceId: true,
        hasCompletedOnboarding: true,
        language: AppLanguage.simplifiedChinese,
      );

      expect(TaskList.fromJson(list.toJson()).sortOrder, 4);
      expect(AppSettings.fromJson(settings.toJson()).themeId, 'system');
      expect(
        AppSettings.fromJson(settings.toJson()).language,
        AppLanguage.simplifiedChinese,
      );
    });
  });

  group('Focus sessions', () {
    test('countdown remainingAt uses the absolute target time', () {
      final session = ActiveFocusSession(
        id: 'active-1',
        mode: FocusMode.countdown,
        startedAt: DateTime.utc(2026, 6, 13, 10),
        targetAt: DateTime.utc(2026, 6, 13, 10, 10),
        durationSeconds: 600,
      );

      expect(
        session.remainingAt(DateTime.utc(2026, 6, 13, 10, 3)),
        const Duration(minutes: 7),
      );
    });

    test('pause and resume exclude paused time from elapsed time', () {
      final running = ActiveFocusSession(
        id: 'active-1',
        mode: FocusMode.countUp,
        startedAt: DateTime.utc(2026, 6, 13, 10),
      );
      final paused = running.pause(DateTime.utc(2026, 6, 13, 10, 5));
      final resumed = paused.resume(DateTime.utc(2026, 6, 13, 10, 8));

      expect(
        paused.elapsedAt(DateTime.utc(2026, 6, 13, 10, 7)),
        const Duration(minutes: 5),
      );
      expect(
        resumed.elapsedAt(DateTime.utc(2026, 6, 13, 10, 10)),
        const Duration(minutes: 7),
      );
      expect(resumed.accumulatedPaused, const Duration(minutes: 3));
    });

    test('active session JSON round trip preserves UTC state', () {
      final session = ActiveFocusSession(
        id: 'active-1',
        taskId: 'task-1',
        mode: FocusMode.pomodoro,
        startedAt: DateTime.utc(2026, 6, 13, 10),
        pausedAt: DateTime.utc(2026, 6, 13, 10, 5),
        targetAt: DateTime.utc(2026, 6, 13, 10, 25),
        durationSeconds: 1500,
        accumulatedPaused: const Duration(seconds: 30),
      );

      final restored = ActiveFocusSession.fromJson(session.toJson());

      expect(restored.id, session.id);
      expect(restored.taskId, session.taskId);
      expect(restored.mode, session.mode);
      expect(restored.startedAt, session.startedAt);
      expect(restored.pausedAt, session.pausedAt);
      expect(restored.targetAt, session.targetAt);
      expect(restored.durationSeconds, session.durationSeconds);
      expect(restored.accumulatedPaused, session.accumulatedPaused);
      expect(restored.startedAt.isUtc, isTrue);
    });

    test('completed focus session stores UTC completion and mode', () {
      final session = FocusSession(
        id: 'session-1',
        taskTitle: 'Write tests',
        minutes: 25,
        mode: FocusMode.pomodoro,
        durationSeconds: 1500,
        completedAt: DateTime(2026, 6, 13, 10),
      );

      final restored = FocusSession.fromJson(session.toJson());

      expect(restored.mode, FocusMode.pomodoro);
      expect(restored.durationSeconds, 1500);
      expect(restored.completedAt.isUtc, isTrue);
    });
  });
}
