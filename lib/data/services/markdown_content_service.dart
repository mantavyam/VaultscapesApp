import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

/// Service for fetching and caching Gitbook markdown content
class MarkdownContentService {
  static const String _cacheBoxName = 'markdown_cache';
  static const Duration _cacheExpiry = Duration(hours: 24);
  
  Box<String>? _cacheBox;
  
  Future<void> init() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    } else {
      _cacheBox = Hive.box<String>(_cacheBoxName);
    }
  }
  
  /// Fetches markdown content from a Gitbook URL
  /// The URL should be in format: https://mantavyam.gitbook.io/vaultscapes/...
  /// We append .md to get raw markdown
  Future<MarkdownFetchResult> fetchContent(String gitbookUrl) async {
    try {
      // Check cache first
      final cached = await _getCachedContent(gitbookUrl);
      if (cached != null) {
        return MarkdownFetchResult.success(cached, fromCache: true);
      }
      
      // Construct the raw markdown URL
      // Gitbook provides raw markdown at URL + .md extension
      final markdownUrl = '$gitbookUrl.md';
      
      final response = await http.get(
        Uri.parse(markdownUrl),
        headers: {
          'Accept': 'text/markdown, text/plain, */*',
          'User-Agent': 'Vaultscapes-App/1.0',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        
        // Cache the content
        await _cacheContent(gitbookUrl, content);
        
        return MarkdownFetchResult.success(content);
      } else if (response.statusCode == 404) {
        return MarkdownFetchResult.error(
          'Content not found',
          errorType: MarkdownErrorType.notFound,
        );
      } else {
        return MarkdownFetchResult.error(
          'Server error: ${response.statusCode}',
          errorType: MarkdownErrorType.serverError,
        );
      }
    } on http.ClientException catch (e) {
      return MarkdownFetchResult.error(
        'Network error: ${e.message}',
        errorType: MarkdownErrorType.networkError,
      );
    } catch (e) {
      return MarkdownFetchResult.error(
        'Failed to load content: $e',
        errorType: MarkdownErrorType.unknown,
      );
    }
  }
  
  /// Cache markdown content with timestamp
  Future<void> _cacheContent(String url, String content) async {
    if (_cacheBox == null) await init();
    
    final cacheData = jsonEncode({
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    await _cacheBox?.put(_getCacheKey(url), cacheData);
  }
  
  /// Get cached content if not expired
  Future<String?> _getCachedContent(String url) async {
    if (_cacheBox == null) await init();
    
    final cacheData = _cacheBox?.get(_getCacheKey(url));
    if (cacheData == null) return null;
    
    try {
      final data = jsonDecode(cacheData) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      // Check if cache is expired
      if (DateTime.now().difference(cachedTime) > _cacheExpiry) {
        await _cacheBox?.delete(_getCacheKey(url));
        return null;
      }
      
      return data['content'] as String;
    } catch (_) {
      return null;
    }
  }
  
  String _getCacheKey(String url) {
    return url.hashCode.toString();
  }
  
  /// Clear all cached content
  Future<void> clearCache() async {
    if (_cacheBox == null) await init();
    await _cacheBox?.clear();
  }
  
  /// Clear specific cached content
  Future<void> clearCacheFor(String url) async {
    if (_cacheBox == null) await init();
    await _cacheBox?.delete(_getCacheKey(url));
  }
}

/// Result of a markdown fetch operation
class MarkdownFetchResult {
  final bool isSuccess;
  final String? content;
  final String? errorMessage;
  final MarkdownErrorType? errorType;
  final bool fromCache;
  
  MarkdownFetchResult._({
    required this.isSuccess,
    this.content,
    this.errorMessage,
    this.errorType,
    this.fromCache = false,
  });
  
  factory MarkdownFetchResult.success(String content, {bool fromCache = false}) {
    return MarkdownFetchResult._(
      isSuccess: true,
      content: content,
      fromCache: fromCache,
    );
  }
  
  factory MarkdownFetchResult.error(String message, {MarkdownErrorType? errorType}) {
    return MarkdownFetchResult._(
      isSuccess: false,
      errorMessage: message,
      errorType: errorType ?? MarkdownErrorType.unknown,
    );
  }
}

enum MarkdownErrorType {
  networkError,
  serverError,
  notFound,
  parseError,
  unknown,
}
