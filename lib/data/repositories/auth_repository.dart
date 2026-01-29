import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';

/// Repository for handling authentication
///
/// Auth State Priority:
/// 1. Firebase authenticated user → authenticated
/// 2. Explicit guest mode (user clicked "Continue as Guest") → guest
/// 3. Default → unauthenticated (show welcome/login screen)
///
/// The key insight is: we only restore guest mode if user EXPLICITLY chose it.
/// After logout, even if there was a previous guest session, we don't restore it.
class AuthRepository {
  static const String _userKey = 'current_user';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _homepagePreferenceKey = 'homepage_preference';
  // This flag tracks if user explicitly chose guest mode (vs just being unauthenticated)
  static const String _isExplicitGuestKey = 'is_explicit_guest';

  SharedPreferences? _prefs;
  final FirebaseAuthService _firebaseAuthService;

  AuthRepository({FirebaseAuthService? firebaseAuthService})
    : _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService();

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Stream of Firebase auth state changes - use this for reliable auth restoration
  Stream<User?> get authStateChanges => _firebaseAuthService.authStateChanges;

  /// Check if user explicitly chose guest mode
  /// This is different from just being unauthenticated - guest mode is an explicit choice
  Future<bool> isExplicitGuestMode() async {
    final prefs = await this.prefs;
    final isExplicitGuest = prefs.getBool(_isExplicitGuestKey) ?? false;
    debugPrint('AuthRepository: isExplicitGuestMode = $isExplicitGuest');
    return isExplicitGuest;
  }

  /// Get user model from current Firebase user (without cache check)
  Future<UserModel?> getUserFromFirebase() async {
    final firebaseUser = _firebaseAuthService.getCurrentUserModel();
    if (firebaseUser == null) return null;

    // Load preferences and merge
    final prefs = await this.prefs;
    final homepagePreference = prefs.getString(_homepagePreferenceKey);
    return firebaseUser.copyWith(homepagePreference: homepagePreference);
  }

  /// Get guest user from local cache (if exists)
  Future<UserModel?> getGuestUser() async {
    try {
      final prefs = await this.prefs;
      final userJson = prefs.getString(_userKey);
      if (userJson == null) return null;

      final user = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      // Only return if it's a guest user
      return user.isGuest ? user : null;
    } catch (e) {
      return null;
    }
  }

  /// Sign in with Google using Firebase
  Future<UserModel> signInWithGoogle() async {
    final user = await _firebaseAuthService.signInWithGoogle();

    // Clear guest mode flag since user is signing in properly
    final prefs = await this.prefs;
    await prefs.remove(_isExplicitGuestKey);

    final homepagePreference = prefs.getString(_homepagePreferenceKey);
    final userWithPrefs = user.copyWith(homepagePreference: homepagePreference);

    await _saveUser(userWithPrefs);
    return userWithPrefs;
  }

  /// Sign in with GitHub using Firebase
  Future<UserModel> signInWithGithub() async {
    final user = await _firebaseAuthService.signInWithGithub();

    // Clear guest mode flag since user is signing in properly
    final prefs = await this.prefs;
    await prefs.remove(_isExplicitGuestKey);

    final homepagePreference = prefs.getString(_homepagePreferenceKey);
    final userWithPrefs = user.copyWith(homepagePreference: homepagePreference);

    await _saveUser(userWithPrefs);
    return userWithPrefs;
  }

  /// Perform mock authentication (fallback for testing)
  Future<UserModel> mockAuthenticate({String? name, String? email}) async {
    // Simulate network delay
    await Future.delayed(AppConstants.mockAuthDelay);

    // Clear guest mode flag since user is signing in
    final prefs = await this.prefs;
    await prefs.remove(_isExplicitGuestKey);

    final user = UserModel.mockAuth(name: name, email: email);
    await _saveUser(user);
    return user;
  }

  /// Continue as guest - EXPLICIT user choice
  /// This sets a flag so we can restore guest mode on app restart
  Future<UserModel> continueAsGuest() async {
    debugPrint('AuthRepository: User explicitly choosing guest mode');

    // Set explicit guest flag - this is the ONLY way guest mode gets enabled
    final prefs = await this.prefs;
    await prefs.setBool(_isExplicitGuestKey, true);

    final user = UserModel.guest();
    await _saveUser(user);
    return user;
  }

  /// Get current user (checks Firebase first, then local cache)
  Future<UserModel?> getCurrentUser() async {
    try {
      // First check Firebase auth state
      final firebaseUser = _firebaseAuthService.getCurrentUserModel();
      if (firebaseUser != null) {
        // Load preferences and merge
        final prefs = await this.prefs;
        final homepagePreference = prefs.getString(_homepagePreferenceKey);
        return firebaseUser.copyWith(homepagePreference: homepagePreference);
      }

      // Fall back to local cache (for guest users)
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
    // Check Firebase first
    if (_firebaseAuthService.currentUser != null) {
      return true;
    }

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
    // Check if Firebase user exists
    if (_firebaseAuthService.currentUser != null) {
      final updatedUser = await _firebaseAuthService.updateDisplayName(name);
      final prefs = await this.prefs;
      final homepagePreference = prefs.getString(_homepagePreferenceKey);
      final userWithPrefs = updatedUser.copyWith(
        homepagePreference: homepagePreference,
      );
      await _saveUser(userWithPrefs);
      return userWithPrefs;
    }

    // Fallback to local cache
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

    // Save preference separately so it persists across sessions
    final prefs = await this.prefs;
    if (preference != null) {
      await prefs.setString(_homepagePreferenceKey, preference);
    } else {
      await prefs.remove(_homepagePreferenceKey);
    }

    final updatedUser = currentUser.copyWith(homepagePreference: preference);
    await _saveUser(updatedUser);
    return updatedUser;
  }

  /// Logout - clears all auth state including guest mode
  /// After logout, user should be fully unauthenticated (not restored as guest)
  Future<void> logout() async {
    debugPrint('AuthRepository: Logging out - clearing all auth state');

    // Sign out from Firebase
    try {
      await _firebaseAuthService.signOut();
    } catch (e) {
      debugPrint('AuthRepository: Firebase sign out error: $e');
      // Continue even if Firebase sign out fails
    }

    // Clear ALL local data including guest mode flag
    final prefs = await this.prefs;
    await prefs.remove(_userKey);
    await prefs.setBool(_isAuthenticatedKey, false);
    // CRITICAL: Remove explicit guest flag - this ensures user won't be restored as guest
    await prefs.remove(_isExplicitGuestKey);
    debugPrint('AuthRepository: Cleared _isExplicitGuestKey flag');
    // Note: We intentionally keep homepage preference as it's a user preference
  }

  /// Save user to local storage
  Future<void> _saveUser(UserModel user) async {
    final prefs = await this.prefs;
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isAuthenticatedKey, !user.isGuest);
  }
}
