import 'dart:convert';

import 'package:timezone/timezone.dart' as tz;

import '../models/task_item.dart';

enum NotificationIdNamespace { task, focus }

tz.TZDateTime? nextReminderOccurrence({
  required DateTime anchor,
  required RepeatRule repeatRule,
  required DateTime now,
  required tz.Location location,
}) {
  final localAnchor = tz.TZDateTime.from(anchor, location);
  return nextReminderOccurrenceForAnchor(
    anchor: ReminderAnchor(
      year: localAnchor.year,
      month: localAnchor.month,
      day: localAnchor.day,
      hour: localAnchor.hour,
      minute: localAnchor.minute,
    ),
    repeatRule: repeatRule,
    now: now,
    location: location,
  );
}

tz.TZDateTime? nextReminderOccurrenceForAnchor({
  required ReminderAnchor anchor,
  required RepeatRule repeatRule,
  required DateTime now,
  required tz.Location location,
}) {
  final localNow = tz.TZDateTime.from(now, location);
  final localAnchor = _validWallTime(
    location,
    anchor.year,
    anchor.month,
    anchor.day,
    anchor.hour,
    anchor.minute,
  );
  if (localAnchor != null && localAnchor.isAfter(localNow)) return localAnchor;
  if (repeatRule == RepeatRule.none) return null;

  return switch (repeatRule) {
    RepeatRule.none => null,
    RepeatRule.daily => _nextDaily(anchor, localNow, location),
    RepeatRule.weekly => _nextWeekly(anchor, localNow, location),
    RepeatRule.monthly => _nextMonthly(anchor, localNow, location),
  };
}

List<tz.TZDateTime> reminderOccurrences({
  required DateTime anchor,
  required RepeatRule repeatRule,
  required DateTime now,
  required tz.Location location,
  int monthlyCount = 12,
}) {
  final first = nextReminderOccurrence(
    anchor: anchor,
    repeatRule: repeatRule,
    now: now,
    location: location,
  );
  if (first == null) return const [];
  if (repeatRule != RepeatRule.monthly) return [first];

  final localAnchor = tz.TZDateTime.from(anchor, location);
  return [
    first,
    for (var offset = 1; offset < monthlyCount; offset++)
      _monthlyCandidate(
        location,
        first.year,
        first.month + offset,
        anchorDay: localAnchor.day,
        hour: localAnchor.hour,
        minute: localAnchor.minute,
      ),
  ];
}

List<tz.TZDateTime> reminderOccurrencesForAnchor({
  required ReminderAnchor anchor,
  required RepeatRule repeatRule,
  required DateTime now,
  required tz.Location location,
  int monthlyCount = 64,
}) {
  final first = nextReminderOccurrenceForAnchor(
    anchor: anchor,
    repeatRule: repeatRule,
    now: now,
    location: location,
  );
  if (first == null) return const [];
  if (repeatRule != RepeatRule.monthly) return [first];
  return [
    for (var offset = 0; offset < monthlyCount; offset++)
      _monthlyCandidate(
        location,
        first.year,
        first.month + offset,
        anchorDay: anchor.day,
        hour: anchor.hour,
        minute: anchor.minute,
      ),
  ];
}

int stableNotificationId(NotificationIdNamespace namespace, String value) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode('${namespace.name}:$value')) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final partitionedHash = hash & 0x3fffffff;
  return switch (namespace) {
    NotificationIdNamespace.task => partitionedHash == 0 ? 1 : partitionedHash,
    NotificationIdNamespace.focus => 0x40000000 | partitionedHash,
  };
}

tz.TZDateTime _nextDaily(
  ReminderAnchor anchor,
  tz.TZDateTime now,
  tz.Location location,
) {
  for (var offset = 0; ; offset++) {
    final date = tz.TZDateTime(location, now.year, now.month, now.day + offset);
    final candidate = _validWallTime(
      location,
      date.year,
      date.month,
      date.day,
      anchor.hour,
      anchor.minute,
    );
    if (candidate != null && candidate.isAfter(now)) return candidate;
  }
}

tz.TZDateTime _nextWeekly(
  ReminderAnchor anchor,
  tz.TZDateTime now,
  tz.Location location,
) {
  final anchorWeekday = DateTime(anchor.year, anchor.month, anchor.day).weekday;
  final daysUntilAnchor = (anchorWeekday - now.weekday) % 7;
  final date = tz.TZDateTime(
    location,
    now.year,
    now.month,
    now.day + daysUntilAnchor,
  );
  for (var weeks = 0; ; weeks++) {
    final weekDate = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day + weeks * 7,
    );
    final candidate = _validWallTime(
      location,
      weekDate.year,
      weekDate.month,
      weekDate.day,
      anchor.hour,
      anchor.minute,
    );
    if (candidate != null && candidate.isAfter(now)) return candidate;
  }
}

tz.TZDateTime _nextMonthly(
  ReminderAnchor anchor,
  tz.TZDateTime now,
  tz.Location location,
) {
  var candidate = _monthlyCandidate(
    location,
    now.year,
    now.month,
    anchorDay: anchor.day,
    hour: anchor.hour,
    minute: anchor.minute,
  );
  if (!candidate.isAfter(now)) {
    final nextMonth = tz.TZDateTime(location, now.year, now.month + 1);
    candidate = _monthlyCandidate(
      location,
      nextMonth.year,
      nextMonth.month,
      anchorDay: anchor.day,
      hour: anchor.hour,
      minute: anchor.minute,
    );
  }
  return candidate;
}

tz.TZDateTime _monthlyCandidate(
  tz.Location location,
  int year,
  int month, {
  required int anchorDay,
  required int hour,
  required int minute,
}) {
  final lastDay = tz.TZDateTime(location, year, month + 1, 0).day;
  final day = anchorDay > lastDay ? lastDay : anchorDay;
  return tz.TZDateTime(location, year, month, day, hour, minute);
}

tz.TZDateTime? _validWallTime(
  tz.Location location,
  int year,
  int month,
  int day,
  int hour,
  int minute,
) {
  final candidate = tz.TZDateTime(location, year, month, day, hour, minute);
  return candidate.year == year &&
          candidate.month == month &&
          candidate.day == day &&
          candidate.hour == hour &&
          candidate.minute == minute
      ? candidate
      : null;
}
