/// Collaboration submission model
class CollaborationModel {
  final String? id;
  final List<SubmissionType> submissionTypes;
  final SourceType source;
  final int semesterSelection;
  final String subjectDetails;
  final List<String> filePaths;
  final String? urlSubmission;
  final String description;
  final bool wantsCredit;
  final String? creditName;
  final String? adminNotes;
  final DateTime submittedAt;

  CollaborationModel({
    this.id,
    required this.submissionTypes,
    required this.source,
    required this.semesterSelection,
    required this.subjectDetails,
    this.filePaths = const [],
    this.urlSubmission,
    required this.description,
    this.wantsCredit = false,
    this.creditName,
    this.adminNotes,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submissionTypes': submissionTypes.map((e) => e.name).toList(),
      'source': source.name,
      'semesterSelection': semesterSelection,
      'subjectDetails': subjectDetails,
      'filePaths': filePaths,
      'urlSubmission': urlSubmission,
      'description': description,
      'wantsCredit': wantsCredit,
      'creditName': creditName,
      'adminNotes': adminNotes,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory CollaborationModel.fromJson(Map<String, dynamic> json) {
    return CollaborationModel(
      id: json['id'] as String?,
      submissionTypes: (json['submissionTypes'] as List<dynamic>)
          .map((e) => SubmissionType.values.firstWhere((s) => s.name == e))
          .toList(),
      source: SourceType.values.firstWhere((e) => e.name == json['source']),
      semesterSelection: json['semesterSelection'] as int,
      subjectDetails: json['subjectDetails'] as String,
      filePaths: (json['filePaths'] as List<dynamic>?)?.cast<String>() ?? [],
      urlSubmission: json['urlSubmission'] as String?,
      description: json['description'] as String,
      wantsCredit: json['wantsCredit'] as bool? ?? false,
      creditName: json['creditName'] as String?,
      adminNotes: json['adminNotes'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
    );
  }
}

enum SubmissionType {
  notes,
  assignment,
  pyq,
  questionBank,
  referenceBook,
  tutorial,
  other,
}

enum SourceType {
  selfCreated,
  teacherProvided,
  internetSource,
  otherStudent,
  other,
}
