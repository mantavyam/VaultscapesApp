import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'color_scheme.dart';

/// Application theme configuration using shadcn_flutter
class AppTheme {
  AppTheme._();

  /// Custom Urbanist typography
  static Typography get _urbanistTypography {
    const String fontFamily = 'Urbanist';

    return Typography.geist(
      sans: const TextStyle(fontFamily: fontFamily),
      mono: const TextStyle(fontFamily: fontFamily),
      xSmall: const TextStyle(fontSize: 12, fontFamily: fontFamily),
      small: const TextStyle(fontSize: 14, fontFamily: fontFamily),
      base: const TextStyle(fontSize: 16, fontFamily: fontFamily),
      large: const TextStyle(fontSize: 18, fontFamily: fontFamily),
      xLarge: const TextStyle(fontSize: 20, fontFamily: fontFamily),
      x2Large: const TextStyle(fontSize: 24, fontFamily: fontFamily),
      x3Large: const TextStyle(fontSize: 30, fontFamily: fontFamily),
      x4Large: const TextStyle(fontSize: 36, fontFamily: fontFamily),
      x5Large: const TextStyle(fontSize: 48, fontFamily: fontFamily),
      x6Large: const TextStyle(fontSize: 60, fontFamily: fontFamily),
      x7Large: const TextStyle(fontSize: 72, fontFamily: fontFamily),
      x8Large: const TextStyle(fontSize: 96, fontFamily: fontFamily),
      x9Large: const TextStyle(fontSize: 144, fontFamily: fontFamily),
      thin: const TextStyle(fontWeight: FontWeight.w100, fontFamily: fontFamily),
      light: const TextStyle(fontWeight: FontWeight.w300, fontFamily: fontFamily),
      extraLight: const TextStyle(fontWeight: FontWeight.w200, fontFamily: fontFamily),
      normal: const TextStyle(fontWeight: FontWeight.w400, fontFamily: fontFamily),
      medium: const TextStyle(fontWeight: FontWeight.w500, fontFamily: fontFamily),
      semiBold: const TextStyle(fontWeight: FontWeight.w600, fontFamily: fontFamily),
      bold: const TextStyle(fontWeight: FontWeight.w700, fontFamily: fontFamily),
      extraBold: const TextStyle(fontWeight: FontWeight.w800, fontFamily: fontFamily),
      black: const TextStyle(fontWeight: FontWeight.w900, fontFamily: fontFamily),
      italic: const TextStyle(fontStyle: FontStyle.italic, fontFamily: fontFamily),
      h1: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, fontFamily: fontFamily),
      h2: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, fontFamily: fontFamily),
      h3: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, fontFamily: fontFamily),
      h4: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: fontFamily),
      p: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, fontFamily: fontFamily),
      blockQuote: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, fontFamily: fontFamily),
      inlineCode: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: fontFamily),
      lead: const TextStyle(fontSize: 20, fontFamily: fontFamily),
      textLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: fontFamily),
      textSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: fontFamily),
      textMuted: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, fontFamily: fontFamily),
    );
  }

  /// Get the light theme data for the application
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: LegacyColorSchemes.lightZinc(),
      radius: 0.5,
      typography: _urbanistTypography,
    );
  }

  /// Get the dark theme data for the application
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: LegacyColorSchemes.darkZinc(),
      radius: 0.5,
      typography: _urbanistTypography,
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
