import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/workflow_harness.dart';

void main() {
  testWidgets('uses adaptive navigation on phone and iPad', (tester) async {
    final harness = await WorkflowHarness.create();
    addTearDown(harness.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(harness.widget);
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    tester.view.physicalSize = const Size(1024, 1366);
    await tester.pump();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text does not overflow phone layouts', (tester) async {
    final harness = await WorkflowHarness.create();
    addTearDown(harness.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;

    await tester.pumpWidget(harness.widget);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
