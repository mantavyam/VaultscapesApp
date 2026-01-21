import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';

/// Repository for handling authentication
class AuthRepository {
  static const String _userKey = 'current_user';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _homepagePreferenceKey = 'homepage_preference';

  SharedPreferences? _prefs;
  final FirebaseAuthService _firebaseAuthService;

  AuthRepository({FirebaseAuthService? firebaseAuthService})
      : _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService();

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Sign in with Google using Firebase
  Future<UserModel> signInWithGoogle() async {
    final user = await _firebaseAuthService.signInWithGoogle();
    
    // Load any saved preferences and merge with user
    final prefs = await this.prefs;
    final homepagePreference = prefs.getString(_homepagePreferenceKey);
    final userWithPrefs = user.copyWith(homepagePreference: homepagePreference);
    
    await _saveUser(userWithPrefs);
    return userWithPrefs;
  }

  /// Perform mock authentication (fallback for testing)
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
      final userWithPrefs = updatedUser.copyWith(homepagePreference: homepagePreference);
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

  /// Logout
  Future<void> logout() async {
    // Sign out from Firebase
    try {
      await _firebaseAuthService.signOut();
    } catch (e) {
      // Continue even if Firebase sign out fails
    }
    
    // Clear local data
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
