import 'package:intl/intl.dart';

/// General helper utilities
class Helpers {
  Helpers._();

  /// Get greeting based on time of day
  static String getGreeting({String? name}) {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    if (name != null && name.isNotEmpty) {
      return '$greeting, $name!';
    }
    return '$greeting!';
  }

  /// Format date to readable string
  static String formatDate(DateTime date, {String? pattern}) {
    final formatter = DateFormat(pattern ?? 'MMM d, yyyy');
    return formatter.format(date);
  }

  /// Format file size to human readable
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get semester ordinal (1st, 2nd, 3rd, etc.)
  static String getSemesterOrdinal(int semester) {
    if (semester < 1 || semester > 8) return 'Semester $semester';

    const suffixes = ['st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th'];
    return '$semester${suffixes[semester - 1]} Semester';
  }

  /// Generate unique ID for mock authentication
  static String generateUniqueId() {
    final now = DateTime.now();
    return 'user_${now.millisecondsSinceEpoch}';
  }

  /// Check if cache is expired
  static bool isCacheExpired(DateTime cachedAt, Duration expiration) {
    return DateTime.now().difference(cachedAt) > expiration;
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Get initials from name
  static String getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }
}
