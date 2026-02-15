import 'package:flutter/material.dart';

/// Desktop-specific theme configurations following Material 3
class DesktopTheme {
  /// Desktop-specific spacing values
  static const double desktopSpacing = 24.0;
  static const double desktopCompactSpacing = 16.0;
  static const double desktopLargeSpacing = 32.0;

  /// Desktop-specific component sizes
  static const double desktopAppBarHeight = 64.0;
  static const double desktopPlayerBarHeight = 72.0;
  static const double desktopNavigationRailWidth = 80.0;
  static const double desktopNavigationRailExtendedWidth = 256.0;

  /// Desktop-specific elevation values
  static const double desktopCardElevation = 1.0;
  static const double desktopHoverElevation = 3.0;

  /// Desktop-specific border radius
  static const double desktopBorderRadius = 12.0;
  static const double desktopSmallBorderRadius = 8.0;
  static const double desktopLargeBorderRadius = 16.0;

  /// Create desktop-optimized theme data
  static ThemeData createDesktopTheme({
    required ColorScheme colorScheme,
    String? fontFamily,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,

      // Desktop-specific card theme
      cardTheme: CardThemeData(
        elevation: desktopCardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(desktopBorderRadius),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Desktop-specific elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(desktopSmallBorderRadius),
          ),
        ),
      ),

      // Desktop-specific filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(desktopSmallBorderRadius),
          ),
        ),
      ),

      // Desktop-specific text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(desktopSmallBorderRadius),
          ),
        ),
      ),

      // Desktop-specific icon button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(12),
        ),
      ),

      // Desktop-specific navigation rail theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        indicatorColor: colorScheme.secondaryContainer,
        groupAlignment: -1.0,
      ),

      // Desktop-specific list tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minLeadingWidth: 56,
        horizontalTitleGap: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(desktopSmallBorderRadius),
        ),
      ),

      // Desktop-specific dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(desktopLargeBorderRadius),
        ),
        elevation: 3,
      ),

      // Desktop-specific tooltip theme
      tooltipTheme: TooltipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(desktopSmallBorderRadius),
        ),
        textStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 14,
        ),
        waitDuration: const Duration(seconds: 1),
        showDuration: const Duration(milliseconds: 1500),
      ),
    );
  }

  /// Create hover effect decoration
  static BoxDecoration createHoverDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(desktopSmallBorderRadius),
    );
  }

  /// Create focus effect decoration
  static BoxDecoration createFocusDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      border: Border.all(
        color: colorScheme.primary,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(desktopSmallBorderRadius),
    );
  }

  /// Get desktop-specific text styles
  static TextTheme getDesktopTextTheme(TextTheme base) {
    return base.copyWith(
      // Slightly larger text for desktop readability
      bodySmall: base.bodySmall?.copyWith(fontSize: 13),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 15),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 17),
      titleSmall: base.titleSmall?.copyWith(fontSize: 15),
      titleMedium: base.titleMedium?.copyWith(fontSize: 17),
      titleLarge: base.titleLarge?.copyWith(fontSize: 24),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: 26),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 30),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 34),
    );
  }
}