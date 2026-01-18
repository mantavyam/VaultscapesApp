/// Semester model representing a semester with its metadata
class SemesterModel {
  final int id;
  final String name;
  final String description;
  final String? thumbnailPath;
  final String? overviewGitbookUrl;
  final String? overviewName;
  final List<SubjectInfo> coreSubjects;
  final List<SubjectInfo> specializationSubjects;

  SemesterModel({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnailPath,
    this.overviewGitbookUrl,
    this.overviewName,
    this.coreSubjects = const [],
    this.specializationSubjects = const [],
  });

  /// Create from JSON (navigation.json format)
  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    // Parse the id which can be "semester-1" or an int
    final rawId = json['id'];
    final int semId;
    if (rawId is String) {
      // Parse "semester-1" -> 1
      semId = int.tryParse(rawId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    } else {
      semId = rawId as int;
    }

    // Parse overview section
    final overview = json['overview'] as Map<String, dynamic>?;
    
    // Parse subjects - can be a flat list
    final subjects = (json['subjects'] as List<dynamic>?)
        ?.map((e) => SubjectInfo.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    
    // Separate core and specialization subjects
    final coreSubjects = subjects.where((s) => !s.isSpecialization).toList();
    final specSubjects = subjects.where((s) => s.isSpecialization).toList();

    return SemesterModel(
      id: semId,
      name: json['name'] as String? ?? 'Semester $semId',
      description: json['description'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String?,
      overviewGitbookUrl: overview?['gitbookUrl'] as String?,
      overviewName: overview?['name'] as String?,
      coreSubjects: coreSubjects,
      specializationSubjects: specSubjects,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnailPath': thumbnailPath,
      'overviewGitbookUrl': overviewGitbookUrl,
      'overviewName': overviewName,
      'coreSubjects': coreSubjects.map((e) => e.toJson()).toList(),
      'specializationSubjects': specializationSubjects.map((e) => e.toJson()).toList(),
    };
  }

  /// Get all subjects
  List<SubjectInfo> get allSubjects => [...coreSubjects, ...specializationSubjects];
}

/// Subject info for navigation
class SubjectInfo {
  final String id;
  final String code;
  final String name;
  final String? gitbookUrl;
  final bool isSpecialization;

  SubjectInfo({
    required this.id,
    required this.code,
    required this.name,
    this.gitbookUrl,
    this.isSpecialization = false,
  });

  factory SubjectInfo.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return SubjectInfo(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: name,
      gitbookUrl: json['gitbookUrl'] as String?,
      isSpecialization: name.toLowerCase().contains('(spec)') || 
                        (json['gitbookUrl'] as String? ?? '').contains('specialisation'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'gitbookUrl': gitbookUrl,
      'isSpecialization': isSpecialization,
    };
  }
}
