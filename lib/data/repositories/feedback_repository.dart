import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/feedback_model.dart';
import '../models/collaboration_model.dart';
import '../../core/error/exceptions.dart';

/// Repository for handling feedback and collaboration submissions
class FeedbackRepository {
  // In Phase 1, we'll mock the API calls
  // In Phase 2, this will connect to actual backend

  /// Submit feedback (mock implementation for Phase 1)
  Future<bool> submitFeedback(FeedbackModel feedback) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Log the submission (in real implementation, this goes to backend)
      debugPrint('Feedback submitted: ${jsonEncode(feedback.toJson())}');

      // Mock success
      return true;
    } catch (e) {
      throw ServerException('Failed to submit feedback: $e');
    }
  }

  /// Submit collaboration (mock implementation for Phase 1)
  Future<bool> submitCollaboration(CollaborationModel collaboration) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Log the submission (in real implementation, this goes to backend)
      debugPrint('Collaboration submitted: ${jsonEncode(collaboration.toJson())}');

      // Mock success
      return true;
    } catch (e) {
      throw ServerException('Failed to submit collaboration: $e');
    }
  }

  /// Validate file size and count for feedback attachments
  bool validateFeedbackAttachments(List<String> filePaths, List<int> fileSizes) {
    const maxFiles = 5;
    const maxTotalSizeMB = 10;

    if (filePaths.length > maxFiles) return false;

    final totalSizeBytes = fileSizes.reduce((a, b) => a + b);
    final totalSizeMB = totalSizeBytes / (1024 * 1024);

    return totalSizeMB <= maxTotalSizeMB;
  }

  /// Validate file size and count for collaboration attachments
  bool validateCollaborationAttachments(List<String> filePaths, List<int> fileSizes) {
    const maxFiles = 10;
    const maxFileSizeMB = 5;

    if (filePaths.length > maxFiles) return false;

    for (final size in fileSizes) {
      if (size > maxFileSizeMB * 1024 * 1024) return false;
    }

    return true;
  }
}
