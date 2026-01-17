import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';

/// Repository for handling authentication
class AuthRepository {
  static const String _userKey = 'current_user';
  static const String _isAuthenticatedKey = 'is_authenticated';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Perform mock authentication (Phase 1)
  Future<UserModel> mockAuthenticate({String? name, String? email}) async {
    // Simulate network delay
    await Future.delayed(AppConstants.mockAuthDelay);

    final user = UserModel.mockAuth(name: name, email: email);
    await _saveUser(user);
    return user;
  }

  /// Continue as guest
  Future<UserModel> continueAsGuest() async {
    final user = UserModel.guest();
    await _saveUser(user);
    return user;
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await this.prefs;
      final userJson = prefs.getString(_userKey);
      if (userJson == null) return null;
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (e) {
      throw CacheException('Failed to get current user: $e');
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final prefs = await this.prefs;
    return prefs.getBool(_isAuthenticatedKey) ?? false;
  }

  /// Update user profile
  Future<UserModel> updateUser(UserModel user) async {
    await _saveUser(user);
    return user;
  }

  /// Update display name
  Future<UserModel> updateDisplayName(String name) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw AuthException('No user logged in');
    }
    final updatedUser = currentUser.copyWith(displayName: name);
    await _saveUser(updatedUser);
    return updatedUser;
  }

  /// Update homepage preference
  Future<UserModel> updateHomepagePreference(String? preference) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw AuthException('No user logged in');
    }
    final updatedUser = currentUser.copyWith(homepagePreference: preference);
    await _saveUser(updatedUser);
    return updatedUser;
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await this.prefs;
    await prefs.remove(_userKey);
    await prefs.setBool(_isAuthenticatedKey, false);
  }

  /// Save user to local storage
  Future<void> _saveUser(UserModel user) async {
    final prefs = await this.prefs;
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isAuthenticatedKey, !user.isGuest);
  }
}
