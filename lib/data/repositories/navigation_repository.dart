import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/semester_model.dart';
import '../../core/constants/app_constants.dart';

/// Repository for loading navigation manifest from remote or cache
class NavigationRepository {
  List<SemesterModel>? _cachedSemesters;

  /// Remote URL for navigation data
  static const String _remoteUrl =
      'https://raw.githubusercontent.com/mantavyam/vaultscapesDB/refs/heads/main/sitemap.json';

  /// Cache key for SharedPreferences
  static const String _cacheKey = 'cached_navigation_json';
  static const String _cacheTimestampKey = 'cached_navigation_timestamp';

  /// Cache duration (24 hours)
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Load semesters from remote URL with caching and fallback
  Future<List<SemesterModel>> loadSemesters() async {
    if (_cachedSemesters != null) {
      return _cachedSemesters!;
    }

    try {
      // Try to load from remote first
      final jsonData = await _loadFromRemote();
      if (jsonData != null) {
        _cachedSemesters = _parseSemesters(jsonData);
        return _cachedSemesters!;
      }

      // Fall back to local cache
      final cachedJson = await _loadFromLocalCache();
      if (cachedJson != null) {
        _cachedSemesters = _parseSemesters(cachedJson);
        return _cachedSemesters!;
      }

      // Last resort: default semesters
      return _getDefaultSemesters();
    } catch (e) {
      // Try local cache on error
      try {
        final cachedJson = await _loadFromLocalCache();
        if (cachedJson != null) {
          _cachedSemesters = _parseSemesters(cachedJson);
          return _cachedSemesters!;
        }
      } catch (_) {
        // Ignore cache errors
      }

      // Return default semesters if all else fails
      return _getDefaultSemesters();
    }
  }

  /// Load JSON data from remote URL
  Future<Map<String, dynamic>?> _loadFromRemote() async {
    try {
      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        // Save to local cache for offline access
        await _saveToLocalCache(response.body);

        return jsonData;
      }
    } catch (e) {
      // Network error, will fall back to cache
    }
    return null;
  }

  /// Load JSON from local cache (SharedPreferences)
  Future<Map<String, dynamic>?> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedJson != null) {
        // Check if cache is not too old (optional - can still use if remote fails)
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final isExpired =
              DateTime.now().difference(cacheTime) > _cacheDuration;
          // We still return cached data even if expired, as fallback
          if (!isExpired) {
            return jsonDecode(cachedJson) as Map<String, dynamic>;
          }
        }
        // Return cached data even if timestamp missing or expired (as fallback)
        return jsonDecode(cachedJson) as Map<String, dynamic>;
      }
    } catch (e) {
      // Cache read error
    }
    return null;
  }

  /// Save JSON to local cache
  Future<void> _saveToLocalCache(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Cache write error - non-critical
    }
  }

  /// Parse semesters from JSON data
  List<SemesterModel> _parseSemesters(Map<String, dynamic> jsonData) {
    final semestersJson = jsonData['semesters'] as List<dynamic>;
    return semestersJson
        .map((e) => SemesterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get semester by ID
  Future<SemesterModel?> getSemesterById(int id) async {
    final semesters = await loadSemesters();
    return semesters.where((s) => s.id == id).firstOrNull;
  }

  /// Clear cache (both memory and local)
  Future<void> clearCache() async {
    _cachedSemesters = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (_) {
      // Ignore cache clear errors
    }
  }

  /// Force refresh from remote (ignores cache)
  Future<List<SemesterModel>> refreshFromRemote() async {
    _cachedSemesters = null;

    try {
      final jsonData = await _loadFromRemote();
      if (jsonData != null) {
        _cachedSemesters = _parseSemesters(jsonData);
        return _cachedSemesters!;
      }
    } catch (_) {
      // Fall through to cached data
    }

    // Return whatever we have cached
    return loadSemesters();
  }

  /// Get default semesters when remote and cache are not available
  List<SemesterModel> _getDefaultSemesters() {
    return List.generate(AppConstants.totalSemesters, (index) {
      final semId = index + 1;
      return SemesterModel(
        id: semId,
        name: 'Semester $semId',
        description:
            AppConstants.semesterDescriptions[semId] ?? 'Course materials',
        thumbnailPath: 'assets/images/semester_thumbnails/sem_$semId.png',
        coreSubjects: _getDefaultSubjects(semId),
      );
    });
  }

  /// Get default subjects for a semester
  List<SubjectInfo> _getDefaultSubjects(int semesterId) {
    // Sample subjects - these will be replaced by actual data from remote
    final subjectNames = {
      1: [
        'Mathematics I',
        'Physics',
        'Chemistry',
        'English',
        'Programming Fundamentals',
        'Workshop',
      ],
      2: [
        'Mathematics II',
        'Data Structures',
        'Digital Electronics',
        'OOPs',
        'Environmental Science',
        'Communication Skills',
      ],
      3: [
        'Mathematics III',
        'Algorithms',
        'Database Systems',
        'Computer Networks',
        'Operating Systems',
        'Software Engineering',
      ],
      4: [
        'Computer Architecture',
        'Theory of Computation',
        'Compiler Design',
        'Machine Learning',
        'Web Technologies',
        'Elective I',
      ],
      5: [
        'Artificial Intelligence',
        'Information Security',
        'Cloud Computing',
        'Mobile App Development',
        'Elective II',
        'Elective III',
      ],
      6: [
        'Deep Learning',
        'Big Data Analytics',
        'DevOps',
        'Project I',
        'Elective IV',
        'Elective V',
      ],
      7: [
        'Blockchain',
        'Natural Language Processing',
        'IoT',
        'Project II',
        'Elective VI',
        'Internship',
      ],
      8: [
        'Major Project',
        'Industry Training',
        'Seminar',
        'Comprehensive Viva',
      ],
    };

    final subjects = subjectNames[semesterId] ?? [];
    return subjects.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;
      final code = 'CS${semesterId}0${index + 1}';
      return SubjectInfo(id: code.toLowerCase(), code: code, name: name);
    }).toList();
  }
}
