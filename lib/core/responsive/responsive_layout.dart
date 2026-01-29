import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Width class breakpoints aligned with Material Design 3 guidelines
/// and Android's WindowSizeClass API
enum WidthClass {
  /// Pop-up windows, tiny split-screen (< 360dp)
  micro,

  /// Phone portrait, narrow split (360dp ≤ width < 600dp)
  compact,

  /// Phone landscape, tablet portrait (600dp ≤ width < 840dp)
  medium,

  /// Tablet landscape, small desktop (840dp ≤ width < 1200dp)
  expanded,

  /// Desktop (1200dp ≤ width < 1600dp)
  large,

  /// Ultra-wide displays (≥ 1600dp)
  xlarge,
}

/// Height class breakpoints for vertical viewport considerations
enum HeightClass {
  /// Landscape phones, horizontal split (< 480dp)
  compressed,

  /// Standard viewports (480dp ≤ height < 900dp)
  normal,

  /// Tablets, vertical monitors (≥ 900dp)
  extended,
}

/// Window mode detection for multi-window scenarios
enum WindowMode {
  /// Full screen mode
  fullscreen,

  /// Vertical split-screen (side by side)
  splitVertical,

  /// Horizontal split-screen (top and bottom)
  splitHorizontal,

  /// Floating pop-up window
  popup,
}

/// Represents the current window size with classification
class WindowSize {
  final double width;
  final double height;
  final WidthClass widthClass;
  final HeightClass heightClass;

  const WindowSize({
    required this.width,
    required this.height,
    required this.widthClass,
    required this.heightClass,
  });

  /// Minimum dimension (useful for proportional calculations)
  double get minDimension => math.min(width, height);

  /// Maximum dimension
  double get maxDimension => math.max(width, height);

  /// Aspect ratio (width / height)
  double get aspectRatio => width / height;

  /// Whether the viewport is in landscape orientation
  bool get isLandscape => width > height;

  /// Whether the viewport is in portrait orientation
  bool get isPortrait => height >= width;

  /// Whether this is a micro viewport (smallest)
  bool get isMicro => widthClass == WidthClass.micro;

  /// Whether this is a compact viewport (phone portrait)
  bool get isCompact => widthClass == WidthClass.compact;

  /// Whether this is a medium viewport (phone landscape/tablet portrait)
  bool get isMedium => widthClass == WidthClass.medium;

  /// Whether this is an expanded viewport (tablet landscape)
  bool get isExpanded => widthClass == WidthClass.expanded;

  /// Whether this is a large viewport (desktop)
  bool get isLarge => widthClass == WidthClass.large;

  /// Whether this is an extra-large viewport (ultra-wide)
  bool get isXLarge => widthClass == WidthClass.xlarge;

  /// Whether height is compressed (landscape/split)
  bool get isHeightCompressed => heightClass == HeightClass.compressed;

  /// Whether this is a narrow viewport (micro or compact)
  bool get isNarrow => isMicro || isCompact;

  /// Whether this is a wide viewport (expanded or larger)
  bool get isWide => isExpanded || isLarge || isXLarge;

  @override
  String toString() =>
      'WindowSize($width x $height, $widthClass, $heightClass)';
}

/// Central utility for responsive layout calculations
class ResponsiveLayout {
  ResponsiveLayout._();

  /// Get the current window size with classifications
  static WindowSize getWindowSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;

