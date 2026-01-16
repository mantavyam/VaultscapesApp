import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E88E5); // Blue 600
  static const Color primaryLight = Color(0xFF64B5F6); // Blue 400
  static const Color primaryDark = Color(0xFF1565C0); // Blue 800

  // Secondary Colors
  static const Color secondary = Color(0xFFFFC107); // Amber 500
  static const Color secondaryLight = Color(0xFFFFD54F); // Amber 300
  static const Color secondaryDark = Color(0xFFFFA000); // Amber 700

  // Neutral Colors
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color surface = Color(0xFFF5F5F5); // Grey 100
  static const Color outline = Color(0xFFE0E0E0); // Grey 300
  static const Color textPrimary = Color(0xFF212121); // Grey 900
  static const Color textSecondary = Color(0xFF757575); // Grey 600

  // Status Colors
  static const Color error = Color(0xFFE53935); // Red 600
  static const Color success = Color(0xFF43A047); // Green 600
  static const Color warning = Color(0xFFFB8C00); // Orange 600

  // Additional utility colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  
  // Creates a material color swatch from primary color
  static MaterialColor get primarySwatch {
    return MaterialColor(0xFF1E88E5, const {
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: primary,
      600: Color(0xFF1E88E5),
      700: primaryDark,
      800: Color(0xFF1976D2),
      900: Color(0xFF0D47A1),
    });
  }
}