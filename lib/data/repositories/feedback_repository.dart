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
      List<String> uploadedNames = [];
      if (feedback.attachmentPaths.isNotEmpty) {
        final uploadResult = await _uploadFilesWithNames(
          feedback.attachmentPaths,
          '$_feedbackStoragePath/$userId',
        );
        uploadedUrls = uploadResult['urls'] as List<String>;
        uploadedNames = uploadResult['names'] as List<String>;
        feedbackWithUser = feedbackWithUser.copyWithUrls(uploadedUrls, uploadedNames);
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
      List<String> uploadedNames = [];
      if (collaboration.filePaths.isNotEmpty) {
        final uploadResult = await _uploadFilesWithNames(
          collaboration.filePaths,
          '$_collaborateStoragePath/$userId',
        );
        uploadedUrls = uploadResult['urls'] as List<String>;
        uploadedNames = uploadResult['names'] as List<String>;
        collaborationWithUser = collaborationWithUser.copyWithUrls(uploadedUrls, uploadedNames);
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

  /// Upload files to Firebase Storage and return both URLs and original filenames
  Future<Map<String, List<String>>> _uploadFilesWithNames(
      List<String> filePaths, String storagePath) async {
    final List<String> downloadUrls = [];
    final List<String> fileNames = [];
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
        fileNames.add(fileName);

        debugPrint('Uploaded file: $fileName -> $downloadUrl');
      } catch (e) {
        debugPrint('Failed to upload file $fileName: $e');
        // Continue with other files even if one fails
      }
    }

    return {
      'urls': downloadUrls,
      'names': fileNames,
    };
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      
      // Text files
      case 'txt':
        return 'text/plain';
      case 'md':
      case 'markdown':
        return 'text/markdown';
      case 'rtf':
        return 'application/rtf';
      
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      
      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
        return 'application/gzip';
      
      // Code files
      case 'py':
        return 'text/x-python';
      case 'java':
        return 'text/x-java-source';
      case 'cpp':
      case 'cc':
      case 'cxx':
        return 'text/x-c++src';
      case 'c':
        return 'text/x-csrc';
      case 'h':
      case 'hpp':
        return 'text/x-c++hdr';
      case 'js':
        return 'application/javascript';
      case 'ts':
        return 'application/typescript';
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'yaml':
      case 'yml':
        return 'application/x-yaml';
      case 'sh':
        return 'application/x-sh';
      case 'sql':
        return 'application/sql';
      case 'r':
        return 'text/x-r';
      case 'm':
        return 'text/x-matlab';
      case 'dart':
        return 'application/dart';
      case 'go':
        return 'text/x-go';
      case 'rs':
        return 'text/x-rust';
      case 'swift':
        return 'text/x-swift';
      case 'kt':
      case 'kts':
        return 'text/x-kotlin';
      case 'php':
        return 'application/x-httpd-php';
      case 'rb':
        return 'text/x-ruby';
      
      // Other academic formats
      case 'csv':
        return 'text/csv';
      case 'odt':
        return 'application/vnd.oasis.opendocument.text';
      case 'ods':
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case 'odp':
        return 'application/vnd.oasis.opendocument.presentation';
      
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

  /// Check if user can submit feedback (rate limiting - 5 per day IST)
  Future<bool> canSubmitFeedback() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      final count = await getTodayFeedbackCount();
      return count < 5;
    } catch (e) {
      debugPrint('Error checking feedback rate limit: $e');
      return true; // Allow submission if check fails
    }
  }

  /// Get today's feedback count for current user (IST timezone)
  Future<int> getTodayFeedbackCount() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return 0;

      // Get current time in IST (UTC+5:30)
      final nowUtc = DateTime.now().toUtc();
      final nowIST = nowUtc.add(const Duration(hours: 5, minutes: 30));
      final startOfDayIST = DateTime(nowIST.year, nowIST.month, nowIST.day);

      // Fetch all user's feedback and filter client-side
      final snapshot = await _firestore
          .collection(_feedbackCollection)
          .where('userId', isEqualTo: userId)
          .get();

      // Filter by date client-side
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final submittedAtStr = data['submittedAt'] as String?;
        if (submittedAtStr != null) {
          try {
            final submittedAt = DateTime.parse(submittedAtStr);
            final submittedIST = submittedAt.toUtc().add(const Duration(hours: 5, minutes: 30));
            
            // Check if submission was today in IST
            if (submittedIST.year == startOfDayIST.year &&
                submittedIST.month == startOfDayIST.month &&
                submittedIST.day == startOfDayIST.day) {
              count++;
            }
          } catch (e) {
            debugPrint('Error parsing date: $e');
          }
        }
      }

      debugPrint('Feedback count for today (IST): $count');
      return count;
    } catch (e) {
      debugPrint('Error getting feedback count: $e');
      return 0;
    }
  }

  /// Check if user can submit collaboration (rate limiting - 5 per day IST)
  Future<bool> canSubmitCollaboration() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      final count = await getTodayCollaborationCount();
      return count < 5;
    } catch (e) {
      debugPrint('Error checking collaboration rate limit: $e');
      return true; // Allow submission if check fails
    }
  }

  /// Get today's collaboration count for current user (IST timezone)
  Future<int> getTodayCollaborationCount() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return 0;

      // Get current time in IST (UTC+5:30)
      final nowUtc = DateTime.now().toUtc();
      final nowIST = nowUtc.add(const Duration(hours: 5, minutes: 30));
      final startOfDayIST = DateTime(nowIST.year, nowIST.month, nowIST.day);

      // Fetch all user's collaborations and filter client-side
      final snapshot = await _firestore
          .collection(_collaborateCollection)
          .where('userId', isEqualTo: userId)
          .get();

      // Filter by date client-side
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final submittedAtStr = data['submittedAt'] as String?;
        if (submittedAtStr != null) {
          try {
            final submittedAt = DateTime.parse(submittedAtStr);
            final submittedIST = submittedAt.toUtc().add(const Duration(hours: 5, minutes: 30));
            
            // Check if submission was today in IST
            if (submittedIST.year == startOfDayIST.year &&
                submittedIST.month == startOfDayIST.month &&
                submittedIST.day == startOfDayIST.day) {
              count++;
            }
          } catch (e) {
            debugPrint('Error parsing date: $e');
          }
        }
      }

      debugPrint('Collaboration count for today (IST): $count');
      return count;
    } catch (e) {
      debugPrint('Error getting collaboration count: $e');
      return 0;
    }
  }
}
