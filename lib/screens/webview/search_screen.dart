import 'package:flutter/material.dart';

import '../../widgets/webview_wrapper.dart';
import '../../services/url_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late WebViewWrapper _webViewWrapper;

  @override
  Widget build(BuildContext context) {
    _webViewWrapper = WebViewWrapper(
      url: UrlService.getSearchUrl(),
      title: 'Search Database',
      showAppBar: true,
      enablePullToRefresh: true,
      enableJavaScript: true,
      onPageFinished: (url) {
        // Auto-focus search input after page loads
        _focusSearchInput();
      },
    );

    return _webViewWrapper;
  }

  void _focusSearchInput() {
    // JavaScript to focus the search input field on GitBook
    // This will attempt to focus the search input and trigger keyboard
    final focusScript = '''
      (function() {
        // Common selectors for GitBook search input
        var selectors = [
          'input[type="search"]',
          'input[placeholder*="search" i]',
          'input[placeholder*="Search" i]',
          '.search-input',
          '[data-testid="search-input"]',
          'input[aria-label*="search" i]'
        ];
        
        for (var i = 0; i < selectors.length; i++) {
          var input = document.querySelector(selectors[i]);
          if (input) {
            input.focus();
            input.click();
            return;
          }
        }
        
        // Fallback: try to find any input that might be the search
        var inputs = document.querySelectorAll('input[type="text"], input:not([type])');
        for (var i = 0; i < inputs.length; i++) {
          var input = inputs[i];
          var placeholder = input.getAttribute('placeholder') || '';
          var ariaLabel = input.getAttribute('aria-label') || '';
          if (placeholder.toLowerCase().includes('search') || 
              ariaLabel.toLowerCase().includes('search')) {
            input.focus();
            input.click();
            return;
          }
        }
      })();
    ''';

    // Delay to ensure page is fully loaded
    Future.delayed(const Duration(milliseconds: 1500), () {
      try {
        // Note: We'll need to access the WebViewController from WebViewWrapper
        // For now, this shows the intent - the actual implementation would require
        // exposing the controller or adding a method to WebViewWrapper
      } catch (e) {
        // Ignore errors - search focus is a nice-to-have feature
      }
    });
  }
}