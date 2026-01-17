import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Authentication state
enum AuthState {
  initial,
  loading,
  authenticated,
  guest,
  unauthenticated,
  error,
}

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  // Getters
  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isGuest => _state == AuthState.guest;
  bool get isLoading => _state == AuthState.loading;

  /// Initialize auth state on app start
  Future<void> initialize() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _user = user;
        _state = user.isGuest ? AuthState.guest : AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Perform mock authentication (Phase 1)
  Future<bool> mockAuthenticate({String? name, String? email}) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.mockAuthenticate(name: name, email: email);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Authentication failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Continue as guest
  Future<void> continueAsGuest() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.continueAsGuest();
      _state = AuthState.guest;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Failed to continue as guest.';
    }

    notifyListeners();
  }

  /// Update display name
  Future<bool> updateDisplayName(String name) async {
    if (_user == null) return false;

    try {
      _user = await _authRepository.updateDisplayName(name);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update name.';
      notifyListeners();
      return false;
    }
  }

  /// Update homepage preference
  Future<bool> updateHomepagePreference(String? preference) async {
    if (_user == null) return false;

    try {
      _user = await _authRepository.updateHomepagePreference(preference);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update homepage preference.';
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _authRepository.logout();
      _user = null;
      _state = AuthState.unauthenticated;
    } catch (e) {
      _errorMessage = 'Failed to logout.';
    }

    notifyListeners();
  }

  /// Sign out (alias for logout)
  Future<void> signOut() async {
    await logout();
  }

  /// Sign in with Google (placeholder)
  Future<bool> signInWithGoogle() async {
    // For Phase 1, just use mock authentication
    return await mockAuthenticate();
  }

  /// Convert guest to authenticated user
  Future<bool> convertGuestToAuthenticated({String? name, String? email}) async {
    if (_state != AuthState.guest) return false;
    return await mockAuthenticate(name: name, email: email);
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
