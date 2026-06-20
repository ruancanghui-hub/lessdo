import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/workflow_harness.dart';

void main() {
  testWidgets('today top bar add opens the task editor', (tester) async {
    final harness = await WorkflowHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('top-bar-add')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-title-field')), findsOneWidget);
    expect(find.byKey(const Key('task-save')), findsOneWidget);
  });

  testWidgets('today calendar button opens date picker then task editor', (
    tester,
  ) async {
    final harness = await WorkflowHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('today-calendar-button')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-title-field')), findsOneWidget);
  });
}
