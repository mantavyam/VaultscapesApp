/// Semester entity for domain layer
class Semester {
  final int id;
  final String name;
  final String description;
  final String? thumbnailPath;
  final List<Subject> subjects;

  const Semester({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnailPath,
    this.subjects = const [],
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Semester && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Subject entity for domain layer
class Subject {
  final String code;
  final String name;
  final int semesterId;
  final String? description;

  const Subject({
    required this.code,
    required this.name,
    required this.semesterId,
    this.description,
  });

  String get fullName => '$code - $name';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subject && other.code == code && other.semesterId == semesterId;
  }

  @override
  int get hashCode => Object.hash(code, semesterId);
}
