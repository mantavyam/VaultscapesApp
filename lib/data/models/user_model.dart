/// User model for authentication and profile management
class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? provider;
  final DateTime createdAt;
  final String? homepagePreference;
  final bool isGuest;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.provider,
    required this.createdAt,
    this.homepagePreference,
    this.isGuest = false,
  });

  /// Create a guest user
  factory UserModel.guest() {
    return UserModel(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      isGuest: true,
    );
  }

  /// Create a mock authenticated user (Phase 1)
  factory UserModel.mockAuth({String? name, String? email}) {
    final uid = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    return UserModel(
      uid: uid,
      email: email ?? 'user@vaultscapes.app',
      displayName: name ?? 'Vaultscapes User',
      provider: 'mock',
      createdAt: DateTime.now(),
      isGuest: false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'provider': provider,
      'createdAt': createdAt.toIso8601String(),
      'homepagePreference': homepagePreference,
      'isGuest': isGuest,
    };
  }

  /// Create from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      provider: json['provider'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      homepagePreference: json['homepagePreference'] as String?,
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? provider,
    DateTime? createdAt,
    String? homepagePreference,
    bool? isGuest,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      homepagePreference: homepagePreference ?? this.homepagePreference,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, isGuest: $isGuest)';
  }
}
