import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/app_controller.dart';
import '../models/task_item.dart';
import 'notification_service.dart';

class NotificationServiceCoordinator implements NotificationCoordinator {
  NotificationServiceCoordinator(this._service);

  final NotificationService _service;

  @override
  Future<void> cancel(String taskId) => _service.cancel(taskId);

  @override
  Future<void> schedule(TaskItem task) async {
    await _service.requestPermission();
    await _service.schedule(task);
  }
}

class LocalAuthenticationCoordinator implements AuthenticationCoordinator {
  LocalAuthenticationCoordinator({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      if (!await _localAuthentication.isDeviceSupported()) return false;
      return _localAuthentication.authenticate(
        localizedReason: 'Unlock LessDo',
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

class SharePlusCoordinator implements SharingCoordinator {
  @override
  Future<void> share({required String title, required String text}) {
    return SharePlus.instance.share(ShareParams(title: title, text: text));
  }
}
