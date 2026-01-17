/// User entity for domain layer
class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isGuest;
  final String? homepagePreference;

  const User({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isGuest = false,
    this.homepagePreference,
  });

  bool get isAuthenticated => !isGuest;

  String get displayNameOrDefault => displayName ?? (isGuest ? 'Guest' : 'User');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
