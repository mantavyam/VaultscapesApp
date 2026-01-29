import 'package:flutter/widgets.dart';
import 'responsive_layout.dart';

/// A responsive container widget that adapts padding and max-width
/// based on the current viewport size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final bool center;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.center = true,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    // Get window size for responsive adaptations
    final _ = ResponsiveLayout.getWindowSize(context);

    final adaptivePadding =
        padding ??
        EdgeInsets.all(
          ResponsiveLayout.getResponsiveValue(
            context: context,
            micro: 12.0,
            compact: 16.0,
            medium: 24.0,
            expanded: 32.0,
          ),
        );

    final adaptiveMaxWidth =
        maxWidth ?? ResponsiveLayout.getMaxContentWidth(context);

    Widget content = Padding(padding: adaptivePadding, child: child);

    if (adaptiveMaxWidth != double.infinity) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: adaptiveMaxWidth),
        child: content,
      );
    }

    if (center) {
      content = Center(child: content);
    }

    return content;
  }
}

/// A responsive form container with appropriate max-width and padding for forms
class ResponsiveFormContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsiveFormContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final adaptivePadding =
        padding ??
        EdgeInsets.all(
          ResponsiveLayout.getResponsiveValue(
            context: context,
            micro: 12.0,
            compact: 16.0,
            medium: 24.0,
            expanded: 32.0,
          ),
        );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.getMaxFormWidth(context),
        ),
        child: Padding(padding: adaptivePadding, child: child),
      ),
    );
  }
}

/// A widget that switches between portrait and landscape layouts
/// based on orientation and viewport width
class OrientationAwareLayout extends StatelessWidget {
  final Widget portrait;
  final Widget? landscape;
  final double breakpoint;

  const OrientationAwareLayout({
    super.key,
    required this.portrait,
    this.landscape,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final windowSize = ResponsiveLayout.getWindowSize(context);

        // Use landscape layout if:
        // 1. Orientation is landscape, OR
        // 2. Width exceeds breakpoint (for wide portrait tablets)
        final useLandscape =
            orientation == Orientation.landscape ||
            windowSize.width > breakpoint;

        if (useLandscape && landscape != null) {
          return landscape!;
        }

        return portrait;
      },
    );
  }
}

/// A widget that provides different layouts based on width class
class ResponsiveLayoutSwitcher extends StatelessWidget {
  /// Layout for micro viewports (< 360dp)
  final Widget? micro;

  /// Layout for compact viewports (360-600dp) - required as baseline
  final Widget compact;

  /// Layout for medium viewports (600-840dp)
  final Widget? medium;

  /// Layout for expanded viewports (840-1200dp)
  final Widget? expanded;

  /// Layout for large viewports (1200-1600dp)
  final Widget? large;

  /// Layout for extra-large viewports (≥1600dp)
  final Widget? xlarge;

  const ResponsiveLayoutSwitcher({
    super.key,
    this.micro,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
    this.xlarge,
  });

  @override
  Widget build(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);

    return switch (windowSize.widthClass) {
      WidthClass.micro => micro ?? compact,
      WidthClass.compact => compact,
      WidthClass.medium => medium ?? compact,
      WidthClass.expanded => expanded ?? medium ?? compact,
      WidthClass.large => large ?? expanded ?? medium ?? compact,
      WidthClass.xlarge => xlarge ?? large ?? expanded ?? medium ?? compact,
    };
  }
}

/// A widget that builds based on current window size
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, WindowSize windowSize) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return builder(context, windowSize);
  }
}

/// A conditional wrapper that applies a layout change only in certain viewport sizes
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;

  /// Show only in micro viewports
  final bool? visibleInMicro;

  /// Show only in compact viewports
  final bool? visibleInCompact;

  /// Show only in medium viewports
  final bool? visibleInMedium;

  /// Show only in expanded viewports
  final bool? visibleInExpanded;

  /// Show only in large viewports
  final bool? visibleInLarge;

  /// Show only in xlarge viewports
  final bool? visibleInXLarge;

  /// Replacement widget when not visible (defaults to SizedBox.shrink)
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleInMicro,
    this.visibleInCompact,
    this.visibleInMedium,
    this.visibleInExpanded,
    this.visibleInLarge,
    this.visibleInXLarge,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);

    final isVisible = switch (windowSize.widthClass) {
      WidthClass.micro => visibleInMicro ?? true,
      WidthClass.compact => visibleInCompact ?? true,
      WidthClass.medium => visibleInMedium ?? true,
      WidthClass.expanded => visibleInExpanded ?? true,
      WidthClass.large => visibleInLarge ?? true,
      WidthClass.xlarge => visibleInXLarge ?? true,
    };

    if (isVisible) {
      return child;
    }

    return replacement ?? const SizedBox.shrink();
  }
}

/// A widget that provides responsive spacing
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  /// Multiplier for responsive height calculation
  final double? heightFactor;

  /// Multiplier for responsive width calculation
  final double? widthFactor;

  const ResponsiveSizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
    this.heightFactor,
    this.widthFactor,
  });

  /// Creates a responsive vertical spacer
  const ResponsiveSizedBox.vertical(double size, {super.key})
    : height = size,
      width = null,
      child = null,
      heightFactor = null,
      widthFactor = null;

  /// Creates a responsive horizontal spacer
  const ResponsiveSizedBox.horizontal(double size, {super.key})
    : width = size,
      height = null,
      child = null,
      heightFactor = null,
      widthFactor = null;

  @override
  Widget build(BuildContext context) {
    double? effectiveWidth = width;
    double? effectiveHeight = height;

    if (widthFactor != null) {
      final viewportWidth = MediaQuery.of(context).size.width;
      effectiveWidth = viewportWidth * widthFactor!;
    }

    if (heightFactor != null) {
      final viewportHeight = MediaQuery.of(context).size.height;
      effectiveHeight = viewportHeight * heightFactor!;
    }

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: child,
    );
  }
}
