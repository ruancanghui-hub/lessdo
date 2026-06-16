import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/legal/legal_content.dart';

import '../support/workflow_harness.dart';

void main() {
  testWidgets('settings has no premium or deferred controls', (tester) async {
    final harness = await WorkflowHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Upgrade'), findsNothing);
    expect(find.text('Cloud sync'), findsNothing);
    expect(find.text('Calendar sync'), findsNothing);
    expect(find.text('Continuous reminder'), findsNothing);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Privacy & permissions'), findsOneWidget);
  });

  testWidgets('lists page does not advertise deferred collaboration', (
    tester,
  ) async {
    final harness = await WorkflowHarness.create();
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pump();
    await tester.tap(find.text('Lists'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Share a list'), findsNothing);
    expect(find.textContaining('together'), findsNothing);
  });

  test('in-app legal copy matches the free local-only release', () {
    final combined = '$privacyPolicy\n$termsOfUse'.toLowerCase();

    expect(combined, isNot(contains('optional subscription')));
    expect(combined, isNot(contains('renew automatically')));
    expect(combined, contains('version 1.0 is free'));
    expect(combined, contains('does not collect'));
    expect(combined, contains('no subscriptions, in-app purchases'));
  });
}
