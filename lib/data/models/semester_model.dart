/// Semester model representing a semester with its metadata
class SemesterModel {
  final int id;
  final String name;
  final String description;
  final int order;
  final String? thumbnailPath;
  final String? overviewGitbookUrl;
  final String? overviewName;
  final List<SubjectInfo> coreSubjects;
  final List<SubjectInfo> specializationSubjects;

  SemesterModel({
    required this.id,
    required this.name,
    required this.description,
    this.order = 0,
    this.thumbnailPath,
    this.overviewGitbookUrl,
    this.overviewName,
    this.coreSubjects = const [],
    this.specializationSubjects = const [],
  });

  /// Create from JSON (navigation.json format with core and specialisation arrays)
  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    // Parse the id which can be "y1s1", "y1s2", etc. or an int
    final rawId = json['id'];
    final int semId;
    if (rawId is String) {
      // Parse "y1s1" -> extract last digit as semester number
      // Format: y<year>s<semester>
      final match = RegExp(r's(\d+)$').firstMatch(rawId);
      if (match != null) {
        semId = int.tryParse(match.group(1)!) ?? 1;
      } else {
        // Fallback: try to extract any number
        semId = int.tryParse(rawId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      }
    } else {
      semId = rawId as int;
    }

    // Parse overview section
    final overview = json['overview'] as Map<String, dynamic>?;

    // Parse order
    final order = json['order'] as int? ?? semId;

    // Parse core subjects from 'core' array
    final coreSubjects =
        (json['core'] as List<dynamic>?)
            ?.map(
              (e) => SubjectInfo.fromJson(
                e as Map<String, dynamic>,
                isSpecialization: false,
              ),
            )
            .toList() ??
        [];

    // Parse specialization subjects from 'specialisation' array
    final specSubjects =
        (json['specialisation'] as List<dynamic>?)
            ?.map(
              (e) => SubjectInfo.fromJson(
                e as Map<String, dynamic>,
                isSpecialization: true,
              ),
            )
            .toList() ??
        [];

    return SemesterModel(
      id: semId,
      name: json['name'] as String? ?? 'Semester $semId',
      description: json['description'] as String? ?? '',
      order: order,
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
      'order': order,
      'thumbnailPath': thumbnailPath,
      'overviewGitbookUrl': overviewGitbookUrl,
      'overviewName': overviewName,
      'coreSubjects': coreSubjects.map((e) => e.toJson()).toList(),
      'specializationSubjects': specializationSubjects
          .map((e) => e.toJson())
          .toList(),
    };
  }

  /// Get all subjects (core first, then specialization)
  List<SubjectInfo> get allSubjects => [
    ...coreSubjects,
    ...specializationSubjects,
  ];

  /// Get parent-child relationship map for subjects
  /// Returns a map where key is parent subject and value is list of child subjects
  Map<SubjectInfo, List<SubjectInfo>> get subjectHierarchy {
    final Map<SubjectInfo, List<SubjectInfo>> hierarchy = {};
    final allSubs = allSubjects;

    for (final subject in allSubs) {
      if (subject.gitbookUrl == null) continue;

      // Check if this subject is a child of another subject
      bool isChild = false;
      for (final potentialParent in allSubs) {
        if (potentialParent.id == subject.id) continue;
        if (potentialParent.gitbookUrl == null) continue;

        // Child URL should contain parent URL and be longer
        if (subject.gitbookUrl!.startsWith(potentialParent.gitbookUrl!) &&
            subject.gitbookUrl!.length > potentialParent.gitbookUrl!.length) {
          // This subject is a child of potentialParent
          hierarchy[potentialParent] ??= [];
          hierarchy[potentialParent]!.add(subject);
          isChild = true;
          break;
        }
      }

      // If not a child, it's a top-level subject
      if (!isChild) {
        hierarchy[subject] ??= [];
      }
    }

    return hierarchy;
  }

  /// Get flat list of subjects excluding children (for sidebar accordion)
  List<SubjectInfo> get topLevelSubjects {
    final childIds = <String>{};
    final hierarchy = subjectHierarchy;

    for (final children in hierarchy.values) {
      for (final child in children) {
        childIds.add(child.id);
      }
    }

    return allSubjects.where((s) => !childIds.contains(s.id)).toList();
  }

  /// Get children for a specific subject
  List<SubjectInfo> getChildrenOf(SubjectInfo parent) {
    return subjectHierarchy[parent] ?? [];
  }
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

  factory SubjectInfo.fromJson(
    Map<String, dynamic> json, {
    bool isSpecialization = false,
  }) {
    return SubjectInfo(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gitbookUrl: json['gitbookUrl'] as String?,
      isSpecialization: isSpecialization,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubjectInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
