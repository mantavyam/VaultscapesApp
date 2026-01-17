import 'package:flutter/foundation.dart';
import '../../data/models/semester_model.dart';
import '../../data/repositories/navigation_repository.dart';

/// Provider for managing navigation and semester data
class NavigationProvider extends ChangeNotifier {
  final NavigationRepository _navigationRepository;

  List<SemesterModel> _semesters = [];
  SemesterModel? _selectedSemester;
  SubjectInfo? _selectedSubject;
  bool _isLoading = false;
  String? _errorMessage;

  NavigationProvider({NavigationRepository? navigationRepository})
      : _navigationRepository = navigationRepository ?? NavigationRepository();

  // Getters
  List<SemesterModel> get semesters => _semesters;
  SemesterModel? get selectedSemester => _selectedSemester;
  SubjectInfo? get selectedSubject => _selectedSubject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all semesters
  Future<void> loadSemesters() async {
    if (_semesters.isNotEmpty) return; // Already loaded

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _semesters = await _navigationRepository.loadSemesters();
    } catch (e) {
      _errorMessage = 'Failed to load semesters: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Select a semester
  Future<void> selectSemester(int semesterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedSemester = await _navigationRepository.getSemesterById(semesterId);
      _selectedSubject = null; // Clear subject selection
    } catch (e) {
      _errorMessage = 'Failed to load semester: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Select a subject
  void selectSubject(SubjectInfo subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  /// Clear semester selection
  void clearSemesterSelection() {
    _selectedSemester = null;
    _selectedSubject = null;
    notifyListeners();
  }

  /// Clear subject selection
  void clearSubjectSelection() {
    _selectedSubject = null;
    notifyListeners();
  }

  /// Get semester by ID
  SemesterModel? getSemesterById(int id) {
    return _semesters.where((s) => s.id == id).firstOrNull;
  }

  /// Refresh semesters
  Future<void> refresh() async {
    _navigationRepository.clearCache();
    _semesters = [];
    await loadSemesters();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
