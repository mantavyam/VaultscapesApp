import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing user preferences
class UserPreferencesRepository {
  static const String _homepagePreferenceKey = 'homepage_preference';
  static const String _themeKey = 'theme_mode';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _lastVisitedSemesterKey = 'last_visited_semester';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get homepage preference (returns semester id or null for root)
  Future<String?> getHomepagePreference() async {
    final prefs = await this.prefs;
    return prefs.getString(_homepagePreferenceKey);
  }

  /// Set homepage preference
  Future<void> setHomepagePreference(String? semesterId) async {
    final prefs = await this.prefs;
    if (semesterId == null) {
      await prefs.remove(_homepagePreferenceKey);
    } else {
      await prefs.setString(_homepagePreferenceKey, semesterId);
    }
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final prefs = await this.prefs;
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding as complete
  Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await this.prefs;
    await prefs.setBool(_onboardingCompleteKey, complete);
  }

  /// Get last visited semester
  Future<int?> getLastVisitedSemester() async {
    final prefs = await this.prefs;
    return prefs.getInt(_lastVisitedSemesterKey);
  }

  /// Set last visited semester
  Future<void> setLastVisitedSemester(int semesterId) async {
    final prefs = await this.prefs;
    await prefs.setInt(_lastVisitedSemesterKey, semesterId);
  }

  /// Get theme mode (light/dark/system)
  Future<String> getThemeMode() async {
    final prefs = await this.prefs;
    return prefs.getString(_themeKey) ?? 'system';
  }

  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    final prefs = await this.prefs;
    await prefs.setString(_themeKey, mode);
  }

  /// Clear all preferences
  Future<void> clearAll() async {
    final prefs = await this.prefs;
    await prefs.clear();
  }
}
