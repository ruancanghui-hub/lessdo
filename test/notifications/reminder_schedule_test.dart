import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/notifications/reminder_schedule.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('nextReminderOccurrence', () {
    test('returns a future one-time reminder unchanged', () {
      final location = tz.getLocation('Asia/Shanghai');
      final anchor = tz.TZDateTime(location, 2026, 6, 15, 9, 30);
      final now = tz.TZDateTime(location, 2026, 6, 14, 12);

      expect(
        nextReminderOccurrence(
          anchor: anchor,
          repeatRule: RepeatRule.none,
          now: now,
          location: location,
        ),
        anchor,
      );
    });

    test('returns null for an expired one-time reminder', () {
      final location = tz.getLocation('Asia/Shanghai');

      expect(
        nextReminderOccurrence(
          anchor: tz.TZDateTime(location, 2026, 6, 13, 9),
          repeatRule: RepeatRule.none,
          now: tz.TZDateTime(location, 2026, 6, 13, 9, 1),
          location: location,
        ),
        isNull,
      );
    });

    test('daily recurrence preserves local wall time across DST', () {
      final location = tz.getLocation('America/New_York');
      final result = nextReminderOccurrence(
        anchor: tz.TZDateTime(location, 2026, 3, 7, 9, 30),
        repeatRule: RepeatRule.daily,
        now: tz.TZDateTime(location, 2026, 3, 7, 10),
        location: location,
      );

      expect(result, tz.TZDateTime(location, 2026, 3, 8, 9, 30));
      expect(result!.timeZoneOffset, const Duration(hours: -4));
    });

    test('weekly recurrence advances by local calendar weeks', () {
      final location = tz.getLocation('America/New_York');
      final result = nextReminderOccurrence(
        anchor: tz.TZDateTime(location, 2026, 10, 25, 8, 15),
        repeatRule: RepeatRule.weekly,
        now: tz.TZDateTime(location, 2026, 10, 26),
        location: location,
      );

      expect(result, tz.TZDateTime(location, 2026, 11, 1, 8, 15));
      expect(result!.timeZoneOffset, const Duration(hours: -5));
    });

    test('monthly recurrence clamps day 31 to the month end', () {
      final location = tz.getLocation('Asia/Shanghai');
      final result = nextReminderOccurrence(
        anchor: tz.TZDateTime(location, 2026, 1, 31, 18, 45),
        repeatRule: RepeatRule.monthly,
        now: tz.TZDateTime(location, 2026, 2, 1),
        location: location,
      );

      expect(result, tz.TZDateTime(location, 2026, 2, 28, 18, 45));
    });

    test('monthly recurrence keeps the original anchor day after clamping', () {
      final location = tz.getLocation('Asia/Shanghai');
      final result = nextReminderOccurrence(
        anchor: tz.TZDateTime(location, 2026, 1, 31, 18, 45),
        repeatRule: RepeatRule.monthly,
        now: tz.TZDateTime(location, 2026, 2, 28, 19),
        location: location,
      );

      expect(result, tz.TZDateTime(location, 2026, 3, 31, 18, 45));
    });

    test('monthly recurrence produces twelve future calendar occurrences', () {
      final location = tz.getLocation('Asia/Shanghai');

      final occurrences = reminderOccurrences(
        anchor: tz.TZDateTime(location, 2026, 1, 31, 18, 45),
        repeatRule: RepeatRule.monthly,
        now: tz.TZDateTime(location, 2026, 1, 31, 19),
        location: location,
      );

      expect(occurrences, hasLength(12));
      expect(occurrences[0], tz.TZDateTime(location, 2026, 2, 28, 18, 45));
      expect(occurrences[1], tz.TZDateTime(location, 2026, 3, 31, 18, 45));
      expect(occurrences[11], tz.TZDateTime(location, 2027, 1, 31, 18, 45));
    });
  });

  group('stableNotificationId', () {
    test('is deterministic and constrained to signed 31-bit positive ids', () {
      final first = stableNotificationId(
        NotificationIdNamespace.task,
        'task-123',
      );
      final second = stableNotificationId(
        NotificationIdNamespace.task,
        'task-123',
      );

      expect(second, first);
      expect(first, inInclusiveRange(1, 2147483647));
    });

    test('separates task and focus namespaces', () {
      final taskId = stableNotificationId(
        NotificationIdNamespace.task,
        'same-id',
      );
      final focusId = stableNotificationId(
        NotificationIdNamespace.focus,
        'same-id',
      );

      expect(taskId, inInclusiveRange(1, 0x3fffffff));
      expect(focusId, inInclusiveRange(0x40000000, 0x7fffffff));
    });
  });
}
