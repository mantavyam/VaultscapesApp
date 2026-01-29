import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../../core/error/exceptions.dart';

/// Service for GitHub OAuth using manual Authorization Code Flow
/// Uses url_launcher + app_links for more reliable deep link handling
/// This avoids flutter_appauth state management issues on Android
class GitHubOAuthService {
  // GitHub OAuth configuration loaded from .env file
  // IMPORTANT: In GitHub OAuth App settings, set Authorization callback URL to:
  // com.mantavyam.vaultscapes://oauth-callback
  String get _clientId => dotenv.env['GITHUB_CLIENT_ID'] ?? '';
  String get _clientSecret => dotenv.env['GITHUB_CLIENT_SECRET'] ?? '';
  static const String _redirectUrl = 'com.mantavyam.vaultscapes://oauth-callback';
  static const String _authorizationEndpoint = 'https://github.com/login/oauth/authorize';
  static const String _tokenEndpoint = 'https://github.com/login/oauth/access_token';
  static const List<String> _scopes = ['user:email', 'read:user'];
  
  // Store state for CSRF protection
  String? _pendingState;
  Completer<String>? _authCompleter;
  StreamSubscription? _linkSubscription;

  GitHubOAuthService();

  /// Generate a random state string for CSRF protection
  String _generateState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// Perform GitHub OAuth authorization and return access token
  Future<String> authorizeAndGetToken() async {
    try {
      debugPrint('GitHubOAuth: Starting manual authorization flow...');
      
      // Cancel any existing auth flow
      await _cancelPendingAuth();
      
      // Generate state for CSRF protection
      _pendingState = _generateState();
      _authCompleter = Completer<String>();
      
      // Build authorization URL
      final authUrl = Uri.parse(_authorizationEndpoint).replace(
        queryParameters: {
          'client_id': _clientId,
          'redirect_uri': _redirectUrl,
          'scope': _scopes.join(' '),
          'state': _pendingState!,
          'response_type': 'code',
        },
      );
      
      debugPrint('GitHubOAuth: Authorization URL: $authUrl');
      
      // Set up deep link listener BEFORE launching browser
      final appLinks = AppLinks();
      _linkSubscription = appLinks.uriLinkStream.listen((Uri uri) {
        debugPrint('GitHubOAuth: Received deep link: $uri');
        _handleDeepLink(uri);
      });
      
      // Launch browser for authorization
      if (!await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      )) {
        throw AuthException('Could not launch authorization URL');
      }
      
      debugPrint('GitHubOAuth: Browser launched, waiting for callback...');
      
      // Wait for the deep link callback with timeout
      final code = await _authCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw AuthException('Authorization timed out');
        },
      );
      
      debugPrint('GitHubOAuth: Received authorization code, exchanging for token...');
      
      // Exchange code for token
      final accessToken = await _exchangeCodeForToken(code);
      
      debugPrint('GitHubOAuth: Successfully obtained access token');
      return accessToken;
    } catch (e) {
      debugPrint('GitHubOAuth: Error during authorization: $e');
      await _cancelPendingAuth();
      if (e is AuthException) rethrow;
      throw AuthException('GitHub authorization failed: $e');
    }
  }
  
  /// Handle incoming deep link from OAuth callback
  void _handleDeepLink(Uri uri) {
    debugPrint('GitHubOAuth: Processing deep link: $uri');
    
    // Check if this is our OAuth callback
    if (uri.scheme != 'com.mantavyam.vaultscapes' || uri.host != 'oauth-callback') {
      debugPrint('GitHubOAuth: Not an OAuth callback, ignoring');
      return;
    }
    
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];
    final errorDescription = uri.queryParameters['error_description'];
    
    debugPrint('GitHubOAuth: code=$code, state=$state, error=$error');
    
    // Verify state for CSRF protection
    if (state != _pendingState) {
      _authCompleter?.completeError(
        AuthException('Invalid state parameter - possible CSRF attack'),
      );
      return;
    }
    
    if (error != null) {
      _authCompleter?.completeError(
        AuthException('GitHub authorization denied: $errorDescription'),
      );
      return;
    }
    
    if (code == null) {
      _authCompleter?.completeError(
        AuthException('No authorization code received'),
      );
      return;
    }
    
    // Complete with the authorization code
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete(code);
    }
    
    // Clean up
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
  
  /// Exchange authorization code for access token
  Future<String> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'redirect_uri': _redirectUrl,
      },
    );
    
    debugPrint('GitHubOAuth: Token exchange response status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      throw AuthException('Failed to exchange code for token: ${response.body}');
    }
    
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (data.containsKey('error')) {
      throw AuthException('Token exchange error: ${data['error_description'] ?? data['error']}');
    }
    
    final accessToken = data['access_token'] as String?;
    if (accessToken == null) {
      throw AuthException('No access token in response');
    }
    
    return accessToken;
  }
  
  /// Cancel any pending authorization flow
  Future<void> _cancelPendingAuth() async {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.completeError(AuthException('Authorization cancelled'));
    }
    _authCompleter = null;
    _pendingState = null;
  }
}
