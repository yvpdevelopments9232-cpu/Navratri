import 'package:flutter/material.dart';

enum DeviceScreenType { mobile, tablet, desktop }

class ResponsiveHelper {
  static const double mobileBreakpoint = 768.0;
  static const double desktopBreakpoint = 1200.0;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return DeviceScreenType.mobile;
    } else if (width < desktopBreakpoint) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.desktop;
    }
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 900.0;

  static int dynamicGridColumns(
    double width, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 4,
    double minTileWidth = 260.0,
  }) {
    if (width < mobileBreakpoint) {
      return mobile;
    } else if (width < desktopBreakpoint) {
      return tablet;
    } else {
      final calculated = (width / minTileWidth).floor();
      return calculated > desktop ? calculated : desktop;
    }
  }
}

/// Universal Adaptive Responsive Layout Widget
/// Tiers:
/// - Mobile (< 768px): Single-column vertical stack wrapped in SafeArea and BouncingScrollPhysics
/// - Tablet (768px - 1200px): Balanced 2-column layout
/// - Desktop (>= 1200px): Multi-column widescreen layout with flexible proportional ratios
class AdaptiveResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)? mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)? tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)? desktop;
  final bool autoScrollMobile;
  final EdgeInsetsGeometry? padding;

  const AdaptiveResponsiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.autoScrollMobile = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= ResponsiveHelper.desktopBreakpoint && desktop != null) {
          return desktop!(context, constraints);
        }

        if (width >= ResponsiveHelper.mobileBreakpoint && tablet != null) {
          return tablet!(context, constraints);
        }

        if (mobile != null) {
          final content = mobile!(context, constraints);
          if (!autoScrollMobile) return content;

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: padding ?? const EdgeInsets.all(16),
              child: content,
            ),
          );
        }

        // Graceful fallback if a specific tier builder is omitted
        if (tablet != null) return tablet!(context, constraints);
        if (desktop != null) return desktop!(context, constraints);

        return const SizedBox.shrink();
      },
    );
  }
}

/// Dynamic wrap widget that prevents RenderFlex overflow when displaying buttons,
/// chips, or action toolbars on compact mobile screens.
class AdaptiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;

  const AdaptiveWrap({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// Adaptive Grid View that automatically calculates column counts based on available width
class AdaptiveGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double maxCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  const AdaptiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxCrossAxisExtent = 320.0,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
    this.childAspectRatio = 1.2,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: itemBuilder,
    );
  }
}
