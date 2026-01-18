import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/semester_model.dart';
import '../../core/constants/app_constants.dart';

/// Repository for loading navigation manifest
class NavigationRepository {
  List<SemesterModel>? _cachedSemesters;

  /// Load semesters from navigation.json asset
  Future<List<SemesterModel>> loadSemesters() async {
    if (_cachedSemesters != null) {
      return _cachedSemesters!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/navigation.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final semestersJson = jsonData['semesters'] as List<dynamic>;
      
      _cachedSemesters = semestersJson
          .map((e) => SemesterModel.fromJson(e as Map<String, dynamic>))
          .toList();
      
      return _cachedSemesters!;
    } catch (e) {
      // Return default semesters if asset not found
      return _getDefaultSemesters();
    }
  }

  /// Get semester by ID
  Future<SemesterModel?> getSemesterById(int id) async {
    final semesters = await loadSemesters();
    return semesters.where((s) => s.id == id).firstOrNull;
  }

  /// Clear cache
  void clearCache() {
    _cachedSemesters = null;
  }

  /// Get default semesters when asset is not available
  List<SemesterModel> _getDefaultSemesters() {
    return List.generate(AppConstants.totalSemesters, (index) {
      final semId = index + 1;
      return SemesterModel(
        id: semId,
        name: 'Semester $semId',
        description: AppConstants.semesterDescriptions[semId] ?? 'Course materials',
        thumbnailPath: 'assets/images/semester_thumbnails/sem_$semId.png',
        coreSubjects: _getDefaultSubjects(semId),
      );
    });
  }

  /// Get default subjects for a semester
  List<SubjectInfo> _getDefaultSubjects(int semesterId) {
    // Sample subjects - these will be replaced by actual data from navigation.json
    final subjectNames = {
      1: ['Mathematics I', 'Physics', 'Chemistry', 'English', 'Programming Fundamentals', 'Workshop'],
      2: ['Mathematics II', 'Data Structures', 'Digital Electronics', 'OOPs', 'Environmental Science', 'Communication Skills'],
      3: ['Mathematics III', 'Algorithms', 'Database Systems', 'Computer Networks', 'Operating Systems', 'Software Engineering'],
      4: ['Computer Architecture', 'Theory of Computation', 'Compiler Design', 'Machine Learning', 'Web Technologies', 'Elective I'],
      5: ['Artificial Intelligence', 'Information Security', 'Cloud Computing', 'Mobile App Development', 'Elective II', 'Elective III'],
      6: ['Deep Learning', 'Big Data Analytics', 'DevOps', 'Project I', 'Elective IV', 'Elective V'],
      7: ['Blockchain', 'Natural Language Processing', 'IoT', 'Project II', 'Elective VI', 'Internship'],
      8: ['Major Project', 'Industry Training', 'Seminar', 'Comprehensive Viva'],
    };

    final subjects = subjectNames[semesterId] ?? [];
    return subjects.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;
      final code = 'CS${semesterId}0${index + 1}';
      return SubjectInfo(
        id: code.toLowerCase(),
        code: code,
        name: name,
      );
    }).toList();
  }
}
