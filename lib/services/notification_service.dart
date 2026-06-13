import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_item.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      final current = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(current.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macOS = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    final results = <bool?>[
      await android?.requestNotificationsPermission(),
      await ios?.requestPermissions(alert: true, badge: true, sound: true),
      await macOS?.requestPermissions(alert: true, badge: true, sound: true),
    ];
    return results.whereType<bool>().every((result) => result);
  }

  Future<void> schedule(TaskItem task) async {
    if (kIsWeb) return;
    await cancel(task.id);
    final reminder = _nextReminder(task);
    if (reminder == null) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'Task reminders',
        channelDescription: 'Reminders for LessDo tasks',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(categoryIdentifier: 'task_reminder'),
      macOS: DarwinNotificationDetails(categoryIdentifier: 'task_reminder'),
    );

    await _plugin.zonedSchedule(
      id: _notificationId(task.id),
      title: task.title,
      body: task.notes.isEmpty ? 'LessDo reminder' : task.notes,
      scheduledDate: tz.TZDateTime.from(reminder, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: task.id,
      matchDateTimeComponents: switch (task.repeatRule) {
        RepeatRule.daily => DateTimeComponents.time,
        RepeatRule.weekly => DateTimeComponents.dayOfWeekAndTime,
        RepeatRule.monthly => DateTimeComponents.dayOfMonthAndTime,
        RepeatRule.none => null,
      },
    );
  }

  Future<void> cancel(String taskId) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: _notificationId(taskId));
  }

  int _notificationId(String taskId) => taskId.hashCode.abs() % 2147483647;

  DateTime? _nextReminder(TaskItem task) {
    final reminder = task.reminderAt;
    if (reminder == null) return null;
    final now = DateTime.now();
    if (reminder.isAfter(now)) return reminder;

    return switch (task.repeatRule) {
      RepeatRule.none => null,
      RepeatRule.daily => DateTime(
        now.year,
        now.month,
        now.day + 1,
        reminder.hour,
        reminder.minute,
      ),
      RepeatRule.weekly => reminder.add(
        Duration(days: ((now.difference(reminder).inDays ~/ 7) + 1) * 7),
      ),
      RepeatRule.monthly => _nextMonthly(reminder, now),
    };
  }

  DateTime _nextMonthly(DateTime reminder, DateTime now) {
    var year = now.year;
    var month = now.month;
    var candidate = DateTime(
      year,
      month,
      reminder.day,
      reminder.hour,
      reminder.minute,
    );
    if (!candidate.isAfter(now)) {
      month++;
      if (month > 12) {
        year++;
        month = 1;
      }
      candidate = DateTime(
        year,
        month,
        reminder.day,
        reminder.hour,
        reminder.minute,
      );
    }
    return candidate;
  }
}
