import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for Firestore database operations
/// User document schema:
/// {
///   defaultName: string (original name from provider),
///   email: string,
///   photoUrl: string,
///   provider: string,
///   uid: string,
///   createdAt: timestamp,
///   lastActive: timestamp,
///   preferences: {
///     displayName: string (user's chosen display name),
///     gender: string,
///     hasSetProfile: boolean
///   }
/// }
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Create or update user document in Firestore with new schema
  /// Called when a new user signs in or updates their profile
  Future<void> createOrUpdateUser({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
    String? gender,
    String? provider,
    bool merge = true,
  }) async {
    // Check if user already exists to preserve existing data
    final existingDoc = await _usersCollection.doc(uid).get();
    final existingData = existingDoc.data();

    // Determine if this completes profile setup
    // hasSetProfile is true if user has set both displayName and gender
    final hasSetProfile = gender != null && displayName.isNotEmpty;

    final userData = <String, dynamic>{
      'uid': uid,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'lastActive': FieldValue.serverTimestamp(),
      'preferences': {
        'displayName': displayName,
        'gender': gender,
        'hasSetProfile': hasSetProfile,
      },
    };

    // Only set defaultName if this is first time or it doesn't exist
    if (existingData == null || existingData['defaultName'] == null) {
      userData['defaultName'] = displayName;
    }

    // Add createdAt only on first creation
    if (!merge || existingData == null) {
      userData['createdAt'] = FieldValue.serverTimestamp();
    }

    await _usersCollection.doc(uid).set(userData, SetOptions(merge: merge));
  }

  /// Create new user document (for first-time sign in, before profile setup)
  /// This creates a minimal document that will be updated during profile setup
  Future<void> createNewUser({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
    String? provider,
  }) async {
    // Check if user already exists
    final doc = await _usersCollection.doc(uid).get();

    if (!doc.exists) {
      // New user - create document with default schema
      await _usersCollection.doc(uid).set({
        'uid': uid,
        'defaultName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'provider': provider,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'preferences': {
          'displayName': displayName,
          'gender': null,
          'hasSetProfile': false,
        },
      });
    } else {
      // Existing user - just update lastActive
      await _usersCollection.doc(uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Update user profile (name, gender, etc.) and mark profile as set
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? gender,
  }) async {
    final updateData = <String, dynamic>{
      'lastActive': FieldValue.serverTimestamp(),
    };

    // Update preferences map
    if (displayName != null) {
      updateData['preferences.displayName'] = displayName;
    }

    if (gender != null) {
      updateData['preferences.gender'] = gender;
    }

    // If both displayName and gender are provided, mark profile as set
    if (displayName != null && gender != null) {
      updateData['preferences.hasSetProfile'] = true;
    }

    await _usersCollection.doc(uid).update(updateData);
  }

  /// Get user document from Firestore
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return doc.data();
  }

  /// Check if user has completed profile setup in Firebase
  /// Returns true if user exists and has hasSetProfile = true
  Future<bool> hasUserCompletedProfileSetup(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      // Check new schema first
      final preferences = data['preferences'] as Map<String, dynamic>?;
      if (preferences != null) {
        return preferences['hasSetProfile'] == true;
      }

      // Fallback: check if old schema has gender set (migration support)
      // If user has gender in old format, they've completed profile
      return data['gender'] != null && data['gender'].toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get user preferences from Firestore
  /// Returns preferences map or null if not found
  Future<Map<String, dynamic>?> getUserPreferences(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Return preferences from new schema
      final preferences = data['preferences'] as Map<String, dynamic>?;
      if (preferences != null) {
        return preferences;
      }

      // Fallback: construct preferences from old schema
      return {
        'displayName': data['displayName'],
        'gender': data['gender'],
        'hasSetProfile': data['gender'] != null,
      };
    } catch (e) {
      return null;
    }
  }

  /// Check if user exists in Firestore
  Future<bool> userExists(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return doc.exists;
  }

  /// Delete user document
  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }
}
