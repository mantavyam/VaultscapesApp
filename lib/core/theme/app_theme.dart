import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'color_scheme.dart';

/// Application theme configuration using shadcn_flutter
class AppTheme {
  AppTheme._();

  /// Get the light theme data for the application
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: LegacyColorSchemes.lightZinc(),
      radius: 0.5,
    );
  }

  /// Get the dark theme data for the application
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: LegacyColorSchemes.darkZinc(),
      radius: 0.5,
    );
  }

  /// Custom card decoration
  static BoxDecoration cardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.border,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Semester card gradient decoration
  static BoxDecoration semesterCardDecoration(int semester) {
    final color = AppColorScheme.getSemesterColor(semester);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          color.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
