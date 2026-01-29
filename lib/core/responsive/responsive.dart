// Responsive layout utilities for Vaultscapes
//
// This module provides comprehensive support for dynamic resizing across:
// - Split-screen (horizontal/vertical)
// - Pop-up windows
// - Device rotation
// - Multi-window scenarios
//
// ## Core Components
//
// ### ResponsiveLayout
// Central utility for viewport detection and responsive value calculations.
//
// ```dart
// final windowSize = ResponsiveLayout.getWindowSize(context);
// final padding = ResponsiveLayout.getResponsivePadding(context);
// ```
//
// ### Responsive Dimensions
// Adaptive form dimensions, spacing, typography, and icons.
//
// ```dart
// final inputHeight = ResponsiveFormDimensions.getInputHeight(context);
// final spacing = ResponsiveSpacing.md(context);
// final fontSize = ResponsiveTypography.body(context);
// ```
//
// ### Responsive Widgets
// Pre-built widgets that adapt to viewport changes.
//
// ```dart
// ResponsiveContainer(child: myContent)
// ResponsiveFormContainer(child: myForm)
// OrientationAwareLayout(portrait: portraitView, landscape: landscapeView)
// ResponsiveLayoutSwitcher(compact: phoneLayout, expanded: tabletLayout)
// ```
//
// ## Breakpoints
//
// Width classes (aligned with Material Design 3):
// - Micro: < 360dp (pop-ups, tiny split-screen)
// - Compact: 360-600dp (phone portrait)
// - Medium: 600-840dp (phone landscape, tablet portrait)
// - Expanded: 840-1200dp (tablet landscape)
// - Large: 1200-1600dp (desktop)
// - XLarge: ≥1600dp (ultra-wide)
//
// Height classes:
// - Compressed: < 480dp (landscape phones, horizontal split)
// - Normal: 480-900dp (standard)
// - Extended: ≥900dp (tablets, vertical monitors)

export 'responsive_layout.dart';
export 'responsive_dimensions.dart';
export 'responsive_widgets.dart';
