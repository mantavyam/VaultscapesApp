/// Subject model with detailed information
class SubjectModel {
  final String code;
  final String name;
  final int semesterId;
  final String? description;
  final String? syllabusUrl;
  final List<ModuleInfo> modules;
  final List<ResourceLink> externalResources;
  final NoteSection? notes;
  final QuestionSection? questions;

  SubjectModel({
    required this.code,
    required this.name,
    required this.semesterId,
    this.description,
    this.syllabusUrl,
    this.modules = const [],
    this.externalResources = const [],
    this.notes,
    this.questions,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      code: json['code'] as String,
      name: json['name'] as String,
      semesterId: json['semesterId'] as int,
      description: json['description'] as String?,
      syllabusUrl: json['syllabusUrl'] as String?,
      modules: (json['modules'] as List<dynamic>?)
              ?.map((e) => ModuleInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      externalResources: (json['externalResources'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] != null
          ? NoteSection.fromJson(json['notes'] as Map<String, dynamic>)
          : null,
      questions: json['questions'] != null
          ? QuestionSection.fromJson(json['questions'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'semesterId': semesterId,
      'description': description,
      'syllabusUrl': syllabusUrl,
      'modules': modules.map((e) => e.toJson()).toList(),
      'externalResources': externalResources.map((e) => e.toJson()).toList(),
      'notes': notes?.toJson(),
      'questions': questions?.toJson(),
    };
  }
}

/// Module information within a subject
class ModuleInfo {
  final int number;
  final String title;
  final String? markdownUrl;
  final List<ResourceLink> resources;

  ModuleInfo({
    required this.number,
    required this.title,
    this.markdownUrl,
    this.resources = const [],
  });

  factory ModuleInfo.fromJson(Map<String, dynamic> json) {
    return ModuleInfo(
      number: json['number'] as int,
      title: json['title'] as String,
      markdownUrl: json['markdownUrl'] as String?,
      resources: (json['resources'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'markdownUrl': markdownUrl,
      'resources': resources.map((e) => e.toJson()).toList(),
    };
  }
}

/// Resource link model
class ResourceLink {
  final String title;
  final String url;
  final ResourceType type;
  final String? description;

  ResourceLink({
    required this.title,
    required this.url,
    required this.type,
    this.description,
  });

  factory ResourceLink.fromJson(Map<String, dynamic> json) {
    return ResourceLink(
      title: json['title'] as String,
      url: json['url'] as String,
      type: ResourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ResourceType.other,
      ),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'type': type.name,
      'description': description,
    };
  }
}

enum ResourceType { pdf, video, youtube, website, other }

/// Note section for subject
class NoteSection {
  final List<ResourceLink> shortNotes;
  final List<ResourceLink> midSemNotes;
  final List<ResourceLink> endSemNotes;
  final List<ResourceLink> oneShotNotes;

  NoteSection({
    this.shortNotes = const [],
    this.midSemNotes = const [],
    this.endSemNotes = const [],
    this.oneShotNotes = const [],
  });

  factory NoteSection.fromJson(Map<String, dynamic> json) {
    return NoteSection(
      shortNotes: (json['shortNotes'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      midSemNotes: (json['midSemNotes'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      endSemNotes: (json['endSemNotes'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      oneShotNotes: (json['oneShotNotes'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shortNotes': shortNotes.map((e) => e.toJson()).toList(),
      'midSemNotes': midSemNotes.map((e) => e.toJson()).toList(),
      'endSemNotes': endSemNotes.map((e) => e.toJson()).toList(),
      'oneShotNotes': oneShotNotes.map((e) => e.toJson()).toList(),
    };
  }
}

/// Question section for subject
class QuestionSection {
  final List<ResourceLink> questionBanks;
  final List<ResourceLink> midSemPyqs;
  final List<ResourceLink> endSemPyqs;
  final List<ResourceLink> expectedQuestions;

  QuestionSection({
    this.questionBanks = const [],
    this.midSemPyqs = const [],
    this.endSemPyqs = const [],
    this.expectedQuestions = const [],
  });

  factory QuestionSection.fromJson(Map<String, dynamic> json) {
    return QuestionSection(
      questionBanks: (json['questionBanks'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      midSemPyqs: (json['midSemPyqs'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      endSemPyqs: (json['endSemPyqs'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expectedQuestions: (json['expectedQuestions'] as List<dynamic>?)
              ?.map((e) => ResourceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionBanks': questionBanks.map((e) => e.toJson()).toList(),
      'midSemPyqs': midSemPyqs.map((e) => e.toJson()).toList(),
      'endSemPyqs': endSemPyqs.map((e) => e.toJson()).toList(),
      'expectedQuestions': expectedQuestions.map((e) => e.toJson()).toList(),
    };
  }
}
