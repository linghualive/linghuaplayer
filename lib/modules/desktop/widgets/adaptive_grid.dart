import 'package:flutter/material.dart';
import '../../../shared/responsive/breakpoints.dart';

/// Adaptive grid widget that adjusts columns based on screen size
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.childAspectRatio = 1.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = Breakpoints.getGridColumns(width);
        final effectivePadding = padding ?? Breakpoints.getScreenPadding(width);

        return Padding(
          padding: effectivePadding,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: runSpacing,
              childAspectRatio: childAspectRatio ?? 1.0,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        );
      },
    );
  }
}

/// Adaptive sliver grid for use in custom scroll views
class AdaptiveSliverGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;

  const AdaptiveSliverGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.childAspectRatio = 1.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = Breakpoints.getGridColumns(width);
        final effectivePadding = padding ?? Breakpoints.getScreenPadding(width);

        return SliverPadding(
          padding: effectivePadding,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: runSpacing,
              childAspectRatio: childAspectRatio ?? 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => children[index],
              childCount: children.length,
            ),
          ),
        );
      },
    );
  }
}