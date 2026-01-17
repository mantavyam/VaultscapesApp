/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Vaultscapes';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'An Open-Source Database for Collaborating and Viewing Course Resources';

  // Semester Info
  static const int totalSemesters = 8;

  // Cache Settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const String markdownCacheBox = 'markdown_cache';
  static const String userPreferencesBox = 'user_preferences';

  // Mock Auth Settings (Phase 1)
  static const Duration mockAuthDelay = Duration(seconds: 2);

  // WebView Settings
  static const Duration webViewTimeout = Duration(seconds: 15);

  // Form Limits
  static const int maxFeedbackFiles = 5;
  static const int maxFeedbackFileSizeMB = 10;
  static const int maxCollaborationFiles = 10;
  static const int maxCollaborationFileSizeMB = 5;

  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Semester Descriptions
  static const Map<int, String> semesterDescriptions = {
    1: 'Foundational Courses',
    2: 'Core Fundamentals',
    3: 'Data Structures & Algorithms',
    4: 'Database & Networks',
    5: 'Software Engineering',
    6: 'Advanced Topics',
    7: 'Specialization Electives',
    8: 'Project & Industry Prep',
  };
}
