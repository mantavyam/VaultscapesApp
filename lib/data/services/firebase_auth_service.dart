import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../core/error/exceptions.dart';
import 'github_oauth_service.dart';

/// Service for Firebase Authentication
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final GitHubOAuthService _githubOAuth;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    GitHubOAuthService? githubOAuth,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _githubOAuth = githubOAuth ?? GitHubOAuthService();

  /// Get current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AuthException('Failed to get user after sign in');
      }

      return _mapFirebaseUserToModel(firebaseUser);
    } on FirebaseAuthException catch (e) {
      throw AuthException('Firebase auth error: ${e.message}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Sign in failed: $e');
    }
  }

  /// Sign in with GitHub using manual OAuth2 flow
  /// This avoids the "missing initial state" error by using native OAuth
  /// instead of web-based redirect that relies on browser sessionStorage
  Future<UserModel> signInWithGithub() async {
    try {
      // Step 1: Get GitHub access token via manual OAuth2 flow
      final accessToken = await _githubOAuth.authorizeAndGetToken();

      // Step 2: Create Firebase credential with the access token
      final credential = GithubAuthProvider.credential(accessToken);

      // Step 3: Sign in to Firebase with the credential
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AuthException('Failed to get user after GitHub sign in');
      }

      return _mapFirebaseUserToModel(firebaseUser);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during GitHub sign in: ${e.code} - ${e.message}');
      
      // Handle account-exists-with-different-credential error
      if (e.code == 'account-exists-with-different-credential') {
        final email = e.email;
        if (email != null) {
          // Get the sign-in methods for this email
          final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
          debugPrint('Existing sign-in methods for $email: $methods');
          
          if (methods.contains('google.com')) {
            throw AuthException(
              'This email is already registered with Google. '
              'Please sign in with Google instead, or use a different GitHub account.'
            );
          } else if (methods.isNotEmpty) {
            throw AuthException(
              'This email is already registered with ${methods.first}. '
              'Please use that sign-in method instead.'
            );
          }
        }
        throw AuthException(
          'This email is already registered with a different sign-in method. '
          'Please use your original sign-in method.'
        );
      }
      
      throw AuthException('Firebase auth error: ${e.message}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('GitHub sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  /// Get current user as UserModel
  UserModel? getCurrentUserModel() {
    final user = currentUser;
    if (user == null) return null;
    return _mapFirebaseUserToModel(user);
  }

  /// Update display name
  Future<UserModel> updateDisplayName(String name) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('No user signed in');
    }

    try {
      await user.updateDisplayName(name);
      await user.reload();
      return _mapFirebaseUserToModel(_firebaseAuth.currentUser!);
    } catch (e) {
      throw AuthException('Failed to update display name: $e');
    }
  }

  /// Map Firebase User to UserModel
  UserModel _mapFirebaseUserToModel(User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      isGuest: false,
      provider: _getProvider(user),
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  /// Get the authentication provider
  String _getProvider(User user) {
    if (user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      if (providerId.contains('google')) return 'google';
      if (providerId.contains('github')) return 'github';
      if (providerId.contains('apple')) return 'apple';
      return providerId;
    }
    return 'unknown';
  }
}
