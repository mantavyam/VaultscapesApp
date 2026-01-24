/// Feedback form model - Firestore collection: 'feedback-submit'
class FeedbackModel {
  final String? id;
  final String? userId; // Firebase Auth UID
  final String name;
  final String email;
  final UserRole role;
  final List<UsageFrequency> usageFrequency;
  final int semesterSelection;
  final FeedbackType feedbackType;
  final String description;
  final String? pageUrl;
  final List<String> attachmentPaths; // Local paths before upload
  final List<String> attachmentUrls; // Firebase Storage URLs after upload
  final List<String> attachmentNames; // Original filenames
  final int? usabilityRating;
  final DateTime submittedAt;
  final String status; // 'pending', 'reviewed', 'resolved'

  FeedbackModel({
    this.id,
    this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.usageFrequency,
    required this.semesterSelection,
    required this.feedbackType,
    required this.description,
    this.pageUrl,
    this.attachmentPaths = const [],
    this.attachmentUrls = const [],
    this.attachmentNames = const [],
    this.usabilityRating,
    DateTime? submittedAt,
    this.status = 'pending',
  }) : submittedAt = submittedAt ?? DateTime.now();

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role.name,
      'usageFrequency': usageFrequency.map((e) => e.name).toList(),
      'semesterSelection': semesterSelection,
      'feedbackType': feedbackType.name,
      'description': description,
      'pageUrl': pageUrl,
      'attachmentUrls': attachmentUrls,
      'attachmentNames': attachmentNames,
      'usabilityRating': usabilityRating,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'role': role.name,
      'usageFrequency': usageFrequency.map((e) => e.name).toList(),
      'semesterSelection': semesterSelection,
      'feedbackType': feedbackType.name,
      'description': description,
      'pageUrl': pageUrl,
      'attachmentPaths': attachmentPaths,
      'attachmentUrls': attachmentUrls,
      'attachmentNames': attachmentNames,
      'usabilityRating': usabilityRating,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
    };
  }

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      usageFrequency: (json['usageFrequency'] as List<dynamic>)
          .map((e) => UsageFrequency.values.firstWhere((u) => u.name == e))
          .toList(),
      semesterSelection: json['semesterSelection'] as int,
      feedbackType: FeedbackType.values.firstWhere((e) => e.name == json['feedbackType']),
      description: json['description'] as String,
      pageUrl: json['pageUrl'] as String?,
      attachmentPaths: (json['attachmentPaths'] as List<dynamic>?)?.cast<String>() ?? [],
      attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      attachmentNames: (json['attachmentNames'] as List<dynamic>?)?.cast<String>() ?? [],
      usabilityRating: json['usabilityRating'] as int?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// Create a copy with updated attachment URLs and names (after upload)
  FeedbackModel copyWithUrls(List<String> urls, List<String> names) {
    return FeedbackModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      role: role,
      usageFrequency: usageFrequency,
      semesterSelection: semesterSelection,
      feedbackType: feedbackType,
      description: description,
      pageUrl: pageUrl,
      attachmentPaths: attachmentPaths,
      attachmentUrls: urls,
      attachmentNames: names,
      usabilityRating: usabilityRating,
      submittedAt: submittedAt,
      status: status,
    );
  }

  /// Create a copy with userId
  FeedbackModel copyWithUserId(String uid) {
    return FeedbackModel(
      id: id,
      userId: uid,
      name: name,
      email: email,
      role: role,
      usageFrequency: usageFrequency,
      semesterSelection: semesterSelection,
      feedbackType: feedbackType,
      description: description,
      pageUrl: pageUrl,
      attachmentPaths: attachmentPaths,
      attachmentUrls: attachmentUrls,
      attachmentNames: attachmentNames,
      usabilityRating: usabilityRating,
      submittedAt: submittedAt,
      status: status,
    );
  }
}

enum UserRole {
  student,
  faculty,
  alumni,
  staff,
  other,
}

enum UsageFrequency {
  daily,
  weekly,
  monthly,
  examTimeOnly,
  amateurNewUser,
}

enum FeedbackType {
  grievance,
  improvementSuggestion,
  generalFeedback,
  technicalIssues,
}
