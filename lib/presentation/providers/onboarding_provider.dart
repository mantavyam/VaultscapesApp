import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing onboarding state
class OnboardingProvider extends ChangeNotifier {
  static const String _onboardingCompletedKey = 'onboarding_completed';

  bool _hasCompletedOnboarding = false;
  bool _isLoading = true;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isLoading => _isLoading;

  OnboardingProvider() {
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = prefs.getBool(_onboardingCompletedKey) ?? false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_hasCompletedOnboarding) return;

    _hasCompletedOnboarding = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Reset onboarding state (for testing/debugging)
  Future<void> resetOnboarding() async {
    _hasCompletedOnboarding = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
  }
}
