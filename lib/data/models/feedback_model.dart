/// Feedback form model
class FeedbackModel {
  final String? id;
  final String name;
  final String email;
  final UserRole role;
  final List<UsageFrequency> usageFrequency;
  final int semesterSelection;
  final FeedbackType feedbackType;
  final String description;
  final String? pageUrl;
  final List<String> attachmentPaths;
  final int? usabilityRating;
  final DateTime submittedAt;

  FeedbackModel({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.usageFrequency,
    required this.semesterSelection,
    required this.feedbackType,
    required this.description,
    this.pageUrl,
    this.attachmentPaths = const [],
    this.usabilityRating,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'usageFrequency': usageFrequency.map((e) => e.name).toList(),
      'semesterSelection': semesterSelection,
      'feedbackType': feedbackType.name,
      'description': description,
      'pageUrl': pageUrl,
      'attachmentPaths': attachmentPaths,
      'usabilityRating': usabilityRating,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String?,
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
      usabilityRating: json['usabilityRating'] as int?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
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
  rarely,
}

enum FeedbackType {
  suggestion,
  grievance,
  appreciation,
  bugReport,
  other,
}
