import 'package:flutter/material.dart';

/// A row of form fields that collapses to a vertical column on narrow screens.
///
/// On wide screens (>= [breakpoint]) children are laid out horizontally and
/// each child is wrapped in an [Expanded]. On narrow screens they are stacked
/// vertically with [spacing] as vertical gap.
class ResponsiveFormRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double breakpoint;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveFormRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.breakpoint = 600,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= breakpoint;

        if (isWide) {
          final rowChildren = <Widget>[];
          for (var i = 0; i < children.length; i++) {
            if (i > 0) {
              rowChildren.add(SizedBox(width: spacing));
            }
            rowChildren.add(Expanded(child: children[i]));
          }
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            children: rowChildren,
          );
        }

        final columnChildren = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i > 0) {
            columnChildren.add(SizedBox(height: spacing));
          }
          columnChildren.add(children[i]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: columnChildren,
        );
      },
    );
  }
}
