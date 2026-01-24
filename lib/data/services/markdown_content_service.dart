import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

/// Service for fetching and caching Gitbook markdown content
class MarkdownContentService {
  static const String _cacheBoxName = 'markdown_cache';
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const String _logName = 'MarkdownContentService';

  Box<String>? _cacheBox;

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _logName,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  Future<void> init() async {
    _log('Initializing cache box: $_cacheBoxName');
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      _cacheBox = await Hive.openBox<String>(_cacheBoxName);
      _log('Opened new cache box');
    } else {
      _cacheBox = Hive.box<String>(_cacheBoxName);
      _log('Using existing cache box');
    }
  }

  /// Fetches markdown content from a Gitbook URL
  /// The URL should be in format: https://mantavyam.gitbook.io/vaultscapes/...
  /// We append .md to get raw markdown
  Future<MarkdownFetchResult> fetchContent(String gitbookUrl) async {
    _log('=== FETCH CONTENT START ===');
    _log('Requested URL: $gitbookUrl');

    try {
      // Check cache first
      _log('Checking cache...');
      final cached = await _getCachedContent(gitbookUrl);
      if (cached != null) {
        _log('Cache HIT - returning cached content (${cached.length} chars)');
        return MarkdownFetchResult.success(cached, fromCache: true);
      }
      _log('Cache MISS - fetching from network');

      // Construct the raw markdown URL
      // Gitbook provides raw markdown at URL + .md extension
      final markdownUrl = '$gitbookUrl.md';
      _log('Markdown URL: $markdownUrl');

      _log('Making HTTP GET request...');
      final response = await http
          .get(
            Uri.parse(markdownUrl),
            headers: {
              'Accept': 'text/markdown, text/plain, */*',
              'User-Agent': 'Vaultscapes-App/1.0',
            },
          )
          .timeout(const Duration(seconds: 30));

      _log('Response status code: ${response.statusCode}');
      _log('Response content-type: ${response.headers['content-type']}');
      _log('Response body length: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        _log('Decoded content length: ${content.length} chars');
        _log(
          'Content preview (first 500 chars): ${content.substring(0, content.length > 500 ? 500 : content.length)}',
        );

        // Cache the content
        _log('Caching content...');
        await _cacheContent(gitbookUrl, content);
        _log('Content cached successfully');

        _log('=== FETCH CONTENT SUCCESS ===');
        return MarkdownFetchResult.success(content);
      } else if (response.statusCode == 404) {
        _log('ERROR: Content not found (404)');
        return MarkdownFetchResult.error(
          'Content not found',
          errorType: MarkdownErrorType.notFound,
        );
      } else {
        _log('ERROR: Server error (${response.statusCode})');
        _log('Response body: ${response.body}');
        return MarkdownFetchResult.error(
          'Server error: ${response.statusCode}',
          errorType: MarkdownErrorType.serverError,
        );
      }
    } on http.ClientException catch (e, stackTrace) {
      _log('ERROR: Network error', error: e, stackTrace: stackTrace);
      return MarkdownFetchResult.error(
        'Network error: ${e.message}',
        errorType: MarkdownErrorType.networkError,
      );
    } catch (e, stackTrace) {
      _log('ERROR: Unexpected error', error: e, stackTrace: stackTrace);
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

  factory MarkdownFetchResult.success(
    String content, {
    bool fromCache = false,
  }) {
    return MarkdownFetchResult._(
      isSuccess: true,
      content: content,
      fromCache: fromCache,
    );
  }

  factory MarkdownFetchResult.error(
    String message, {
    MarkdownErrorType? errorType,
  }) {
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
