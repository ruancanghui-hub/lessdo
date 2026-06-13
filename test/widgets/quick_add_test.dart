import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/widgets/quick_add.dart';

void main() {
  testWidgets('failed submit keeps input and displays an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickAdd(
            onSubmit: (_) async => throw StateError('Could not save task'),
          ),
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
      MaterialApp(
        home: Scaffold(
          body: QuickAdd(
            onSubmit: (_) {
              submissions += 1;
              return completer.future;
            },
          ),
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

  testWidgets('pending submit can complete after widget is unmounted', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuickAdd(onSubmit: (_) => completer.future)),
      ),
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
