import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/preferences_model.dart';

class StorageService {
  static const String _keyUserData = 'user_data';
  static const String _keyPreferences = 'preferences';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyHasSeenWelcome = 'has_seen_welcome';

  static SharedPreferences? _preferences;

  // Initialize shared preferences
  static Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  // Get SharedPreferences instance
  static SharedPreferences get _prefs {
    if (_preferences == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _preferences!;
  }

  // User data methods
  static Future<bool> saveUser(UserModel user) async {
    try {
      final userData = json.encode(user.toJson());
      return await _prefs.setString(_keyUserData, userData);
    } catch (e) {
      return false;
    }
  }

  static UserModel? getUser() {
    try {
      final userData = _prefs.getString(_keyUserData);
      if (userData == null) return null;
      
      final userMap = json.decode(userData) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> removeUser() async {
    return await _prefs.remove(_keyUserData);
  }

  // Preferences methods
  static Future<bool> savePreferences(PreferencesModel preferences) async {
    try {
      final prefsData = json.encode(preferences.toJson());
      return await _prefs.setString(_keyPreferences, prefsData);
    } catch (e) {
      return false;
    }
  }

  static PreferencesModel getPreferences() {
    try {
      final prefsData = _prefs.getString(_keyPreferences);
      if (prefsData == null) return PreferencesModel.initial();
      
      final prefsMap = json.decode(prefsData) as Map<String, dynamic>;
      return PreferencesModel.fromJson(prefsMap);
    } catch (e) {
      return PreferencesModel.initial();
    }
  }

  static Future<bool> removePreferences() async {
    return await _prefs.remove(_keyPreferences);
  }

  // Auth token methods (for Phase 2)
  static Future<bool> saveAuthToken(String token) async {
    return await _prefs.setString(_keyAuthToken, token);
  }

  static String? getAuthToken() {
    return _prefs.getString(_keyAuthToken);
  }

  static Future<bool> removeAuthToken() async {
    return await _prefs.remove(_keyAuthToken);
  }

  // Welcome screen flag methods
  static Future<bool> markWelcomeSeen() async {
    return await _prefs.setBool(_keyHasSeenWelcome, true);
  }

  static bool hasSeenWelcome() {
    return _prefs.getBool(_keyHasSeenWelcome) ?? false;
  }

  // Semester preference methods (quick access)
  static Future<bool> setSemesterPreference(int? semester) async {
    final currentPrefs = getPreferences();
    final updatedPrefs = currentPrefs.copyWith(semesterPreference: semester);
    return await savePreferences(updatedPrefs);
  }

  static int? getSemesterPreference() {
    return getPreferences().semesterPreference;
  }

  // Update last active timestamp
  static Future<bool> updateLastActive() async {
    final currentPrefs = getPreferences();
    final updatedPrefs = currentPrefs.copyWith(lastActive: DateTime.now());
    return await savePreferences(updatedPrefs);
  }

  // Clear all data (logout)
  static Future<bool> clearAll() async {
    try {
      final results = await Future.wait([
        removeUser(),
        removeAuthToken(),
        // Keep preferences but reset hasSeenWelcome to false
        _prefs.setBool(_keyHasSeenWelcome, false),
      ]);
      
      // Return true if all operations succeeded
      return results.every((result) => result);
    } catch (e) {
      return false;
    }
  }

  // Check if user is logged in
  static bool get isLoggedIn {
    final user = getUser();
    return user != null && user.isAuthenticated;
  }

  // Check if user is in guest mode
  static bool get isGuestMode {
    final user = getUser();
    return user != null && !user.isAuthenticated;
  }

  // Debug method to print all stored data
  static void debugPrintAll() {
    print('=== StorageService Debug ===');
    print('User: ${getUser()}');
    print('Preferences: ${getPreferences()}');
    print('Auth Token: ${getAuthToken() != null ? "[PRESENT]" : "[NULL]"}');
    print('Has Seen Welcome: ${hasSeenWelcome()}');
    print('===========================');
  }
}