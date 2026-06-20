import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/l10n/app_localizations.dart';
import 'package:lessdo/widgets/quick_add.dart';

void main() {
  testWidgets('dark theme quick add uses readable semantic colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        theme: ThemeData.dark(),
        child: QuickAdd(onSubmit: (_) async {}),
      ),
    );

    final surface = tester.widget<Container>(
      find.byKey(const Key('quick-add-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    final textField = tester.widget<TextField>(find.byType(TextField));
    final background = decoration.color!;
    final hint = textField.decoration!.hintStyle!.color!;

    expect(_contrastRatio(background, hint), greaterThanOrEqualTo(4.5));
  });

  testWidgets('failed submit keeps input and displays an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        child: QuickAdd(
          onSubmit: (_) async => throw StateError('Could not save task'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Pay bill');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Pay bill'), findsOneWidget);
    expect(find.text('Could not save task'), findsOneWidget);
  });

  testWidgets('successful submit clears input and blocks duplicate submits', (
    tester,
  ) async {
    final completer = Completer<void>();
    var submissions = 0;
    await tester.pumpWidget(
      _app(
        child: QuickAdd(
          onSubmit: (_) {
            submissions += 1;
            return completer.future;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Pay bill');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(submissions, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.text('Pay bill'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Pay bill'), findsNothing);
  });

  testWidgets('voice button focuses the input field for keyboard dictation', (
    tester,
  ) async {
    await tester.pumpWidget(_app(child: QuickAdd(onSubmit: (_) async {})));

    expect(_focusedField(tester), isFalse);

    await tester.tap(find.byKey(const Key('quick-add-voice')));
    await tester.pump();

    expect(_focusedField(tester), isTrue);
  });

  testWidgets('pending submit can complete after widget is unmounted', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      _app(child: QuickAdd(onSubmit: (_) => completer.future)),
    );
    await tester.enterText(find.byType(TextField), 'Pay bill');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pump();
    final textController = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    completer.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(textController.text, 'Pay bill');
  });
}

Widget _app({required Widget child, ThemeData? theme}) => MaterialApp(
  theme: theme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first
      : second;
  final darker = identical(lighter, first) ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

bool _focusedField(WidgetTester tester) {
  return tester.widget<TextField>(find.byKey(const Key('quick-add-field'))).focusNode?.hasFocus ?? false;
}
