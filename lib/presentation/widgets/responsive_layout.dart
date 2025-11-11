import 'package:flutter/material.dart';

/// Responsive layout wrapper that adapts to different screen sizes
/// Uses LayoutBuilder to detect screen constraints and apply responsive design
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine screen size category
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;
        final isDesktop = screenWidth >= 1200;

        // Calculate responsive padding
        final horizontalPadding = _getHorizontalPadding(
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
        );

        final verticalPadding = _getVerticalPadding(
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
        );

        // Calculate max width for content
        final contentMaxWidth =
            maxWidth ??
            _getMaxWidth(
              screenWidth: screenWidth,
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            );

        // Apply padding from parameter or calculated
        final effectivePadding =
            padding ??
            EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            );

        Widget content = Padding(padding: effectivePadding, child: child);

        // Center content if requested and on larger screens
        if (centerContent && (isTablet || isDesktop)) {
          content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: content,
            ),
          );
        } else if (isTablet || isDesktop) {
          // Constrain width without centering
          content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: content,
          );
        }

        return content;
      },
    );
  }

  double _getHorizontalPadding({
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    if (isMobile) return 20.0;
    if (isTablet) return 40.0;
    return 60.0; // Desktop
  }

  double _getVerticalPadding({
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    if (isMobile) return 16.0;
    if (isTablet) return 24.0;
    return 32.0; // Desktop
  }

  double _getMaxWidth({
    required double screenWidth,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    if (isMobile) return double.infinity;
    if (isTablet) return 800.0;
    return 1200.0; // Desktop
  }
}

/// Responsive breakpoints helper
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1200;
  static const double desktop = 1920;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}

/// Responsive value helper - returns different values based on screen size
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({required this.mobile, this.tablet, this.desktop});

  T getValue(double width) {
    if (ResponsiveBreakpoints.isDesktop(width)) {
      return desktop ?? tablet ?? mobile;
    }
    if (ResponsiveBreakpoints.isTablet(width)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

/// Responsive grid columns helper
class ResponsiveGrid {
  static int getColumns(double width) {
    if (ResponsiveBreakpoints.isMobile(width)) return 1;
    if (ResponsiveBreakpoints.isTablet(width)) return 2;
    return 3; // Desktop
  }

  static double getCrossAxisSpacing(double width) {
    if (ResponsiveBreakpoints.isMobile(width)) return 16.0;
    if (ResponsiveBreakpoints.isTablet(width)) return 24.0;
    return 32.0; // Desktop
  }
}
