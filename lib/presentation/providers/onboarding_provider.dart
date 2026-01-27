import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/firestore_service.dart';

/// Provider for managing onboarding state
class OnboardingProvider extends ChangeNotifier {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _profileSetupCompletedKey = 'profile_setup_completed';
  static const String _userGenderKey = 'user_gender';

  bool _hasCompletedOnboarding = false;
  bool _hasCompletedProfileSetup = false;
  bool _isLoading = true;
  bool _isReturningUser = false;
  String? _userGender;

  final FirestoreService _firestoreService;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasCompletedProfileSetup => _hasCompletedProfileSetup;
  bool get isLoading => _isLoading;
  bool get isReturningUser => _isReturningUser;
  String? get userGender => _userGender;

  OnboardingProvider({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService() {
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = prefs.getBool(_onboardingCompletedKey) ?? false;
    _hasCompletedProfileSetup =
        prefs.getBool(_profileSetupCompletedKey) ?? false;
    _userGender = prefs.getString(_userGenderKey);

    // If user has completed both onboarding and profile setup, they're returning
    _isReturningUser = _hasCompletedOnboarding && _hasCompletedProfileSetup;

    _isLoading = false;
    notifyListeners();
  }

  /// Check Firebase for profile setup status for a specific user
  /// Call this when a user signs in to check if they've already completed setup
  Future<void> checkFirebaseProfileStatus(String uid) async {
    try {
      final hasSetProfile = await _firestoreService
          .hasUserCompletedProfileSetup(uid);

      if (hasSetProfile) {
        // User has already completed profile setup in Firebase
        // Update local state to match
        _hasCompletedProfileSetup = true;
        _isReturningUser = true;

        // Also get the gender from Firebase if available
        final preferences = await _firestoreService.getUserPreferences(uid);
        if (preferences != null) {
          _userGender = preferences['gender'] as String?;
        }

        // Persist to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_profileSetupCompletedKey, true);
        if (_userGender != null) {
          await prefs.setString(_userGenderKey, _userGender!);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking Firebase profile status: $e');
    }
  }

  Future<void> completeOnboarding() async {
    if (_hasCompletedOnboarding) return;

    _hasCompletedOnboarding = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Complete profile setup with gender selection
  Future<void> completeProfileSetup({required String gender}) async {
    _hasCompletedProfileSetup = true;
    _userGender = gender;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileSetupCompletedKey, true);
    await prefs.setString(_userGenderKey, gender);
  }

  /// Mark user as returning (skips profile setup on future logins)
  void markAsReturningUser() {
    _isReturningUser = true;
    notifyListeners();
  }

  /// Reset onboarding state (for testing/debugging)
  Future<void> resetOnboarding() async {
    _hasCompletedOnboarding = false;
    _hasCompletedProfileSetup = false;
    _userGender = null;
    _isReturningUser = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_profileSetupCompletedKey);
    await prefs.remove(_userGenderKey);
  }
}
