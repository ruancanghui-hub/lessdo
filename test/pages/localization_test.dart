import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/models/app_settings.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('Simplified Chinese renders navigation labels', (tester) async {
    final harness = await AppHarness.create(
      settings: const AppSettings(
        hasCompletedOnboarding: true,
        language: AppLanguage.simplifiedChinese,
      ),
    );
    addTearDown(harness.controller.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();

    expect(find.text('今天'), findsWidgets);
    expect(find.text('清单'), findsOneWidget);
    expect(find.text('专注'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('language can be changed from Settings', (tester) async {
    final harness = await AppHarness.create(
      settings: const AppSettings(hasCompletedOnboarding: true),
    );
    addTearDown(harness.controller.dispose);

    await tester.pumpWidget(harness.widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();

    expect(find.text('今天'), findsWidgets);
    expect(harness.controller.settings.language, AppLanguage.simplifiedChinese);
  });
}
