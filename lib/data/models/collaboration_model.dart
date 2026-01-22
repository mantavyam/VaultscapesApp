/// Collaboration submission model - Firestore collection: 'collaborate-submit'
class CollaborationModel {
  final String? id;
  final String? userId; // Firebase Auth UID
  final List<SubmissionType> submissionTypes;
  final SourceType source;
  final int semesterSelection;
  final String subjectDetails;
  final List<String> filePaths; // Local paths before upload
  final List<String> fileUrls; // Firebase Storage URLs after upload
  final String? urlSubmission;
  final String description;
  final bool wantsCredit;
  final String? creditName;
  final String? adminNotes;
  final DateTime submittedAt;
  final String status; // 'pending', 'approved', 'rejected', 'published'

  CollaborationModel({
    this.id,
    this.userId,
    required this.submissionTypes,
    required this.source,
    required this.semesterSelection,
    required this.subjectDetails,
    this.filePaths = const [],
    this.fileUrls = const [],
    this.urlSubmission,
    required this.description,
    this.wantsCredit = false,
    this.creditName,
    this.adminNotes,
    DateTime? submittedAt,
    this.status = 'pending',
  }) : submittedAt = submittedAt ?? DateTime.now();

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'submissionTypes': submissionTypes.map((e) => e.name).toList(),
      'source': source.name,
      'semesterSelection': semesterSelection,
      'subjectDetails': subjectDetails,
      'fileUrls': fileUrls,
      'urlSubmission': urlSubmission,
      'description': description,
      'wantsCredit': wantsCredit,
      'creditName': creditName,
      'adminNotes': adminNotes,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'submissionTypes': submissionTypes.map((e) => e.name).toList(),
      'source': source.name,
      'semesterSelection': semesterSelection,
      'subjectDetails': subjectDetails,
      'filePaths': filePaths,
      'fileUrls': fileUrls,
      'urlSubmission': urlSubmission,
      'description': description,
      'wantsCredit': wantsCredit,
      'creditName': creditName,
      'adminNotes': adminNotes,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
    };
  }

  factory CollaborationModel.fromJson(Map<String, dynamic> json) {
    return CollaborationModel(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      submissionTypes: (json['submissionTypes'] as List<dynamic>)
          .map((e) => SubmissionType.values.firstWhere((s) => s.name == e))
          .toList(),
      source: SourceType.values.firstWhere((e) => e.name == json['source']),
      semesterSelection: json['semesterSelection'] as int,
      subjectDetails: json['subjectDetails'] as String,
      filePaths: (json['filePaths'] as List<dynamic>?)?.cast<String>() ?? [],
      fileUrls: (json['fileUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      urlSubmission: json['urlSubmission'] as String?,
      description: json['description'] as String,
      wantsCredit: json['wantsCredit'] as bool? ?? false,
      creditName: json['creditName'] as String?,
      adminNotes: json['adminNotes'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// Create a copy with updated file URLs (after upload)
  CollaborationModel copyWithUrls(List<String> urls) {
    return CollaborationModel(
      id: id,
      userId: userId,
      submissionTypes: submissionTypes,
      source: source,
      semesterSelection: semesterSelection,
      subjectDetails: subjectDetails,
      filePaths: filePaths,
      fileUrls: urls,
      urlSubmission: urlSubmission,
      description: description,
      wantsCredit: wantsCredit,
      creditName: creditName,
      adminNotes: adminNotes,
      submittedAt: submittedAt,
      status: status,
    );
  }

  /// Create a copy with userId
  CollaborationModel copyWithUserId(String uid) {
    return CollaborationModel(
      id: id,
      userId: uid,
      submissionTypes: submissionTypes,
      source: source,
      semesterSelection: semesterSelection,
      subjectDetails: subjectDetails,
      filePaths: filePaths,
      fileUrls: fileUrls,
      urlSubmission: urlSubmission,
      description: description,
      wantsCredit: wantsCredit,
      creditName: creditName,
      adminNotes: adminNotes,
      submittedAt: submittedAt,
      status: status,
    );
  }
}

enum SubmissionType {
  notes,
  assignment,
  labManual,
  questionBank,
  examPapers,
  codeExamples,
  externalLinks,
}

enum SourceType {
  selfWritten,
  internetResource,
  facultyProvided,
  aiAssisted,
}
