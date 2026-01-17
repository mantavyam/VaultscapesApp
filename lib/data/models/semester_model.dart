/// Semester model representing a semester with its metadata
class SemesterModel {
  final int id;
  final String name;
  final String description;
  final String? thumbnailPath;
  final String? syllabusUrl;
  final List<SubjectInfo> coreSubjects;
  final List<SubjectInfo> specializationSubjects;

  SemesterModel({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnailPath,
    this.syllabusUrl,
    this.coreSubjects = const [],
    this.specializationSubjects = const [],
  });

  /// Create from JSON
  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      syllabusUrl: json['syllabusUrl'] as String?,
      coreSubjects: (json['coreSubjects'] as List<dynamic>?)
              ?.map((e) => SubjectInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      specializationSubjects: (json['specializationSubjects'] as List<dynamic>?)
              ?.map((e) => SubjectInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnailPath': thumbnailPath,
      'syllabusUrl': syllabusUrl,
      'coreSubjects': coreSubjects.map((e) => e.toJson()).toList(),
      'specializationSubjects': specializationSubjects.map((e) => e.toJson()).toList(),
    };
  }

  /// Get all subjects
  List<SubjectInfo> get allSubjects => [...coreSubjects, ...specializationSubjects];
}

/// Subject info for navigation
class SubjectInfo {
  final String code;
  final String name;
  final String? markdownUrl;

  SubjectInfo({
    required this.code,
    required this.name,
    this.markdownUrl,
  });

  factory SubjectInfo.fromJson(Map<String, dynamic> json) {
    return SubjectInfo(
      code: json['code'] as String,
      name: json['name'] as String,
      markdownUrl: json['markdownUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'markdownUrl': markdownUrl,
    };
  }
}
