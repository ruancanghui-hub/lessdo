import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lessdo/models/app_settings.dart';
import 'package:lessdo/notifications/notification_coordinator.dart';

import 'support/integration_app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new user completes and restores the core local-first journey', (
    tester,
  ) async {
    final harness = await IntegrationAppHarness.create();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await harness.close();
    });
    await harness.controller.updateSettings(
      const AppSettings(language: AppLanguage.english),
    );

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('quick-add-field')),
      'Pay electricity',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('quick-add-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Pay electricity'), findsOneWidget);

    await tester.tap(find.text('Pay electricity').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Pay electricity today',
    );
    await tester.tap(find.byKey(const Key('task-save')));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Complete Pay electricity today'));
    await tester.pumpAndSettle();
    expect(find.text('Completed · 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await harness.restart();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Pay electricity today'), findsOneWidget);
    expect(find.text('Completed · 1'), findsOneWidget);
  });

  testWidgets('custom list deletion can move its tasks to Inbox', (
    tester,
  ) async {
    final harness = await IntegrationAppHarness.create();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await harness.close();
    });
    await harness.controller.updateSettings(
      const AppSettings(
        hasCompletedOnboarding: true,
        language: AppLanguage.english,
      ),
    );

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lists'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Weekend');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final list = harness.controller.lists.firstWhere(
      (item) => item.name == 'Weekend',
    );
    await harness.controller.addTask(title: 'Pack bag', listId: list.id);
    await tester.tap(find.text('Weekend'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('list-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete List'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move Tasks to Inbox'));
    await tester.pumpAndSettle();

    expect(
      harness.controller.lists.where((item) => item.name == 'Weekend'),
      isEmpty,
    );
    expect(harness.controller.tasks.single.listId, 'inbox');
  });

  testWidgets('focus, denied reminders, and Chinese locale survive wiring', (
    tester,
  ) async {
    final harness = await IntegrationAppHarness.create(
      permission: NotificationPermissionStatus.denied,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await harness.close();
    });
    await harness.controller.updateSettings(
      const AppSettings(
        hasCompletedOnboarding: true,
        language: AppLanguage.simplifiedChinese,
      ),
    );

    final task = await harness.controller.addTask(
      title: 'Denied reminder',
      reminderAt: DateTime.now().add(const Duration(hours: 1)),
    );
    expect(task.reminderSchedulingFailed, isTrue);
    expect(harness.notifications.permissionRequests, 0);

    await harness.controller.focusController.startCountdown(
      const Duration(minutes: 10),
      taskId: task.id,
      taskTitle: task.title,
    );
    final sessionId = harness.controller.activeFocus!.id;

    await harness.restart();
    expect(harness.controller.activeFocus?.id, sessionId);

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    expect(find.text('今天'), findsWidgets);
    await tester.tap(find.text('专注').last);
    await tester.pumpAndSettle();
    expect(find.text('暂停'), findsOneWidget);
  });
}
