import 'package:flutter_test/flutter_test.dart';

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
}
