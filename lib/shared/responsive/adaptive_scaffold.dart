import 'package:flutter/material.dart';
import '../../app/theme/desktop_theme.dart';
import 'breakpoints.dart';

/// An adaptive scaffold that provides different layouts based on screen size
/// Follows Material 3 navigation patterns
class AdaptiveScaffold extends StatelessWidget {
  /// The main content body
  final Widget body;

  /// Optional navigation rail for desktop layouts
  final Widget? navigationRail;

  /// Optional bottom bar (e.g., player controls)
  final Widget? bottomBar;

  /// Optional app bar
  final PreferredSizeWidget? appBar;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// FAB location
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Background color
  final Color? backgroundColor;

  /// Whether to show navigation rail on medium screens
  final bool showNavigationRailOnMedium;

  /// Padding for the body content
  final EdgeInsetsGeometry? bodyPadding;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.navigationRail,
    this.bottomBar,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.showNavigationRailOnMedium = true,
    this.bodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = Breakpoints.getWindowSizeClass(constraints.maxWidth);
        final isDesktop = sizeClass.isDesktop;
        final showNavRail = isDesktop ||
            (sizeClass == WindowSizeClass.medium && showNavigationRailOnMedium);

        // Calculate effective body padding
        EdgeInsetsGeometry effectiveBodyPadding = bodyPadding ?? EdgeInsets.zero;
        if (bodyPadding == null && isDesktop) {
          effectiveBodyPadding = Breakpoints.getScreenPadding(constraints.maxWidth);
        }

        Widget scaffoldBody = body;

        // Wrap body with padding if needed
        if (effectiveBodyPadding != EdgeInsets.zero) {
          scaffoldBody = Padding(
            padding: effectiveBodyPadding,
            child: scaffoldBody,
          );
        }

        // Add navigation rail for desktop
        if (showNavRail && navigationRail != null) {
          scaffoldBody = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isDesktop && sizeClass == WindowSizeClass.large
                    ? DesktopTheme.desktopNavigationRailExtendedWidth
                    : DesktopTheme.desktopNavigationRailWidth,
                child: navigationRail!,
              ),
              Expanded(child: scaffoldBody),
            ],
          );
        }

        // Build the scaffold
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: appBar,
          body: Column(
            children: [
              Expanded(child: scaffoldBody),
              if (bottomBar != null) bottomBar!,
            ],
          ),
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        );
      },
    );
  }
}

/// Adaptive navigation destination that works with both NavigationBar and NavigationRail
class AdaptiveNavigationDestination {
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final String? tooltip;

  const AdaptiveNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.tooltip,
  });

  /// Convert to NavigationDestination for bottom navigation
  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      tooltip: tooltip,
    );
  }

  /// Convert to NavigationRailDestination for rail navigation
  NavigationRailDestination toNavigationRailDestination() {
    return NavigationRailDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: Text(label),
    );
  }
}

/// Adaptive navigation bar that switches between bottom nav and rail
class AdaptiveNavigationBar extends StatelessWidget {
  final List<AdaptiveNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;
  final NavigationRailLabelType? labelType;
  final Widget? leading;
  final Widget? trailing;
  final double? groupAlignment;
  final Color? backgroundColor;
  final double? elevation;

  const AdaptiveNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.extended = false,
    this.labelType,
    this.leading,
    this.trailing,
    this.groupAlignment,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = Breakpoints.getWindowSizeClass(constraints.maxWidth);
        final useRail = sizeClass.isDesktop ||
            sizeClass == WindowSizeClass.medium;

        if (useRail) {
          // Use NavigationRail for desktop/tablet
          return NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: extended || sizeClass.isLarge,
            labelType: labelType ?? (extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected),
            destinations: destinations.map((d) => d.toNavigationRailDestination()).toList(),
            leading: leading,
            trailing: trailing,
            groupAlignment: groupAlignment ?? -1.0,
            backgroundColor: backgroundColor,
            elevation: elevation,
          );
        } else {
          // Use NavigationBar for mobile
          return NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: destinations.map((d) => d.toNavigationDestination()).toList(),
            backgroundColor: backgroundColor,
            elevation: elevation,
          );
        }
      },
    );
  }
}