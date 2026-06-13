import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_item.dart';
import '../notifications/notification_coordinator.dart';

class NotificationTimeZoneFallbackWarning {
  const NotificationTimeZoneFallbackWarning(this.cause);

  final Object cause;
}

class NotificationTimeZoneInitialization {
  const NotificationTimeZoneInitialization({
    required this.location,
    this.warning,
  });

  final tz.Location location;
  final NotificationTimeZoneFallbackWarning? warning;
}

const _notificationPermissionRequestedKey = 'notification_permission_requested';

NotificationPermissionStatus resolveNotificationPermissionStatus({
  required bool enabled,
  required bool hasRequestedPermission,
}) {
  if (enabled) return NotificationPermissionStatus.granted;
  return hasRequestedPermission
      ? NotificationPermissionStatus.denied
      : NotificationPermissionStatus.notDetermined;
}

DateTimeComponents? notificationDateTimeComponents(RepeatRule repeatRule) {
  return switch (repeatRule) {
    RepeatRule.none || RepeatRule.monthly => null,
    RepeatRule.daily => DateTimeComponents.time,
    RepeatRule.weekly => DateTimeComponents.dayOfWeekAndTime,
  };
}

Future<NotificationTimeZoneInitialization> initializeNotificationTimeZone({
  Future<String> Function()? lookupIdentifier,
  Duration Function()? systemOffset,
}) async {
  tz_data.initializeTimeZones();
  try {
    final identifier = lookupIdentifier == null
        ? (await FlutterTimezone.getLocalTimezone()).identifier
        : await lookupIdentifier();
    final location = tz.getLocation(identifier);
    tz.setLocalLocation(location);
    return NotificationTimeZoneInitialization(location: location);
  } catch (error) {
    final offset = systemOffset?.call() ?? DateTime.now().timeZoneOffset;
    final fallback = tz.Location('System/LocalFallback', [tz.minTime], [0], [
      tz.TimeZone(
        offset,
        isDst:
            DateTime.now().isUtc == false &&
            DateTime.now().timeZoneName.toUpperCase().endsWith('DT'),
        abbreviation: DateTime.now().timeZoneName,
      ),
    ]);
    tz.setLocalLocation(fallback);
    return NotificationTimeZoneInitialization(
      location: fallback,
      warning: NotificationTimeZoneFallbackWarning(error),
    );
  }
}

class NotificationService implements NotificationPlatform {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    SharedPreferences? preferences,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _preferences = preferences;

  final FlutterLocalNotificationsPlugin _plugin;
  final SharedPreferences? _preferences;

  @override
  Future<void> initialize({
    required void Function(NotificationResponseData response) onResponse,
  }) async {
    if (kIsWeb) return;
    final categories = <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        'task_reminder',
        actions: [
          DarwinNotificationAction.plain(
            'complete',
            'Complete',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain(
            'snooze_10',
            'Snooze 10 min',
            options: {DarwinNotificationActionOption.foreground},
          ),
        ],
      ),
    ];
    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: categories,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: categories,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        onResponse(
          NotificationResponseData(
            actionId: response.actionId,
            payload: response.payload,
          ),
        );
      },
    );
  }

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    if (kIsWeb) return NotificationPermissionStatus.granted;
    final hasRequestedPermission =
        (await _getPreferences()).getBool(
          _notificationPermissionRequestedKey,
        ) ??
        false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final enabled = await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();
        if (enabled == null) {
          return NotificationPermissionStatus.notDetermined;
        }
        return resolveNotificationPermissionStatus(
          enabled: enabled,
          hasRequestedPermission: hasRequestedPermission,
        );
      case TargetPlatform.iOS:
        final options = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        if (options == null) {
          return NotificationPermissionStatus.notDetermined;
        }
        return resolveNotificationPermissionStatus(
          enabled: options.isEnabled,
          hasRequestedPermission: hasRequestedPermission,
        );
      case TargetPlatform.macOS:
        final options = await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        if (options == null) {
          return NotificationPermissionStatus.notDetermined;
        }
        return resolveNotificationPermissionStatus(
          enabled: options.isEnabled,
          hasRequestedPermission: hasRequestedPermission,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return NotificationPermissionStatus.granted;
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (kIsWeb) return NotificationPermissionStatus.granted;
    final bool? granted;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        granted = await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      case TargetPlatform.iOS:
        granted = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      case TargetPlatform.macOS:
        granted = await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        granted = true;
    }
    if (granted != null) {
      await (await _getPreferences()).setBool(
        _notificationPermissionRequestedKey,
        true,
      );
    }
    if (granted == null) return NotificationPermissionStatus.notDetermined;
    return granted
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    if (kIsWeb) return;
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'task_reminders',
        'Task reminders',
        channelDescription: 'Reminders for LessDo tasks',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction(
            'complete',
            'Complete',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'snooze_10',
            'Snooze 10 min',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(categoryIdentifier: 'task_reminder'),
      macOS: const DarwinNotificationDetails(
        categoryIdentifier: 'task_reminder',
      ),
    );
    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: notification.scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: notification.payload,
      matchDateTimeComponents: notificationDateTimeComponents(
        notification.repeatRule,
      ),
    );
  }

  @override
  Future<void> cancel(int notificationId) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: notificationId);
  }

  @override
  Future<List<PendingNotification>> pendingNotifications() async {
    if (kIsWeb) return const [];
    final requests = await _plugin.pendingNotificationRequests();
    return List.unmodifiable(
      requests.map(
        (request) =>
            PendingNotification(id: request.id, payload: request.payload),
      ),
    );
  }

  @override
  Future<NotificationResponseData?> launchNotificationResponse() async {
    if (kIsWeb) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    final response = details?.notificationResponse;
    if (response == null) return null;
    return NotificationResponseData(
      actionId: response.actionId,
      payload: response.payload,
    );
  }

  Future<SharedPreferences> _getPreferences() async =>
      _preferences ?? await SharedPreferences.getInstance();
}
