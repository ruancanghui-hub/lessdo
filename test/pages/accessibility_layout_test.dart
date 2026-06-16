import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

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

  testWidgets('accessibility text keeps the full iPad date visible', (
    tester,
  ) async {
    final harness = await WorkflowHarness.create();
    addTearDown(harness.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1024, 1366);
    tester.platformDispatcher.textScaleFactorTestValue = 3.2;

    await tester.pumpWidget(harness.widget);
    await tester.pump();

    final dateText = DateFormat.yMMMEd('en').format(DateTime.now());
    final paragraph = tester.renderObject<RenderParagraph>(find.text(dateText));
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPad landscape keeps adaptive navigation without layout errors', (
    tester,
  ) async {
    final harness = await WorkflowHarness.create();
    addTearDown(harness.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1366, 1024);

    await tester.pumpWidget(harness.widget);
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
