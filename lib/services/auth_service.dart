import 'dart:async';
import '../models/user_model.dart';
import 'storage_service.dart';

// Firebase imports for Phase 2
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthProvider { google, github }

class AuthService {
  static const bool _isMockPhase = false; // Changed to false for Phase 2

  // Mock authentication delay (still used for fallback)
  static const Duration _mockDelay = Duration(seconds: 2);

  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google
  static Future<UserModel?> signInWithGoogle() async {
    if (_isMockPhase) {
      return _mockGoogleSignIn();
    } else {
      // Phase 2: Implement real Google Sign-In
      return _realGoogleSignIn();
    }
  }

  // Sign in with GitHub
  static Future<UserModel?> signInWithGitHub() async {
    if (_isMockPhase) {
      return _mockGitHubSignIn();
    } else {
      // Phase 2: Implement real GitHub Sign-In
      return _realGitHubSignIn();
    }
  }

  // Sign out
  static Future<bool> signOut() async {
    if (_isMockPhase) {
      return _mockSignOut();
    } else {
      // Phase 2: Implement real sign out
      return _realSignOut();
    }
  }

  // Check if user is signed in
  static Future<bool> isSignedIn() async {
    if (_isMockPhase) {
      final user = StorageService.getUser();
      return user != null;
    } else {
      // Phase 2: Check Firebase Auth state
      return _auth.currentUser != null;
    }
  }

  // Get current user
  static Future<UserModel?> getCurrentUser() async {
    if (_isMockPhase) {
      return StorageService.getUser();
    } else {
      // Phase 2: Get user from Firebase
      return _getCurrentFirebaseUser();
    }
  }

  // Update user name
  static Future<bool> updateUserName(String newName) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return false;

    final updatedUser = currentUser.copyWith(customName: newName);
    final saved = await StorageService.saveUser(updatedUser);

    if (!_isMockPhase && saved) {
      // Phase 2: Update Firebase user profile and Firestore
      await _updateFirebaseUserProfile(updatedUser);
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

  // REAL IMPLEMENTATIONS (Phase 2)
  
  static Future<UserModel?> _realGoogleSignIn() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);
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
        photoURL: firebaseUser.photoURL ?? '',
      );

      // Save to local storage
      await StorageService.saveUser(user);
      
      // Save auth token
      final token = await firebaseUser.getIdToken();
      if (token != null) {
        await StorageService.saveAuthToken(token);
      }

      // Create/update Firestore user document
      await _createOrUpdateFirestoreUser(user);

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
      final userCredential = await _auth.signInWithProvider(githubProvider);
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
        photoURL: firebaseUser.photoURL ?? '',
      );

      // Save to local storage
      await StorageService.saveUser(user);
      
      // Save auth token
      final token = await firebaseUser.getIdToken();
      if (token != null) {
        await StorageService.saveAuthToken(token);
      }

      // Create/update Firestore user document
      await _createOrUpdateFirestoreUser(user);

      return user;
    } catch (e) {
      print('GitHub Sign-In error: $e');
      return null;
    }
  }

  static Future<bool> _realSignOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      return await StorageService.clearAll();
    } catch (e) {
      print('Sign out error: $e');
      return false;
    }
  }

  static Future<UserModel?> _getCurrentFirebaseUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // Try to get from local storage first
    var user = StorageService.getUser();
    
    // If not in local storage or outdated, create from Firebase user
    if (user == null || user.userId != firebaseUser.uid) {
      // Try to get from Firestore
      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          user = UserModel(
            userId: firebaseUser.uid,
            email: data['email'] ?? firebaseUser.email ?? '',
            providerName: data['providerName'] ?? firebaseUser.displayName ?? 'User',
            customName: data['customName'],
            authProvider: data['authProvider'] ?? 'google',
            isAuthenticated: true,
            photoURL: data['photoURL'] ?? firebaseUser.photoURL,
          );
        } else {
          // Create from Firebase user if Firestore doc doesn't exist
          user = UserModel(
            userId: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            providerName: firebaseUser.displayName ?? 'User',
            customName: null,
            authProvider: 'google', // Default
            isAuthenticated: true,
            photoURL: firebaseUser.photoURL ?? '',
          );
        }
        
        // Save to local storage
        await StorageService.saveUser(user);
      } catch (e) {
        print('Error getting user from Firestore: $e');
        return null;
      }
    }

    return user;
  }

  static Future<void> _updateFirebaseUserProfile(UserModel user) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null && user.customName != null) {
        await firebaseUser.updateDisplayName(user.customName);
      }

      // Update Firestore document
      await _createOrUpdateFirestoreUser(user);
    } catch (e) {
      print('Error updating Firebase user profile: $e');
    }
  }

  static Future<void> _createOrUpdateFirestoreUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.userId).set({
        'email': user.email,
        'providerName': user.providerName,
        'customName': user.customName,
        'authProvider': user.authProvider,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating Firestore user: $e');
    }
  }
}