    return WindowSize(
      width: width,
      height: height,
      widthClass: _getWidthClass(width),
      heightClass: _getHeightClass(height),
    );
  }

  /// Determine width class from width value
  static WidthClass _getWidthClass(double width) {
    if (width < 360) return WidthClass.micro;
    if (width < 600) return WidthClass.compact;
    if (width < 840) return WidthClass.medium;
    if (width < 1200) return WidthClass.expanded;
    if (width < 1600) return WidthClass.large;
    return WidthClass.xlarge;
  }

  /// Determine height class from height value
  static HeightClass _getHeightClass(double height) {
    if (height < 480) return HeightClass.compressed;
    if (height < 900) return HeightClass.normal;
    return HeightClass.extended;
  }

  /// Get a responsive value based on width class
  /// Larger classes fall back to the next smaller defined value
  static double getResponsiveValue({
    required BuildContext context,
    required double micro,
    required double compact,
    required double medium,
    double? expanded,
    double? large,
    double? xlarge,
  }) {
    final windowSize = getWindowSize(context);
    return switch (windowSize.widthClass) {
      WidthClass.micro => micro,
      WidthClass.compact => compact,
      WidthClass.medium => medium,
      WidthClass.expanded => expanded ?? medium,
      WidthClass.large => large ?? expanded ?? medium,
      WidthClass.xlarge => xlarge ?? large ?? expanded ?? medium,
    };
  }

  /// Get responsive padding based on viewport width
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.all(12);
    if (width < 600) return const EdgeInsets.all(16);
    if (width < 840) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  /// Get responsive horizontal padding only
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 12);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 16);
    if (width < 840) return const EdgeInsets.symmetric(horizontal: 24);
    return const EdgeInsets.symmetric(horizontal: 32);
  }

  /// Get optimal max width for content containers (forms, cards, etc.)
  static double getMaxContentWidth(BuildContext context) {
    final windowSize = getWindowSize(context);
    return switch (windowSize.widthClass) {
      WidthClass.micro => double.infinity,
      WidthClass.compact => 540,
      WidthClass.medium => 640,
      WidthClass.expanded => 720,
      WidthClass.large => 960,
      WidthClass.xlarge => 1200,
    };
  }

  /// Get optimal max width for form containers
  static double getMaxFormWidth(BuildContext context) {
    final windowSize = getWindowSize(context);
    final viewportWidth = windowSize.width;
    return switch (windowSize.widthClass) {
      WidthClass.micro => viewportWidth - 32, // Full width minus margins
      WidthClass.compact => 540,
      WidthClass.medium => 640,
      WidthClass.expanded => 720,
      WidthClass.large => 720,
      WidthClass.xlarge => 720,
    };
  }

  /// Get optimal sidebar width for content screens
  static double getSidebarWidth(BuildContext context) {
    final windowSize = getWindowSize(context);
    return switch (windowSize.widthClass) {
      WidthClass.micro => windowSize.width * 0.85,
      WidthClass.compact => math.min(windowSize.width * 0.80, 320),
      WidthClass.medium => 320,
      WidthClass.expanded => 300,
      WidthClass.large => 280,
      WidthClass.xlarge => 280,
    };
  }

  /// Get number of columns for grid layouts
  static int getColumnCount(BuildContext context) {
    final windowSize = getWindowSize(context);
    return switch (windowSize.widthClass) {
      WidthClass.micro => 1,
      WidthClass.compact => 1,
      WidthClass.medium => 2,
      WidthClass.expanded => 2,
      WidthClass.large => 3,
      WidthClass.xlarge => 4,
    };
  }

  /// Get carousel viewport fraction based on width class
  static double getCarouselViewportFraction(BuildContext context) {
    final windowSize = getWindowSize(context);
    return getCarouselViewportFractionFromSize(windowSize);
  }

  /// Get carousel viewport fraction from WindowSize directly
  static double getCarouselViewportFractionFromSize(WindowSize windowSize) {
    return switch (windowSize.widthClass) {
      WidthClass.micro => 0.95,
      WidthClass.compact => 0.85,
      WidthClass.medium => 0.80,
      WidthClass.expanded => 0.75,
      WidthClass.large => 0.60,
      WidthClass.xlarge => 0.50,
    };
  }

  /// Check if should use grid layout instead of carousel (for wide viewports)
  static bool shouldUseGridLayout(BuildContext context) {
    final windowSize = getWindowSize(context);
    return windowSize.isExpanded || windowSize.isLarge || windowSize.isXLarge;
  }

  /// Check if should use horizontal layout for cards (e.g., Synergy selection)
  static bool shouldUseHorizontalCardLayout(BuildContext context) {
    final windowSize = getWindowSize(context);
    // Use horizontal layout in landscape medium+ or expanded+
    return (windowSize.isMedium && windowSize.isLandscape) ||
        windowSize.isExpanded ||
        windowSize.isLarge ||
        windowSize.isXLarge;
  }

  /// Check if should show navigation labels (hide in narrow viewports)
  static bool shouldShowNavigationLabels(BuildContext context) {
    final windowSize = getWindowSize(context);
    return !windowSize.isMicro;
  }

  /// Check if should use bottom navigation (vs side rail)
  static bool shouldUseBottomNavigation(BuildContext context) {
    final windowSize = getWindowSize(context);
    return windowSize.isMicro || windowSize.isCompact || windowSize.isMedium;
  }

  /// Check if should show dot indicators (hide in very narrow viewports)
  static bool shouldShowDotIndicators(BuildContext context) {
    final windowSize = getWindowSize(context);
    return windowSize.width > 400;
  }

  /// Check if PageView swipe should be disabled (micro viewports)
  static bool shouldDisablePageSwipe(BuildContext context) {
    final windowSize = getWindowSize(context);
    return windowSize.isMicro;
  }

  /// Get responsive vertical spacing
  static double getVerticalSpacing(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return (height * 0.02).clamp(8.0, 32.0);
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {double baseSize = 24}) {
    final windowSize = getWindowSize(context);
    final scaleFactor = switch (windowSize.widthClass) {
      WidthClass.micro => 0.85,
      WidthClass.compact => 1.0,
      WidthClass.medium => 1.0,
      WidthClass.expanded => 1.1,
      WidthClass.large => 1.15,
      WidthClass.xlarge => 1.2,
    };
    return baseSize * scaleFactor;
  }

  /// Get minimum touch target size (accessibility compliant)
  static double getMinTouchTarget(BuildContext context) {
    final windowSize = getWindowSize(context);
    // Slightly smaller in micro viewports but never below 44dp
    return windowSize.isMicro ? 44.0 : 48.0;
  }
}

/// Multi-window detection utilities
class WindowModeDetector {
  WindowModeDetector._();

  /// Detect the current window mode (fullscreen, split, popup)
  static WindowMode detectMode(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    // Detect pop-up window (small size)
    final isProbablyPopup = size.width < 360 && size.height < 480;

    if (isProbablyPopup) {
      return WindowMode.popup;
    }

    // Heuristic-based split-screen detection
    // In split-screen, the viewport is significantly smaller than typical device
    // We can't detect this perfectly, but we can make educated guesses

    // Very narrow viewport suggests vertical split
    if (size.width < 400 && size.height > size.width * 1.5) {
      return WindowMode.splitVertical;
    }

    // Very short viewport suggests horizontal split
    if (size.height < 400 && size.width > size.height * 1.5) {
      return WindowMode.splitHorizontal;
    }

    return WindowMode.fullscreen;
  }

  /// Check if the app is in any compact multi-window mode
  static bool isCompactMode(BuildContext context) {
    final mode = detectMode(context);
    return mode == WindowMode.popup ||
        mode == WindowMode.splitVertical ||
        mode == WindowMode.splitHorizontal;
  }

  /// Check if the app is in split-screen mode
  static bool isSplitScreen(BuildContext context) {
    final mode = detectMode(context);
    return mode == WindowMode.splitVertical ||
        mode == WindowMode.splitHorizontal;
  }

  /// Check if the app is in popup mode
  static bool isPopup(BuildContext context) {
    return detectMode(context) == WindowMode.popup;
  }
}
