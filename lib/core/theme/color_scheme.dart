import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Application color scheme following shadcn design system
class AppColorScheme {
  AppColorScheme._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Secondary Colors
  static const Color secondary = Color(0xFFF1F5F9);
  static const Color secondaryForeground = Color(0xFF0F172A);

  // Destructive/Error Colors
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  // Muted Colors
  static const Color muted = Color(0xFFF1F5F9);
  static const Color mutedForeground = Color(0xFF64748B);

  // Accent Colors
  static const Color accent = Color(0xFFF1F5F9);
  static const Color accentForeground = Color(0xFF0F172A);

  // Background & Foreground
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0F172A);

  // Card Colors
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF0F172A);

  // Border & Input Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color input = Color(0xFFE2E8F0);
  static const Color ring = Color(0xFF6366F1);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Semester Card Colors (for visual distinction)
  static const List<Color> semesterColors = [
    Color(0xFF6366F1), // Semester 1 - Indigo
    Color(0xFF8B5CF6), // Semester 2 - Violet
    Color(0xFFEC4899), // Semester 3 - Pink
    Color(0xFFF97316), // Semester 4 - Orange
    Color(0xFF14B8A6), // Semester 5 - Teal
    Color(0xFF06B6D4), // Semester 6 - Cyan
    Color(0xFF3B82F6), // Semester 7 - Blue
    Color(0xFF10B981), // Semester 8 - Emerald
  ];

  static Color getSemesterColor(int semester) {
    if (semester < 1 || semester > 8) return primary;
    return semesterColors[semester - 1];
  }
}
