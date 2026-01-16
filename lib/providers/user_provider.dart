import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _currentUser!.isAuthenticated;
  bool get isGuest => _currentUser != null && !_currentUser!.isAuthenticated;
  bool get hasUser => _currentUser != null;

  // Initialize user state from storage and set up Firebase auth listener
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      _currentUser = StorageService.getUser();
      
      // Phase 2: Set up Firebase auth state listener
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _handleAuthStateChange(user);
      });
      
      _clearError();
    } catch (e) {
      _setError('Failed to load user data');
    }
    
    _setLoading(false);
  }
  
  // Handle Firebase auth state changes
  Future<void> _handleAuthStateChange(User? firebaseUser) async {
    if (firebaseUser == null) {
      // User signed out
      if (_currentUser != null && _currentUser!.isAuthenticated) {
        _currentUser = null;
        notifyListeners();
      }
    } else {
      // User signed in or session restored
      final authServiceUser = await AuthService.getCurrentUser();
      if (authServiceUser != null) {
        _currentUser = authServiceUser;
        
        // Load preferences from Firestore and merge with local
        await StorageService.loadPreferencesFromFirestore();
        
        notifyListeners();
      }
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await _performAuth(() => AuthService.signInWithGoogle());
  }

  // Sign in with GitHub
  Future<bool> signInWithGitHub() async {
    return await _performAuth(() => AuthService.signInWithGitHub());
  }

  // Create guest user (explore mode)
  Future<bool> continueAsGuest() async {
    _setLoading(true);
    
    try {
      // Create a guest user (mock user with isAuthenticated = false)
      final guestUser = UserModel.mock(
        provider: 'guest',
        mockName: 'Guest',
        mockEmail: 'guest@example.com',
      );

      final saved = await StorageService.saveUser(guestUser);
      if (saved) {
        _currentUser = guestUser;
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError('Failed to create guest session');
        return false;
      }
    } catch (e) {
      _setError('Failed to create guest session');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user name
  Future<bool> updateUserName(String newName) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    
    try {
      final success = await AuthService.updateUserName(newName);
      if (success) {
        _currentUser = _currentUser!.copyWith(customName: newName);
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError('Failed to update name');
        return false;
      }
    } catch (e) {
      _setError('Failed to update name');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<bool> signOut() async {
    _setLoading(true);
    
    try {
      final success = await AuthService.signOut();
      if (success) {
        _currentUser = null;
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError('Failed to sign out');
        return false;
      }
    } catch (e) {
      _setError('Failed to sign out');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Convert guest to authenticated user
  Future<bool> convertGuestToAuthenticated(UserModel authenticatedUser) async {
    _setLoading(true);
    
    try {
      final saved = await StorageService.saveUser(authenticatedUser);
      if (saved) {
        _currentUser = authenticatedUser;
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError('Failed to convert guest account');
        return false;
      }
    } catch (e) {
      _setError('Failed to convert guest account');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    _setLoading(true);
    
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _clearError();
      }
    } catch (e) {
      _setError('Failed to refresh user data');
    }
    
    _setLoading(false);
  }

  // Clear error message
  void clearError() {
    _clearError();
  }

  // Private helper methods
  Future<bool> _performAuth(Future<UserModel?> Function() authFunction) async {
    _setLoading(true);
    
    try {
      final user = await authFunction();
      if (user != null) {
        _currentUser = user;
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError('Authentication failed');
        return false;
      }
    } catch (e) {
      _setError('Authentication failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}