import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lessdo/l10n/app_localizations.dart';
import 'package:lessdo/models/app_settings.dart';
import 'package:lessdo/pages/root_page.dart';

import 'support/integration_app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('valid and invalid deep links preserve trusted mutations', (
    tester,
  ) async {
    final harness = await IntegrationAppHarness.create();
    final links = StreamController<Uri>();
    addTearDown(links.close);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await harness.close();
    });
    await harness.controller.updateSettings(
      const AppSettings(hasCompletedOnboarding: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RootPage(
          store: harness.controller,
          initialLink: () async => null,
          linkStream: links.stream,
        ),
      ),
    );

    links.add(Uri.parse('lessdo://x-callback-url/delete?task=all'));
    await tester.pumpAndSettle();
    expect(harness.controller.tasks, isEmpty);

    links.add(
      Uri.parse('lessdo://x-callback-url/create?content=Created%20from%20link'),
    );
    await tester.pumpAndSettle();
    expect(harness.controller.tasks.single.title, 'Created from link');

    links.add(Uri.parse('lessdo://x-callback-url/create?content=${'x' * 501}'));
    await tester.pumpAndSettle();
    expect(harness.controller.tasks, hasLength(1));
  });
}
