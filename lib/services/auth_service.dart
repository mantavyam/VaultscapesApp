import 'dart:async';
import '../models/user_model.dart';
import 'storage_service.dart';

// For Phase 2 - uncomment these imports
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

enum AuthProvider { google, github }

class AuthService {
  static const bool _isMockPhase = true; // Change to false in Phase 2

  // Mock authentication delay
  static const Duration _mockDelay = Duration(seconds: 2);

  // Sign in with Google
  static Future<UserModel?> signInWithGoogle() async {
    if (_isMockPhase) {
      return _mockGoogleSignIn();
    } else {
      // Phase 2: Implement real Google Sign-In
      // return _realGoogleSignIn();
      throw UnimplementedError('Real Google Sign-In not implemented yet');
    }
  }

  // Sign in with GitHub
  static Future<UserModel?> signInWithGitHub() async {
    if (_isMockPhase) {
      return _mockGitHubSignIn();
    } else {
      // Phase 2: Implement real GitHub Sign-In
      // return _realGitHubSignIn();
      throw UnimplementedError('Real GitHub Sign-In not implemented yet');
    }
  }

  // Sign out
  static Future<bool> signOut() async {
    if (_isMockPhase) {
      return _mockSignOut();
    } else {
      // Phase 2: Implement real sign out
      // return _realSignOut();
      throw UnimplementedError('Real sign out not implemented yet');
    }
  }

  // Check if user is signed in
  static Future<bool> isSignedIn() async {
    if (_isMockPhase) {
      final user = StorageService.getUser();
      return user != null;
    } else {
      // Phase 2: Check Firebase Auth state
      // return FirebaseAuth.instance.currentUser != null;
      return false;
    }
  }

  // Get current user
  static Future<UserModel?> getCurrentUser() async {
    if (_isMockPhase) {
      return StorageService.getUser();
    } else {
      // Phase 2: Get user from Firebase
      // return _getCurrentFirebaseUser();
      return null;
    }
  }

  // Update user name
  static Future<bool> updateUserName(String newName) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return false;

    final updatedUser = currentUser.copyWith(customName: newName);
    final saved = await StorageService.saveUser(updatedUser);

    if (!_isMockPhase && saved) {
      // Phase 2: Update Firebase user profile
      // await _updateFirebaseUserProfile(updatedUser);
    }

    return saved;
  }

  // MOCK IMPLEMENTATIONS (Phase 1)
  
  static Future<UserModel?> _mockGoogleSignIn() async {
    // Simulate network delay
    await Future.delayed(_mockDelay);
    
    // Create mock Google user
    final mockUser = UserModel.mock(
      provider: 'google',
      mockName: 'John Doe',
      mockEmail: 'john.doe@example.com',
    );

    // Save to storage
    final saved = await StorageService.saveUser(mockUser);
    return saved ? mockUser : null;
  }

  static Future<UserModel?> _mockGitHubSignIn() async {
    // Simulate network delay
    await Future.delayed(_mockDelay);
    
    // Create mock GitHub user
    final mockUser = UserModel.mock(
      provider: 'github',
      mockName: 'Jane Smith',
      mockEmail: 'jane.smith@example.com',
    );

    // Save to storage
    final saved = await StorageService.saveUser(mockUser);
    return saved ? mockUser : null;
  }

  static Future<bool> _mockSignOut() async {
    return await StorageService.clearAll();
  }

  // REAL IMPLEMENTATIONS (Phase 2) - To be implemented later
  
  /*
  static Future<UserModel?> _realGoogleSignIn() async {
    try {
      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) return null;

      // Create UserModel from Firebase user
      final user = UserModel(
        userId: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        providerName: firebaseUser.displayName ?? 'Google User',
        customName: null,
        authProvider: 'google',
        isAuthenticated: true,
        photoURL: firebaseUser.photoURL,
      );

      // Save to local storage
      await StorageService.saveUser(user);
      
      // Save auth token
      final token = await firebaseUser.getIdToken();
      await StorageService.saveAuthToken(token);

      return user;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  static Future<UserModel?> _realGitHubSignIn() async {
    try {
      // Create a GitHub provider
      final githubProvider = GithubAuthProvider();
      
      // Sign in with popup (web) or redirect (mobile)
      final userCredential = await FirebaseAuth.instance.signInWithProvider(githubProvider);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) return null;

      // Create UserModel from Firebase user
      final user = UserModel(
        userId: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        providerName: firebaseUser.displayName ?? 'GitHub User',
        customName: null,
        authProvider: 'github',
        isAuthenticated: true,
        photoURL: firebaseUser.photoURL,
      );

      // Save to local storage
      await StorageService.saveUser(user);
      
      // Save auth token
      final token = await firebaseUser.getIdToken();
      await StorageService.saveAuthToken(token);

      return user;
    } catch (e) {
      print('GitHub Sign-In error: $e');
      return null;
    }
  }

  static Future<bool> _realSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      return await StorageService.clearAll();
    } catch (e) {
      print('Sign out error: $e');
      return false;
    }
  }

  static Future<UserModel?> _getCurrentFirebaseUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    // Try to get from local storage first
    var user = StorageService.getUser();
    
    // If not in local storage or outdated, create from Firebase user
    if (user == null || user.userId != firebaseUser.uid) {
      user = UserModel(
        userId: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        providerName: firebaseUser.displayName ?? 'User',
        customName: null, // This would come from Firestore
        authProvider: 'google', // This would come from Firestore
        isAuthenticated: true,
        photoURL: firebaseUser.photoURL,
      );
      
      // Save to local storage
      await StorageService.saveUser(user);
    }

    return user;
  }

  static Future<void> _updateFirebaseUserProfile(UserModel user) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && user.customName != null) {
      await firebaseUser.updateDisplayName(user.customName);
    }
  }
  */
}