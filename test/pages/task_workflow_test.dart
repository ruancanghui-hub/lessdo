import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
