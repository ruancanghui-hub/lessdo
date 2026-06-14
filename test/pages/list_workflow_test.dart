import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/models/task_item.dart';
import 'package:lessdo/models/task_list.dart';

import '../support/workflow_harness.dart';

void main() {
  testWidgets('list deletion requires move or delete choice', (tester) async {
    const work = TaskList(id: 'work', name: 'Work', colorValue: 0xFF2E7BF6);
    final harness = await WorkflowHarness.create(
      lists: const [work],
      tasks: [
        TaskItem.create(
          id: 'task-1',
          title: 'Prepare report',
          listId: work.id,
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
    await tester.tap(find.text('Work'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('list-menu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Delete List'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Move Tasks to Inbox'), findsOneWidget);
    expect(find.text('Delete Tasks'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('deleting the visible list does not rebuild missing state', (
    tester,
  ) async {
    const work = TaskList(id: 'work', name: 'Work', colorValue: 0xFF2E7BF6);
    final harness = await WorkflowHarness.create(lists: const [work]);
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.tap(find.text('Lists'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('list-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete List'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move Tasks to Inbox'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Work'), findsNothing);
  });

  testWidgets('clearing completed tasks requires confirmation', (tester) async {
    const work = TaskList(id: 'work', name: 'Work', colorValue: 0xFF2E7BF6);
    final harness = await WorkflowHarness.create(
      lists: const [work],
      tasks: [
        TaskItem.create(
          id: 'done',
          title: 'Archived task',
          listId: work.id,
          createdAt: DateTime.utc(2026, 6, 14),
        ).copyWith(completed: true, completedAt: DateTime.utc(2026, 6, 14, 10)),
      ],
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pump();
    await tester.tap(find.text('Lists'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Work'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('clear-completed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Clear Completed Tasks?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(harness.controller.tasks, hasLength(1));

    await tester.tap(find.text('Clear'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.controller.tasks, isEmpty);
  });
}
