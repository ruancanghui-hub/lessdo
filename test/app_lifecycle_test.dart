import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/app.dart';
import 'package:lessdo/models/app_settings.dart';
import 'package:lessdo/pages/root_page.dart';

import 'support/app_harness.dart';

void main() {
  testWidgets('launch loads data before showing the root UI', (tester) async {
    final harness = await AppHarness.create(
      settings: const AppSettings(hasCompletedOnboarding: true),
    );
    final loading = Completer<void>();
    final dependencies = AppDependencies(
      load: () async {
        await loading.future;
        return harness.controller;
      },
    );

    await tester.pumpWidget(LessDoApp(dependencies: dependencies));

    expect(find.byKey(const Key('app-loading')), findsOneWidget);
    expect(find.byType(RootPage), findsNothing);

    loading.complete();
    await tester.pumpAndSettle();

    expect(find.byType(RootPage), findsOneWidget);
  });

  testWidgets('startup failure can retry without replacing dependencies', (
    tester,
  ) async {
    final harness = await AppHarness.create(
      settings: const AppSettings(hasCompletedOnboarding: true),
    );
    var attempts = 0;
    var exports = 0;
    final dependencies = AppDependencies(
      load: () async {
        attempts += 1;
        if (attempts == 1) throw StateError('database unavailable');
        return harness.controller;
      },
      exportDiagnostics: () async => exports += 1,
    );

    await tester.pumpWidget(LessDoApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startup-recovery')), findsOneWidget);
    await tester.tap(find.byKey(const Key('export-diagnostics')));
    await tester.pump();
    expect(exports, 1);

    await tester.tap(find.byKey(const Key('retry-startup')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byType(RootPage), findsOneWidget);
  });

  testWidgets('diagnostic write failure does not hide startup recovery', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      load: () async => throw StateError('database unavailable'),
      recordStartupError: (_) async => throw StateError('log unavailable'),
    );

    await tester.pumpWidget(LessDoApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startup-recovery')), findsOneWidget);
  });

  testWidgets('repeated resume callbacks share one lifecycle reconciliation', (
    tester,
  ) async {
    final harness = await AppHarness.create(
      settings: const AppSettings(hasCompletedOnboarding: true),
    );
    final reconciliation = Completer<void>();
    var reconciliationCalls = 0;
    final dependencies = AppDependencies(
      load: () async => harness.controller,
      reconcileLifecycle: (_) async {
        reconciliationCalls += 1;
        await reconciliation.future;
      },
    );

    await tester.pumpWidget(LessDoApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(reconciliationCalls, 1);

    reconciliation.complete();
    await tester.pump();
  });
}
