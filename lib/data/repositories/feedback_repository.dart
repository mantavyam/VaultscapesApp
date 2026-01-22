import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feedback_model.dart';
import '../models/collaboration_model.dart';
import '../../core/error/exceptions.dart';

/// Repository for handling feedback and collaboration submissions to Firebase
class FeedbackRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  // Firestore collection names
  static const String _feedbackCollection = 'feedback-submit';
  static const String _collaborateCollection = 'collaborate-submit';

  // Storage folder paths
  static const String _feedbackStoragePath = 'form-data/feedback-attach';
  static const String _collaborateStoragePath = 'form-data/collaborate-attach';

  FeedbackRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Submit feedback with attachments to Firebase
  Future<bool> submitFeedback(FeedbackModel feedback) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw ServerException('User must be authenticated to submit feedback');
      }

      // Add userId to feedback
      var feedbackWithUser = feedback.copyWithUserId(userId);

      // Upload attachments if any
      List<String> uploadedUrls = [];
      if (feedback.attachmentPaths.isNotEmpty) {
        uploadedUrls = await _uploadFiles(
          feedback.attachmentPaths,
          '$_feedbackStoragePath/$userId',
        );
        feedbackWithUser = feedbackWithUser.copyWithUrls(uploadedUrls);
      }

      // Submit to Firestore
      await _firestore.collection(_feedbackCollection).add(
            feedbackWithUser.toFirestore(),
          );

      debugPrint('Feedback submitted successfully to Firestore');
      return true;
    } catch (e) {
      debugPrint('Failed to submit feedback: $e');
      throw ServerException('Failed to submit feedback: $e');
    }
  }

  /// Submit collaboration with files to Firebase
  Future<bool> submitCollaboration(CollaborationModel collaboration) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw ServerException(
            'User must be authenticated to submit collaboration');
      }

      // Add userId to collaboration
      var collaborationWithUser = collaboration.copyWithUserId(userId);

      // Upload files if any
      List<String> uploadedUrls = [];
      if (collaboration.filePaths.isNotEmpty) {
        uploadedUrls = await _uploadFiles(
          collaboration.filePaths,
          '$_collaborateStoragePath/$userId',
        );
        collaborationWithUser = collaborationWithUser.copyWithUrls(uploadedUrls);
      }

      // Submit to Firestore
      await _firestore.collection(_collaborateCollection).add(
            collaborationWithUser.toFirestore(),
          );

      debugPrint('Collaboration submitted successfully to Firestore');
      return true;
    } catch (e) {
      debugPrint('Failed to submit collaboration: $e');
      throw ServerException('Failed to submit collaboration: $e');
    }
  }

  /// Upload files to Firebase Storage
  Future<List<String>> _uploadFiles(
      List<String> filePaths, String storagePath) async {
    final List<String> downloadUrls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < filePaths.length; i++) {
      final filePath = filePaths[i];
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('File not found: $filePath');
        continue;
      }

      // Create unique filename
      final fileName = filePath.split('/').last;
      final extension = fileName.contains('.') ? fileName.split('.').last : '';
      final uniqueName = '${timestamp}_${i}_$fileName';
      final ref = _storage.ref().child('$storagePath/$uniqueName');

      try {
        // Upload file
        final uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: _getContentType(extension),
            customMetadata: {
              'uploadedAt': DateTime.now().toIso8601String(),
              'originalName': fileName,
            },
          ),
        );

        // Wait for upload to complete
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);

        debugPrint('Uploaded file: $fileName -> $downloadUrl');
      } catch (e) {
        debugPrint('Failed to upload file $fileName: $e');
        // Continue with other files even if one fails
      }
    }

    return downloadUrls;
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }

  /// Validate file size and count for feedback attachments
  bool validateFeedbackAttachments(List<String> filePaths, List<int> fileSizes) {
    const maxFiles = 5;
    const maxFileSizeMB = 25;

    if (filePaths.length > maxFiles) return false;

    for (final size in fileSizes) {
      if (size > maxFileSizeMB * 1024 * 1024) return false;
    }

    return true;
  }

  /// Validate file size and count for collaboration attachments
  bool validateCollaborationAttachments(
      List<String> filePaths, List<int> fileSizes) {
    const maxFiles = 10;
    const maxFileSizeMB = 25;

    if (filePaths.length > maxFiles) return false;

    for (final size in fileSizes) {
      if (size > maxFileSizeMB * 1024 * 1024) return false;
    }

    return true;
  }
}
