import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/models/task_item.dart';

import '../support/workflow_harness.dart';

void main() {
  testWidgets('quick add saves a task and clears input', (tester) async {
    final harness = await WorkflowHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('quick-add-field')),
      'Pay bill',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('quick-add-submit')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pay bill'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('quick-add-field')))
          .controller
          ?.text,
      isEmpty,
    );
    expect(harness.controller.tasks.single.title, 'Pay bill');
  });

  testWidgets('failed editor save preserves content and offers retry', (
    tester,
  ) async {
    final harness = await WorkflowHarness.create(
      tasks: [
        TaskItem.create(
          id: 'task-1',
          title: 'Original',
          listId: 'inbox',
          createdAt: DateTime.utc(2026, 6, 14),
        ),
      ],
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pump();
    await tester.tap(find.text('Lists'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Inbox'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Original'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Edited title',
    );
    harness.failNextTaskSave();
    await tester.tap(find.byKey(const Key('task-save')));
    await tester.pump();

    expect(find.text('Could not save changes.'), findsOneWidget);
    expect(find.text('Edited title'), findsOneWidget);
    expect(find.byKey(const Key('task-save')), findsOneWidget);

    await tester.tap(find.byKey(const Key('task-save')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.controller.tasks.single.title, 'Edited title');
  });

  testWidgets('failed reminder scheduling can be retried from editor', (
    tester,
  ) async {
    final harness = await WorkflowHarness.create(
      tasks: [
        TaskItem.create(
          id: 'task-1',
          title: 'Call dentist',
          listId: 'inbox',
          createdAt: DateTime.utc(2026, 6, 14),
          dueAt: DateTime.utc(2026, 6, 15, 9),
          reminderAt: DateTime.utc(2026, 6, 15, 9),
          reminderSchedulingFailed: true,
        ),
      ],
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pump();
    await tester.tap(find.text('Lists'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Inbox'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Call dentist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reminder could not be scheduled.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.controller.tasks.single.reminderSchedulingFailed, isFalse);
  });
}
