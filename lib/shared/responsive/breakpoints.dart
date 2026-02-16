import 'package:flutter/material.dart';

/// Material 3 responsive breakpoints for desktop layout
/// Based on Material Design 3 specifications
class Breakpoints {
  /// < 600dp: Mobile phones (compact)
  static const double compact = 600;

  /// 600-840dp: Tablets and foldables (medium)
  static const double medium = 840;

  /// 840-1200dp: Small desktop screens (expanded)
  static const double expanded = 1200;

  /// > 1200dp: Large desktop screens (large)
  static const double large = 1600;

  /// Determine the window size class based on width
  static WindowSizeClass getWindowSizeClass(double width) {
    if (width < compact) return WindowSizeClass.compact;
    if (width < medium) return WindowSizeClass.medium;
    if (width < expanded) return WindowSizeClass.expanded;
    return WindowSizeClass.large;
  }

  /// Calculate the number of columns for grid layouts
  static int getGridColumns(double width) {
    if (width < compact) return 2;
    if (width < medium) return 3;
    if (width < expanded) return 4;
    if (width < large) return 5;
    return 6;
  }

  /// Get appropriate padding based on screen size
  static EdgeInsets getScreenPadding(double width) {
    if (width < compact) {
      return const EdgeInsets.all(16);
    } else if (width < medium) {
      return const EdgeInsets.all(24);
    } else if (width < expanded) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }
  }

  /// Get appropriate card size for grid layouts
  static double getCardSize(double width) {
    if (width < compact) return (width - 48) / 2; // 2 columns with padding
    if (width < medium) return (width - 72) / 3; // 3 columns
    if (width < expanded) return (width - 96) / 4; // 4 columns
    return 280; // Fixed size for large screens
  }
}

/// Window size classes for responsive design
enum WindowSizeClass {
  compact,
  medium,
  expanded,
  large,
}

/// Extension methods for WindowSizeClass
extension WindowSizeClassExtension on WindowSizeClass {
  bool get isCompact => this == WindowSizeClass.compact;
  bool get isMedium => this == WindowSizeClass.medium;
  bool get isExpanded => this == WindowSizeClass.expanded;
  bool get isLarge => this == WindowSizeClass.large;

  bool get isDesktop =>
      this == WindowSizeClass.expanded || this == WindowSizeClass.large;
  bool get isMobile =>
      this == WindowSizeClass.compact || this == WindowSizeClass.medium;
}
