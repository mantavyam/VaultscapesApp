import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'responsive_layout.dart';

/// Responsive form dimensions that adapt to viewport size
/// Replaces fixed FormDimensions constants with context-aware calculations
class ResponsiveFormDimensions {
  ResponsiveFormDimensions._();

  /// Get adaptive input field height
  static double getInputHeight(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    final viewportHeight = windowSize.height;

    // Dynamic height based on viewport, with reasonable bounds
    return (viewportHeight * 0.065).clamp(
      windowSize.isMicro ? 44.0 : 48.0, // Min: smaller for micro
      56.0, // Max: standard Material height
    );
  }

  /// Get adaptive button height
  static double getButtonHeight(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 48.0 : 56.0;
  }

  /// Get minimum touch target size (accessibility compliant)
  static double getMinTouchTarget(BuildContext context) {
    return ResponsiveLayout.getMinTouchTarget(context);
  }

  /// Get adaptive border radius
  static double getBorderRadius(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 6.0 : 8.0;
  }

  /// Get adaptive card border radius
  static double getCardRadius(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 10.0 : 12.0;
  }

  /// Get adaptive section border radius
  static double getSectionRadius(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 12.0 : 16.0;
  }

  /// Get adaptive max form width
  static double getMaxFormWidth(BuildContext context) {
    return ResponsiveLayout.getMaxFormWidth(context);
  }
}

/// Responsive spacing that adapts to viewport size
/// Follows 8-point grid system with viewport adjustments
class ResponsiveSpacing {
  ResponsiveSpacing._();

  /// Extra small spacing
  static double xs(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 3.0 : 4.0;
  }

  /// Small spacing
  static double sm(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 6.0 : 8.0;
  }

  /// Medium spacing
  static double md(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 12.0 : 16.0;
  }

  /// Large spacing
  static double lg(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 18.0 : 24.0;
  }

  /// Extra large spacing
  static double xl(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 24.0 : 32.0;
  }

  /// Double extra large spacing
  static double xxl(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 36.0 : 48.0;
  }

  /// Triple extra large spacing
  static double xxxl(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 48.0 : 64.0;
  }

  /// Get vertical spacing that adapts to viewport height
  static double vertical(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return (height * 0.02).clamp(8.0, 32.0);
  }

  /// Get horizontal spacing that adapts to viewport width
  static double horizontal(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width * 0.04).clamp(12.0, 32.0);
  }

  /// Get section spacing (between major sections)
  static double section(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return switch (windowSize.widthClass) {
      WidthClass.micro => 20.0,
      WidthClass.compact => 24.0,
      WidthClass.medium => 32.0,
      WidthClass.expanded => 40.0,
      WidthClass.large => 48.0,
      WidthClass.xlarge => 48.0,
    };
  }
}

/// Responsive typography scaling
class ResponsiveTypography {
  ResponsiveTypography._();

  /// Get base font size multiplier for the current viewport
  static double getScaleFactor(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    // Scale between 0.875 (micro) and 1.125 (xlarge)
    return switch (windowSize.widthClass) {
      WidthClass.micro => 0.875,
      WidthClass.compact => 1.0,
      WidthClass.medium => 1.0,
      WidthClass.expanded => 1.0625,
      WidthClass.large => 1.0625,
      WidthClass.xlarge => 1.125,
    };
  }

  /// Scale a font size for the current viewport
  static double scaleFontSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }

  /// Get adaptive heading 1 size (largest)
  static double h1(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    // Use viewport diagonal for more balanced scaling
    final diagonal = math.sqrt(
      windowSize.width * windowSize.width +
          windowSize.height * windowSize.height,
    );
    return (diagonal * 0.035).clamp(24.0, 48.0);
  }

  /// Get adaptive heading 2 size
  static double h2(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return switch (windowSize.widthClass) {
      WidthClass.micro => 20.0,
      WidthClass.compact => 24.0,
      WidthClass.medium => 28.0,
      WidthClass.expanded => 32.0,
      WidthClass.large => 32.0,
      WidthClass.xlarge => 36.0,
    };
  }

  /// Get adaptive heading 3 size
  static double h3(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return switch (windowSize.widthClass) {
      WidthClass.micro => 16.0,
      WidthClass.compact => 18.0,
      WidthClass.medium => 20.0,
      WidthClass.expanded => 22.0,
      WidthClass.large => 24.0,
      WidthClass.xlarge => 24.0,
    };
  }

  /// Get adaptive body text size
  static double body(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 14.0 : 15.0;
  }

  /// Get adaptive small/caption text size
  static double caption(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 11.0 : 12.0;
  }

  /// Get adaptive label text size (for form labels, etc.)
  static double label(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 13.0 : 14.0;
  }
}

/// Responsive icon sizing
class ResponsiveIcons {
  ResponsiveIcons._();

  /// Extra small icon size
  static double xs(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 12.0 : 14.0;
  }

  /// Small icon size
  static double sm(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 16.0 : 18.0;
  }

  /// Medium icon size (default)
  static double md(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 20.0 : 24.0;
  }

  /// Large icon size
  static double lg(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 28.0 : 32.0;
  }

  /// Extra large icon size
  static double xl(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return windowSize.isMicro ? 36.0 : 44.0;
  }

  /// Get icon size scaled proportionally to viewport
  static double proportional(BuildContext context, {double factor = 0.08}) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return (windowSize.minDimension * factor).clamp(16.0, 48.0);
  }

  /// Get section header icon size
  static double sectionHeader(BuildContext context) {
    final windowSize = ResponsiveLayout.getWindowSize(context);
    return (windowSize.width * 0.06).clamp(20.0, 32.0);
  }
}

/// Responsive card proportions for selection cards, semester cards, etc.
class ResponsiveCardSizing {
  ResponsiveCardSizing._();

  /// Get proportional icon size for cards
  static double cardIcon(BuildContext context, double cardMinDimension) {
    return (cardMinDimension * 0.10).clamp(20.0, 36.0);
  }

  /// Get proportional title font size for cards
  static double cardTitle(BuildContext context, double cardMinDimension) {
    return (cardMinDimension * 0.12).clamp(20.0, 38.0);
  }

  /// Get proportional subtitle font size for cards
  static double cardSubtitle(BuildContext context, double cardMinDimension) {
    return (cardMinDimension * 0.06).clamp(12.0, 18.0);
  }

  /// Get proportional badge font size for cards
  static double cardBadge(BuildContext context, double cardMinDimension) {
    return (cardMinDimension * 0.05).clamp(10.0, 14.0);
  }

  /// Get proportional action button size for cards
  static double cardButton(BuildContext context, double cardMinDimension) {
    // Ensure minimum touch target size
    final calculated = (cardMinDimension * 0.18).clamp(44.0, 64.0);
    return calculated;
  }

  /// Get proportional padding for cards
  static double cardPadding(BuildContext context, double cardMinDimension) {
    return (cardMinDimension * 0.08).clamp(16.0, 32.0);
  }
}
