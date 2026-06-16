import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/models/app_settings.dart';
import 'package:lessdo/models/task_item.dart';

import '../support/app_harness.dart';
import '../support/workflow_harness.dart';

void main() {
  testWidgets('Simplified Chinese renders navigation labels', (tester) async {
    final harness = await AppHarness.create(
      settings: const AppSettings(
        hasCompletedOnboarding: true,
        language: AppLanguage.simplifiedChinese,
      ),
    );
    addTearDown(harness.controller.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();

    expect(find.text('今天'), findsWidgets);
    expect(find.text('清单'), findsOneWidget);
    expect(find.text('专注'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('language can be changed from Settings', (tester) async {
    final harness = await AppHarness.create(
      settings: const AppSettings(hasCompletedOnboarding: true),
    );
    addTearDown(harness.controller.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();

    expect(find.text('今天'), findsWidgets);
    expect(harness.controller.settings.language, AppLanguage.simplifiedChinese);
  });

  testWidgets('Simplified Chinese covers task, list, and focus workflows', (
    tester,
  ) async {
    final task = TaskItem.create(
      id: 'task-1',
      title: '审计发布',
      listId: 'inbox',
      createdAt: DateTime.utc(2026, 6, 14),
      dueAt: DateTime.utc(2026, 6, 14, 10),
    );
    final harness = await WorkflowHarness.create(
      tasks: [task],
      language: AppLanguage.simplifiedChinese,
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();
    expect(find.text('要做什么？'), findsOneWidget);

    await tester.tap(find.text('审计发布'));
    await tester.pumpAndSettle();
    expect(find.text('任务详情'), findsOneWidget);
    expect(find.text('备注'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('子任务'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('清单'));
    await tester.pumpAndSettle();
    expect(find.text('所有任务'), findsOneWidget);
    expect(find.text('分享清单'), findsNothing);

    await tester.tap(find.text('专注'));
    await tester.pumpAndSettle();
    expect(find.text('正在处理'), findsOneWidget);
    expect(find.text('番茄钟'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('最近专注'), findsOneWidget);
  });
}
