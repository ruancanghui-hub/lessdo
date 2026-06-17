import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LessDoTheme {
  static const themes = <String, LessDoPalette>{
    'system': LessDoPalette(
      name: 'System',
      background: Color(0xFFFFFFFF),
      accent: Color(0xFF2E7BF6),
    ),
    'snow': LessDoPalette(
      name: 'Snow',
      background: Color(0xFFFFFFFF),
      accent: Color(0xFF2E7BF6),
    ),
    'mint': LessDoPalette(
      name: 'Mint',
      background: Color(0xFFF1F8F4),
      accent: Color(0xFF388F5A),
    ),
    'sky': LessDoPalette(
      name: 'Sky',
      background: Color(0xFFF2F7FD),
      accent: Color(0xFF2E7BF6),
    ),
    'blush': LessDoPalette(
      name: 'Blush',
      background: Color(0xFFFFF5F3),
      accent: Color(0xFFE75E58),
    ),
  };

  static ThemeData build(String themeId, {required bool largeText}) {
    final palette = themes[themeId] ?? themes['snow']!;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: '.SF Pro Text',
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: Brightness.light,
        surface: palette.background,
      ),
    );

    final scale = largeText ? 1.1 : 1.0;
    return base.copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: const Color(0xFFE0E2E6),
      textTheme: base.textTheme
          .apply(
            bodyColor: const Color(0xFF111216),
            displayColor: const Color(0xFF111216),
          )
          .copyWith(
            headlineSmall: TextStyle(
              fontSize: 21 * scale,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: const Color(0xFF111216),
            ),
            titleMedium: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: const Color(0xFF111216),
            ),
            bodyLarge: TextStyle(
              fontSize: 15 * scale,
              letterSpacing: 0,
              color: const Color(0xFF111216),
            ),
            bodyMedium: TextStyle(
              fontSize: 13 * scale,
              letterSpacing: 0,
              color: const Color(0xFF111216),
            ),
            bodySmall: TextStyle(
              fontSize: 11 * scale,
              letterSpacing: 0,
              color: const Color(0xFF111216),
            ),
          ),
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: palette.accent,
        scaffoldBackgroundColor: palette.background,
      ),
    );
  }

  static ThemeData buildDark({required bool largeText}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: '.SF Pro Text',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6CA6FF),
        brightness: Brightness.dark,
      ),
    );
    final scale = largeText ? 1.1 : 1.0;
    return base.copyWith(
      splashFactory: NoSplash.splashFactory,
      textTheme: base.textTheme.copyWith(
        headlineSmall: TextStyle(
          fontSize: 21 * scale,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(fontSize: 15 * scale),
        bodyMedium: TextStyle(fontSize: 13 * scale),
        bodySmall: TextStyle(fontSize: 11 * scale),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF6CA6FF),
      ),
    );
  }
}

class LessDoPalette {
  const LessDoPalette({
    required this.name,
    required this.background,
    required this.accent,
  });

  final String name;
  final Color background;
  final Color accent;
}
