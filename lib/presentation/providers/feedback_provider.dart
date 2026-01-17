import 'package:flutter/foundation.dart';
import '../../data/models/feedback_model.dart';
import '../../data/models/collaboration_model.dart';
import '../../data/repositories/feedback_repository.dart';

/// State for form submission
enum FormSubmissionState {
  initial,
  submitting,
  success,
  error,
}

/// Provider for managing feedback and collaboration forms
class FeedbackProvider extends ChangeNotifier {
  final FeedbackRepository _feedbackRepository;

  FormSubmissionState _feedbackState = FormSubmissionState.initial;
  FormSubmissionState _collaborationState = FormSubmissionState.initial;
  String? _errorMessage;
  String? _successMessage;

  FeedbackProvider({FeedbackRepository? feedbackRepository})
      : _feedbackRepository = feedbackRepository ?? FeedbackRepository();

  // Getters
  FormSubmissionState get feedbackState => _feedbackState;
  FormSubmissionState get collaborationState => _collaborationState;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isFeedbackSubmitting => _feedbackState == FormSubmissionState.submitting;
  bool get isCollaborationSubmitting => _collaborationState == FormSubmissionState.submitting;

  /// Submit feedback form
  Future<bool> submitFeedback(FeedbackModel feedback) async {
    _feedbackState = FormSubmissionState.submitting;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _feedbackRepository.submitFeedback(feedback);
      if (success) {
        _feedbackState = FormSubmissionState.success;
        _successMessage = 'Feedback submitted successfully!';
        notifyListeners();
        return true;
      } else {
        _feedbackState = FormSubmissionState.error;
        _errorMessage = 'Failed to submit feedback. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _feedbackState = FormSubmissionState.error;
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Submit collaboration form
  Future<bool> submitCollaboration(CollaborationModel collaboration) async {
    _collaborationState = FormSubmissionState.submitting;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _feedbackRepository.submitCollaboration(collaboration);
      if (success) {
        _collaborationState = FormSubmissionState.success;
        _successMessage = 'Collaboration submitted successfully!';
        notifyListeners();
        return true;
      } else {
        _collaborationState = FormSubmissionState.error;
        _errorMessage = 'Failed to submit collaboration. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _collaborationState = FormSubmissionState.error;
      _errorMessage = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Validate feedback attachments
  bool validateFeedbackAttachments(List<String> paths, List<int> sizes) {
    return _feedbackRepository.validateFeedbackAttachments(paths, sizes);
  }

  /// Validate collaboration attachments
  bool validateCollaborationAttachments(List<String> paths, List<int> sizes) {
    return _feedbackRepository.validateCollaborationAttachments(paths, sizes);
  }

  /// Reset feedback form state
  void resetFeedbackState() {
    _feedbackState = FormSubmissionState.initial;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Reset collaboration form state
  void resetCollaborationState() {
    _collaborationState = FormSubmissionState.initial;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
