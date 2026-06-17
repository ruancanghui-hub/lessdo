import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessdo/theme/lessdo_theme.dart';

void main() {
  test('build supports large text without TextTheme.apply fontSizeFactor crash', () {
    for (final themeId in LessDoTheme.themes.keys) {
      expect(
        () => LessDoTheme.build(themeId, largeText: true),
        returnsNormally,
      );
    }
  });

  test('buildDark supports large text without TextTheme.apply fontSizeFactor crash', () {
    expect(() => LessDoTheme.buildDark(largeText: true), returnsNormally);
  });

  test('large text scales primary text styles', () {
    final normal = LessDoTheme.build('snow', largeText: false);
    final large = LessDoTheme.build('snow', largeText: true);

    expect(
      large.textTheme.bodyLarge?.fontSize,
      greaterThan(normal.textTheme.bodyLarge?.fontSize ?? 0),
    );
  });

  testWidgets('large text theme renders MaterialApp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LessDoTheme.build('snow', largeText: true),
        home: const Scaffold(body: Text('LessDo')),
      ),
    );

    expect(find.text('LessDo'), findsOneWidget);
  });
}
