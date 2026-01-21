import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../../core/error/exceptions.dart';

/// Service for Firebase Authentication
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

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
      if (providerId.contains('apple')) return 'apple';
      return providerId;
    }
    return 'unknown';
  }
}
