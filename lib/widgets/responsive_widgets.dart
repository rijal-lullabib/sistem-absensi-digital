import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ResponsiveHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final Color color;

  const ResponsiveHeader({
    super.key,
    required this.child,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final borderRadius = ResponsiveUtils.isMobileOrSmall(context) ? 20.0 : 30.0;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: padding.left, vertical: padding.top / 2),
      child: child,
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final int defaultCrossAxisCount;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.defaultCrossAxisCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(context);
        final responsiveSpacing = ResponsiveUtils.getSpacing(context, spacing);

        return Wrap(
          spacing: responsiveSpacing,
          runSpacing: responsiveSpacing,
          children: children.map((child) {
            final width =
                (constraints.maxWidth - (responsiveSpacing * (crossAxisCount - 1))) /
                crossAxisCount;
            return SizedBox(width: width.clamp(0, constraints.maxWidth), child: child);
          }).toList(),
        );
      },
    );
  }
}

class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveUtils.isTablet(context) || ResponsiveUtils.isDesktop(context)) {
          final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(context);
          final spacing = ResponsiveUtils.getSpacing(context, 16.0);
          return GridView.count(
            crossAxisCount: crossAxisCount,
            childAspectRatio: ResponsiveUtils.isDesktop(context) ? 2.5 : 3,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
            controller: controller,
            shrinkWrap: shrinkWrap,
            children: children,
          );
        }

        return ListView(
          controller: controller,
          padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
          shrinkWrap: shrinkWrap,
          children: children,
        );
      },
    );
  }
}
