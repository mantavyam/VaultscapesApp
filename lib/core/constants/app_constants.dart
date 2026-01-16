class AppSpacing {
  // Base spacing unit (4dp)
  static const double baseUnit = 4.0;

  // Spacing tokens based on multiples of base unit
  static const double xxs = baseUnit; // 4dp - Icon padding
  static const double xs = baseUnit * 2; // 8dp - Tight spacing
  static const double sm = baseUnit * 3; // 12dp - Default item spacing
  static const double md = baseUnit * 4; // 16dp - Screen padding, section spacing
  static const double lg = baseUnit * 6; // 24dp - Large section gaps
  static const double xl = baseUnit * 8; // 32dp - Screen margins
  static const double xxl = baseUnit * 12; // 48dp - Major section breaks

  // Common edge insets
  static const double screenPadding = md; // 16dp
  static const double screenMargin = xl; // 32dp
  static const double cardPadding = lg; // 24dp
  static const double sectionSpacing = lg; // 24dp
}

class AppSizes {
  // Button heights
  static const double buttonHeight = 48.0;
  
  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  
  // Avatar sizes
  static const double avatarSmall = 40.0;
  static const double avatarMedium = 56.0;
  static const double avatarLarge = 80.0;
  
  // List tile heights
  static const double listTileHeight = 56.0;
  static const double quickLinkTileHeight = 48.0;
  
  // Bottom navigation bar
  static const double bottomNavHeight = 56.0;
  
  // Border radius
  static const double borderRadius = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  // Drag handle
  static const double dragHandleWidth = 32.0;
  static const double dragHandleHeight = 4.0;
  
  // Progress indicator
  static const double progressIndicatorHeight = 4.0;
}