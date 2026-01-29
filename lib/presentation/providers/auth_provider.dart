import 'dart:async';
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
/// Uses Firebase auth state stream for reliable restoration on cold starts
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription? _authStateSubscription;

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository() {
    // Listen to Firebase auth state changes for reliable restoration
    _listenToAuthStateChanges();
  }

  // Getters
  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isGuest => _state == AuthState.guest;
  bool get isLoading => _state == AuthState.loading || !_isInitialized;
  bool get isInitialized => _isInitialized;

  /// Listen to Firebase auth state changes stream
  /// This is more reliable than one-time checks as it automatically
  /// handles token refresh and restoration on cold starts
  ///
  /// Auth restoration priority:
  /// 1. Firebase user exists → authenticated
  /// 2. Explicit guest mode flag set → guest (user clicked "Continue as Guest")
  /// 3. Default → unauthenticated (show welcome screen)
  void _listenToAuthStateChanges() {
    _state = AuthState.loading;

    _authStateSubscription = _authRepository.authStateChanges.listen(
      (firebaseUser) async {
        debugPrint(
          'AuthProvider: Firebase auth state changed, user: ${firebaseUser?.uid}',
        );

        if (firebaseUser != null) {
          // User is signed in with Firebase - get full user model with preferences
          debugPrint(
            'AuthProvider: Firebase user found, setting authenticated',
          );
          try {
            final user = await _authRepository.getCurrentUser();
            if (user != null) {
              _user = user;
              _state = user.isGuest ? AuthState.guest : AuthState.authenticated;
            } else {
              // Fallback: create user from Firebase user
              _user = await _authRepository.getUserFromFirebase();
              _state = AuthState.authenticated;
            }
          } catch (e) {
            debugPrint('AuthProvider: Error getting user: $e');
            _user = await _authRepository.getUserFromFirebase();
            _state = AuthState.authenticated;
          }
        } else {
          // No Firebase user - check if user EXPLICITLY chose guest mode
          // This is the key difference: we only restore guest if it was an explicit choice
          debugPrint(
            'AuthProvider: No Firebase user, checking for explicit guest mode',
          );
          final isExplicitGuest = await _authRepository.isExplicitGuestMode();

          if (isExplicitGuest) {
            // User explicitly chose guest mode - restore it
            debugPrint(
              'AuthProvider: Explicit guest mode found, restoring guest',
            );
            try {
              final guestUser = await _authRepository.getGuestUser();
              if (guestUser != null) {
                _user = guestUser;
                _state = AuthState.guest;
              } else {
                // Guest flag set but no guest user in cache - create new guest
                debugPrint(
                  'AuthProvider: No cached guest user, but flag is set - staying unauthenticated',
                );
                _user = null;
                _state = AuthState.unauthenticated;
              }
            } catch (e) {
              debugPrint('AuthProvider: Error getting guest user: $e');
              _user = null;
              _state = AuthState.unauthenticated;
            }
          } else {
            // No explicit guest mode - user is unauthenticated
            // This is the DEFAULT state - show welcome/login screen
            debugPrint(
              'AuthProvider: No explicit guest mode, setting unauthenticated',
            );
            _user = null;
            _state = AuthState.unauthenticated;
          }
        }

        _isInitialized = true;
        debugPrint('AuthProvider: Initialization complete, state: $_state');
        notifyListeners();
      },
      onError: (error) {
        debugPrint('AuthProvider: Auth state error: $error');
        _state = AuthState.unauthenticated;
        _isInitialized = true;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  /// Initialize auth state (called automatically via stream, but can be called manually)
  Future<void> initialize() async {
    if (_isInitialized) return;
    // Stream already handles initialization
  }

  /// Sign in with Google using Firebase
  Future<bool> signInWithGoogle() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.signInWithGoogle();
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Sign in failed. Please try again.';
      debugPrint('Sign in error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Sign in with GitHub using Firebase
  Future<bool> signInWithGithub() async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.signInWithGithub();
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'GitHub sign in failed. Please try again.';
      debugPrint('GitHub sign in error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Perform mock authentication (fallback for testing)
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

  /// Logout - fully signs out user and clears all cached state
  /// After logout, user will be unauthenticated (not guest)
  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _authRepository.logout();
      _user = null;
      _state = AuthState.unauthenticated; // NOT guest - fully logged out
    } catch (e) {
      _errorMessage = 'Failed to logout.';
    }

    notifyListeners();
  }

  /// Sign out (alias for logout)
  Future<void> signOut() async {
    await logout();
  }

  /// Convert guest to authenticated user
  Future<bool> convertGuestToAuthenticated() async {
    if (_state != AuthState.guest) return false;
    return await signInWithGoogle();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
