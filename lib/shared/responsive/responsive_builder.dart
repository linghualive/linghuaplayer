import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// A widget that builds different layouts based on screen size
/// Follows Material 3 responsive design principles
class ResponsiveBuilder extends StatelessWidget {
  /// Builder for compact screens (< 600dp)
  final Widget Function(BuildContext context, BoxConstraints constraints)
      compact;

  /// Builder for medium screens (600-840dp)
  /// If not provided, falls back to compact
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      medium;

  /// Builder for expanded screens (840-1200dp)
  /// If not provided, falls back to medium or compact
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      expanded;

  /// Builder for large screens (> 1200dp)
  /// If not provided, falls back to expanded, medium, or compact
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      large;

  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sizeClass = Breakpoints.getWindowSizeClass(width);

        switch (sizeClass) {
          case WindowSizeClass.compact:
            return compact(context, constraints);
          case WindowSizeClass.medium:
            return (medium ?? compact)(context, constraints);
          case WindowSizeClass.expanded:
            return (expanded ?? medium ?? compact)(context, constraints);
          case WindowSizeClass.large:
            return (large ?? expanded ?? medium ?? compact)(
                context, constraints);
        }
      },
    );
  }
}

/// A widget that shows/hides content based on screen size
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnCompact;
  final bool visibleOnMedium;
  final bool visibleOnExpanded;
  final bool visibleOnLarge;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnCompact = true,
    this.visibleOnMedium = true,
    this.visibleOnExpanded = true,
    this.visibleOnLarge = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass =
            Breakpoints.getWindowSizeClass(constraints.maxWidth);

        bool shouldShow = false;
        switch (sizeClass) {
          case WindowSizeClass.compact:
            shouldShow = visibleOnCompact;
            break;
          case WindowSizeClass.medium:
            shouldShow = visibleOnMedium;
            break;
          case WindowSizeClass.expanded:
            shouldShow = visibleOnExpanded;
            break;
          case WindowSizeClass.large:
            shouldShow = visibleOnLarge;
            break;
        }

        return shouldShow ? child : const SizedBox.shrink();
      },
    );
  }
}

/// Helper widget to provide responsive values
class ResponsiveValue<T> extends StatelessWidget {
  final T compact;
  final T? medium;
  final T? expanded;
  final T? large;
  final Widget Function(BuildContext context, T value) builder;

  const ResponsiveValue({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass =
            Breakpoints.getWindowSizeClass(constraints.maxWidth);

        T value;
        switch (sizeClass) {
          case WindowSizeClass.compact:
            value = compact;
            break;
          case WindowSizeClass.medium:
            value = medium ?? compact;
            break;
          case WindowSizeClass.expanded:
            value = expanded ?? medium ?? compact;
            break;
          case WindowSizeClass.large:
            value = large ?? expanded ?? medium ?? compact;
            break;
        }

        return builder(context, value);
      },
    );
  }
}
