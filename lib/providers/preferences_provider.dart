import 'package:flutter/foundation.dart';
import '../models/preferences_model.dart';
import '../services/storage_service.dart';

class PreferencesProvider extends ChangeNotifier {
  PreferencesModel _preferences = PreferencesModel.initial();
  bool _isLoading = false;

  // Getters
  PreferencesModel get preferences => _preferences;
  bool get isLoading => _isLoading;
  int? get semesterPreference => _preferences.semesterPreference;
  bool get hasSeenWelcome => _preferences.hasSeenWelcome;
  String get semesterDisplayString => _preferences.semesterDisplayString;
  String get fullSemesterDisplay => _preferences.fullSemesterDisplay;

  // Initialize preferences from storage
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      _preferences = StorageService.getPreferences();
    } catch (e) {
      // If loading fails, keep initial preferences
      _preferences = PreferencesModel.initial();
    }
    
    _setLoading(false);
  }

  // Mark welcome screen as seen
  Future<bool> markWelcomeSeen() async {
    _setLoading(true);
    
    try {
      _preferences = _preferences.copyWith(
        hasSeenWelcome: true,
        lastActive: DateTime.now(),
      );
      
      final saved = await StorageService.savePreferences(_preferences);
      if (saved) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set semester preference
  Future<bool> setSemesterPreference(int? semester) async {
    // Validate semester (null is allowed for default)
    if (semester != null && (semester < 1 || semester > 8)) {
      return false;
    }

    _setLoading(true);
    
    try {
      _preferences = _preferences.copyWith(
        semesterPreference: semester,
        lastActive: DateTime.now(),
      );
      
      final saved = await StorageService.savePreferences(_preferences);
      if (saved) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear semester preference (set to default)
  Future<bool> clearSemesterPreference() async {
    return await setSemesterPreference(null);
  }

  // Update last active timestamp
  Future<bool> updateLastActive() async {
    _setLoading(true);
    
    try {
      _preferences = _preferences.copyWith(lastActive: DateTime.now());
      
      final saved = await StorageService.savePreferences(_preferences);
      if (saved) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset all preferences to default (except hasSeenWelcome)
  Future<bool> resetPreferences({bool keepWelcomeFlag = true}) async {
    _setLoading(true);
    
    try {
      _preferences = PreferencesModel(
        semesterPreference: null,
        hasSeenWelcome: keepWelcomeFlag ? _preferences.hasSeenWelcome : false,
        lastActive: DateTime.now(),
      );
      
      final saved = await StorageService.savePreferences(_preferences);
      if (saved) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get semester options for dropdown
  List<SemesterOption> getSemesterOptions() {
    return [
      SemesterOption(value: null, display: 'Default'),
      SemesterOption(value: 1, display: 'Sem 1'),
      SemesterOption(value: 2, display: 'Sem 2'),
      SemesterOption(value: 3, display: 'Sem 3'),
      SemesterOption(value: 4, display: 'Sem 4'),
      SemesterOption(value: 5, display: 'Sem 5'),
      SemesterOption(value: 6, display: 'Sem 6'),
      SemesterOption(value: 7, display: 'Sem 7'),
      SemesterOption(value: 8, display: 'Sem 8'),
    ];
  }

  // Check if a semester is currently selected
  bool isSemesterSelected(int? semester) {
    return _preferences.semesterPreference == semester;
  }

  // Get home URL based on current semester preference
  String getHomeUrl() {
    // This will be used by HomeScreen to construct the correct URL
    if (_preferences.semesterPreference != null) {
      return 'https://mantavyam.gitbook.io/vaultscapes/sem-${_preferences.semesterPreference}';
    }
    return 'https://mantavyam.gitbook.io/vaultscapes';
  }

  // Private helper method
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

// Helper class for semester dropdown options
class SemesterOption {
  final int? value;
  final String display;

  SemesterOption({required this.value, required this.display});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemesterOption && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}