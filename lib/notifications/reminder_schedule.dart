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
  final localNow = tz.TZDateTime.from(now, location);
  if (localAnchor.isAfter(localNow)) return localAnchor;
  if (repeatRule == RepeatRule.none) return null;

  return switch (repeatRule) {
    RepeatRule.none => null,
    RepeatRule.daily => _nextDaily(localAnchor, localNow, location),
    RepeatRule.weekly => _nextWeekly(localAnchor, localNow, location),
    RepeatRule.monthly => _nextMonthly(localAnchor, localNow, location),
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
        localAnchor,
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
  tz.TZDateTime anchor,
  tz.TZDateTime now,
  tz.Location location,
) {
  var candidate = _withDate(location, now.year, now.month, now.day, anchor);
  if (!candidate.isAfter(now)) {
    final tomorrow = tz.TZDateTime(location, now.year, now.month, now.day + 1);
    candidate = _withDate(
      location,
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      anchor,
    );
  }
  return candidate;
}

tz.TZDateTime _nextWeekly(
  tz.TZDateTime anchor,
  tz.TZDateTime now,
  tz.Location location,
) {
  final daysUntilAnchor = (anchor.weekday - now.weekday) % 7;
  final date = tz.TZDateTime(
    location,
    now.year,
    now.month,
    now.day + daysUntilAnchor,
  );
  var candidate = _withDate(location, date.year, date.month, date.day, anchor);
  if (!candidate.isAfter(now)) {
    final nextWeek = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day + 7,
    );
    candidate = _withDate(
      location,
      nextWeek.year,
      nextWeek.month,
      nextWeek.day,
      anchor,
    );
  }
  return candidate;
}

tz.TZDateTime _nextMonthly(
  tz.TZDateTime anchor,
  tz.TZDateTime now,
  tz.Location location,
) {
  var candidate = _monthlyCandidate(location, now.year, now.month, anchor);
  if (!candidate.isAfter(now)) {
    final nextMonth = tz.TZDateTime(location, now.year, now.month + 1);
    candidate = _monthlyCandidate(
      location,
      nextMonth.year,
      nextMonth.month,
      anchor,
    );
  }
  return candidate;
}

tz.TZDateTime _monthlyCandidate(
  tz.Location location,
  int year,
  int month,
  tz.TZDateTime anchor,
) {
  final lastDay = tz.TZDateTime(location, year, month + 1, 0).day;
  final day = anchor.day > lastDay ? lastDay : anchor.day;
  return _withDate(location, year, month, day, anchor);
}

tz.TZDateTime _withDate(
  tz.Location location,
  int year,
  int month,
  int day,
  tz.TZDateTime time,
) {
  return tz.TZDateTime(
    location,
    year,
    month,
    day,
    time.hour,
    time.minute,
    time.second,
    time.millisecond,
    time.microsecond,
  );
}
