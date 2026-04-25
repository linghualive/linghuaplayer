import 'package:flutter/material.dart';

class AppTheme {
  static const Color bilibiliPink = Color(0xFFFB7299);

  static ThemeData lightTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData darkTheme(Color seedColor) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final colorScheme = base.copyWith(
      surface: const Color(0xFF1C1018),
      onSurface: const Color(0xFFF5E0EB),
      surfaceContainerLowest: const Color(0xFF160D12),
      surfaceContainerLow: const Color(0xFF1F141A),
      surfaceContainer: const Color(0xFF24181F),
      surfaceContainerHigh: const Color(0xFF2E2028),
      surfaceContainerHighest: const Color(0xFF3A2A32),
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData lightThemeFromScheme(ColorScheme colorScheme) {
    return _buildTheme(colorScheme);
  }

  static ThemeData darkThemeFromScheme(ColorScheme colorScheme) {
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
