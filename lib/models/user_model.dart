class UserModel {
  final String userId;
  final String email;
  final String providerName;
  final String? customName;
  final String authProvider; // "google" or "github"
  final bool isAuthenticated; // false in Phase 1 (mock), true in Phase 2
  final String? photoURL;

  const UserModel({
    required this.userId,
    required this.email,
    required this.providerName,
    this.customName,
    required this.authProvider,
    required this.isAuthenticated,
    this.photoURL,
  });

  // Computed property for display name
  String get displayName => customName ?? providerName;

  // Gets initials for avatar (first letter of first and last name)
  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return 'U';
    
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    } else {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
    }
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? userId,
    String? email,
    String? providerName,
    String? customName,
    String? authProvider,
    bool? isAuthenticated,
    String? photoURL,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      providerName: providerName ?? this.providerName,
      customName: customName ?? this.customName,
      authProvider: authProvider ?? this.authProvider,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      photoURL: photoURL ?? this.photoURL,
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'providerName': providerName,
      'customName': customName,
      'authProvider': authProvider,
      'isAuthenticated': isAuthenticated,
      'photoURL': photoURL,
    };
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      providerName: json['providerName'] ?? '',
      customName: json['customName'],
      authProvider: json['authProvider'] ?? 'google',
      isAuthenticated: json['isAuthenticated'] ?? false,
      photoURL: json['photoURL'],
    );
  }

  // Factory for creating mock users (Phase 1)
  factory UserModel.mock({
    required String provider,
    String? mockName,
    String? mockEmail,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return UserModel(
      userId: 'mock_$timestamp',
      email: mockEmail ?? 'student@example.com',
      providerName: mockName ?? 'John Doe',
      customName: null,
      authProvider: provider,
      isAuthenticated: false, // Always false for mocks
      photoURL: null,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, email: $email, displayName: $displayName, provider: $authProvider, authenticated: $isAuthenticated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}