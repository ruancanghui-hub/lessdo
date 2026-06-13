import 'package:flutter/material.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'store/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.create();
  final notifications = NotificationService();
  await notifications.initialize();

  final store = AppStore(storage: storage, notifications: notifications);
  await store.load();

  runApp(LessDoApp(store: store));
}
