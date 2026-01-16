class PreferencesModel {
  final int? semesterPreference; // 1-8 or null (default)
  final bool hasSeenWelcome; // First-time launch flag
  final DateTime? lastActive; // Last app open timestamp

  const PreferencesModel({
    this.semesterPreference,
    required this.hasSeenWelcome,
    this.lastActive,
  });

  // Create a copy with updated fields
  PreferencesModel copyWith({
    int? semesterPreference,
    bool? hasSeenWelcome,
    DateTime? lastActive,
  }) {
    return PreferencesModel(
      semesterPreference: semesterPreference ?? this.semesterPreference,
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  // Returns semester display string
  String get semesterDisplayString {
    if (semesterPreference == null) return 'Default';
    return 'Sem $semesterPreference';
  }

  // Returns full semester display string with prefix
  String get fullSemesterDisplay {
    return 'Semester: $semesterDisplayString';
  }

  // Check if semester preference is set
  bool get hasSemesterPreference => semesterPreference != null;

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'semesterPreference': semesterPreference,
      'hasSeenWelcome': hasSeenWelcome,
      'lastActive': lastActive?.toIso8601String(),
    };
  }

  // Create from JSON
  factory PreferencesModel.fromJson(Map<String, dynamic> json) {
    return PreferencesModel(
      semesterPreference: json['semesterPreference'],
      hasSeenWelcome: json['hasSeenWelcome'] ?? false,
      lastActive: json['lastActive'] != null 
          ? DateTime.parse(json['lastActive']) 
          : null,
    );
  }

  // Factory for default/initial preferences
  factory PreferencesModel.initial() {
    return const PreferencesModel(
      semesterPreference: null,
      hasSeenWelcome: false,
      lastActive: null,
    );
  }

  // Factory for after welcome screen is seen
  factory PreferencesModel.afterWelcome() {
    return PreferencesModel(
      semesterPreference: null,
      hasSeenWelcome: true,
      lastActive: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PreferencesModel(semester: $semesterPreference, seenWelcome: $hasSeenWelcome, lastActive: $lastActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PreferencesModel &&
        other.semesterPreference == semesterPreference &&
        other.hasSeenWelcome == hasSeenWelcome &&
        other.lastActive == lastActive;
  }

  @override
  int get hashCode {
    return Object.hash(semesterPreference, hasSeenWelcome, lastActive);
  }
}