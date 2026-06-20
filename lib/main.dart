import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'data/app_database.dart';
import 'data/settings_repository.dart';
import 'data/sqlite_task_repository.dart';
import 'diagnostics/diagnostic_log.dart';
import 'notifications/notification_coordinator.dart';
import 'services/notification_service.dart';
import 'services/platform_coordinators.dart';
import 'services/share_service.dart';
import 'ads/app_open_ad_manager.dart';
import 'ads/mobile_ads_support.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (MobileAdsSupport.enabled) {
    await MobileAds.instance.initialize();
    unawaited(appOpenAdManager.loadAd());
  }

  final diagnostics = await DiagnosticLog.openDefault(
    appVersion: '1.0.0+1',
    platform: Platform.operatingSystem,
  );
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      diagnostics
          .record(DiagnosticEvent.frameworkError, error: details.exception)
          .catchError((_) {}),
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(
      diagnostics
          .record(DiagnosticEvent.platformError, error: error)
          .catchError((_) {}),
    );
    return true;
  };

  final sharing = ShareService();
  runApp(
    LessDoApp(
      dependencies: AppDependencies(
        load: () => _loadApplication(diagnostics, sharing),
        exportDiagnostics: () async {
          await sharing.shareDiagnostics(await diagnostics.readForExport());
        },
        recordStartupError: (error) => diagnostics
            .record(DiagnosticEvent.storageFailure, error: error)
            .catchError((_) {}),
      ),
    ),
  );
}

Future<AppController> _loadApplication(
  DiagnosticLog diagnostics,
  ShareService sharing,
) async {
  final database = await AppDatabase.open();
  final repository = SqliteTaskRepository(database);
  final preferences = await SharedPreferences.getInstance();
  final settingsRepository = SettingsRepository(preferences);
  final timeZone = await initializeNotificationTimeZone();
  _recordTimeZoneWarning(diagnostics, timeZone.warning);
  final notificationPlatform = NotificationService(preferences: preferences);
  final notifications = NotificationCoordinator(
    platform: notificationPlatform,
    repository: repository,
    location: timeZone.location,
    locationProvider: () async {
      final refreshed = await initializeNotificationTimeZone();
      _recordTimeZoneWarning(diagnostics, refreshed.warning);
      return refreshed.location;
    },
  );
  await notifications.initialize();

  final store = AppController(
    repository: repository,
    settingsRepository: settingsRepository,
    notifications: notifications,
    authentication: LocalAuthenticationCoordinator(),
    sharing: sharing,
  );
  await store.load();
  return store;
}

void _recordTimeZoneWarning(
  DiagnosticLog diagnostics,
  NotificationTimeZoneFallbackWarning? warning,
) {
  if (warning == null) return;
  debugPrint('Notification timezone fallback: ${warning.cause}');
  unawaited(
    diagnostics
        .record(DiagnosticEvent.notificationFailure, error: warning.cause)
        .catchError((_) {}),
  );
}
