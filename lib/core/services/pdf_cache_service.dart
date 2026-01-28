import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Custom cache manager for PDF files with configurable limits
/// - Max cache size: 100MB
/// - Max cache age: 7 days
/// - Max number of cached PDFs: 50
class PdfCacheService {
  static const String _cacheKey = 'vaultscapes_pdf_cache';
  
  // Cache configuration
  static const int maxCacheSizeBytes = 100 * 1024 * 1024; // 100MB
  static const Duration maxCacheAge = Duration(days: 7);
  static const int maxNrOfCacheObjects = 50;

  static PdfCacheService? _instance;
  static PdfCacheService get instance => _instance ??= PdfCacheService._();
  
  PdfCacheService._();

  /// Custom cache manager with PDF-specific settings
  late final CacheManager _cacheManager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: maxCacheAge,
      maxNrOfCacheObjects: maxNrOfCacheObjects,
      repo: JsonCacheInfoRepository(databaseName: _cacheKey),
      fileService: HttpFileService(),
    ),
  );

  /// Get PDF file from cache or download if not cached
  /// Returns the cached File object
  Future<File> getPdfFile(
    String url, {
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Check if file is already cached
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        debugPrint('PDF loaded from cache: $url');
        return fileInfo.file;
      }

      // Download and cache the file
      debugPrint('Downloading PDF: $url');
      final file = await _cacheManager.getSingleFile(
        url,
        headers: headers ?? {'User-Agent': 'Mozilla/5.0 (compatible; Vaultscapes/1.0)'},
      );
      
      debugPrint('PDF cached successfully: $url');
      return file;
    } catch (e) {
      debugPrint('Error getting PDF file: $e');
      rethrow;
    }
  }

  /// Download PDF with progress tracking
  /// Returns bytes directly for pdfx compatibility
  Future<Uint8List> downloadPdfWithProgress(
    String url, {
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // First check cache
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        debugPrint('PDF loaded from cache: $url');
        onProgress?.call(1.0);
        return await fileInfo.file.readAsBytes();
      }

      // Download with progress using stream
      debugPrint('Downloading PDF: $url');
      final stream = _cacheManager.getFileStream(
        url,
        headers: headers ?? {'User-Agent': 'Mozilla/5.0 (compatible; Vaultscapes/1.0)'},
        withProgress: true,
      );

      File? cachedFile;
      await for (final result in stream) {
        if (result is DownloadProgress) {
          final progress = result.totalSize != null && result.totalSize! > 0
              ? result.downloaded / result.totalSize!
              : 0.0;
          onProgress?.call(progress);
        } else if (result is FileInfo) {
          cachedFile = result.file;
        }
      }

      if (cachedFile != null) {
        debugPrint('PDF cached successfully: $url');
        onProgress?.call(1.0);
        return await cachedFile.readAsBytes();
      }

      throw Exception('Failed to download and cache PDF');
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      rethrow;
    }
  }

  /// Check if a PDF is cached
  Future<bool> isCached(String url) async {
    final fileInfo = await _cacheManager.getFileFromCache(url);
    return fileInfo != null;
  }

  /// Remove a specific PDF from cache
  Future<void> removeFromCache(String url) async {
    await _cacheManager.removeFile(url);
    debugPrint('PDF removed from cache: $url');
  }

  /// Clear all cached PDFs
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
    debugPrint('PDF cache cleared');
  }

  /// Get current cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final pdfCacheDir = Directory('${cacheDir.path}/libCachedImageData/$_cacheKey');
      
      if (!await pdfCacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in pdfCacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }

  /// Get human-readable cache size string
  Future<String> getFormattedCacheSize() async {
    final sizeBytes = await getCacheSize();
    
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Get number of cached PDFs
  Future<int> getCachedFileCount() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final pdfCacheDir = Directory('${cacheDir.path}/libCachedImageData/$_cacheKey');
      
      if (!await pdfCacheDir.exists()) {
        return 0;
      }

      int count = 0;
      await for (final entity in pdfCacheDir.list()) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          count++;
        }
      }
      // Also count files without extension (cache manager doesn't always preserve extension)
      await for (final entity in pdfCacheDir.list()) {
        if (entity is File && !entity.path.endsWith('.pdf')) {
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('Error getting cached file count: $e');
      return 0;
    }
  }
}
