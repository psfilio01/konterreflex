import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const background = Color(0xFFF8F8F5);
    const foreground = Color(0xFF171817);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6F8F86),
        brightness: Brightness.light,
        surface: background,
      ),
      textTheme: const TextTheme(
        headlineMedium:
            TextStyle(fontWeight: FontWeight.w600, color: foreground),
        bodyLarge: TextStyle(height: 1.45, color: foreground),
      ),
    );
  }
}
