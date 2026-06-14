import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('first launch can skip to an empty Inbox', (tester) async {
    final harness = await AppHarness.create();
    addTearDown(harness.controller.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to LessDo'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Inbox is empty'), findsOneWidget);
    expect(harness.controller.tasks, isEmpty);
    expect(harness.controller.settings.hasCompletedOnboarding, isTrue);
  });
}
