import 'dart:math';

import 'package:flutter/material.dart' show Color, Dialog;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../widgets/common/error_widget.dart';
import '../../../core/constants/url_constants.dart';

/// AlphaSignal WebView screen (Breakthrough)
class AlphaSignalWebViewScreen extends StatefulWidget {
  const AlphaSignalWebViewScreen({super.key});

  @override
  State<AlphaSignalWebViewScreen> createState() =>
      _AlphaSignalWebViewScreenState();
}

class _AlphaSignalWebViewScreenState extends State<AlphaSignalWebViewScreen> {
  late WebViewController _controller;
  bool _hasError = false;
  double _loadingProgress = 0;
  bool _canGoBack = false;
  bool _isContentReady = false;
  bool _isNavigating = false;
  String _loadingText = 'Updated daily except weekends';

  // Random loading messages
  static const List<String> _loadingMessages = [
    'Updated daily except weekends',
    'Our algos spent the night splitting signal from noise',
    'Your AI Briefing will be ready soon',
    'Stay Ahead of the Curve with Vaultscapes',
    'You can finally take a break from AI firehose',
    'Fetching Top News, Models, Papers and Repos',
  ];

  // JavaScript to hide unwanted elements from the email pages
  // FIRST PRINCIPLES: Ensure content is visible, then hide unwanted elements
  static const String _hideEmailElementsJs = '''
    (function() {
      console.log('VaultScapes: === EMAIL PAGE PROCESSOR START ===');
      console.log('VaultScapes: URL = ' + window.location.href);
      
      // STEP 1: Force page-level visibility (fixes Next.js/SSR issues)
      function forcePageVisibility() {
        // Force document and body to be visible
        document.documentElement.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; background-color: white !important;';
        document.body.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; background-color: white !important; min-height: 100vh !important;';
        
        // Force #__next (Next.js root) to be visible
        var nextRoot = document.getElementById('__next');
        if (nextRoot) {
          nextRoot.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important;';
          console.log('VaultScapes: #__next found and made visible');
        }
        
        // Force main content areas
        var mainAreas = document.querySelectorAll('main, .container, [class*="content"], [class*="email"]');
        mainAreas.forEach(function(el) {
          el.style.setProperty('display', 'block', 'important');
          el.style.setProperty('visibility', 'visible', 'important');
          el.style.setProperty('opacity', '1', 'important');
        });
        
        // Remove any loading overlays or skeleton screens
        var overlays = document.querySelectorAll('[class*="loading"], [class*="skeleton"], [class*="spinner"], [class*="overlay"]');
        overlays.forEach(function(el) {
          el.style.setProperty('display', 'none', 'important');
        });
        
        console.log('VaultScapes: Page visibility forced');
      }
      
      // STEP 2: Process iframe (where email content lives)
      function processIframe(iframe) {
        if (!iframe) return;
        
        console.log('VaultScapes: Processing iframe');
        
        // Make iframe container visible and full-width
        iframe.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; width: 100% !important; min-height: 80vh !important; height: auto !important; border: none !important; background: white !important;';
        
        // Make all parent containers visible
        var parent = iframe.parentElement;
        var depth = 0;
        while (parent && parent !== document.body && depth < 20) {
          parent.style.setProperty('display', 'block', 'important');
          parent.style.setProperty('visibility', 'visible', 'important');
          parent.style.setProperty('opacity', '1', 'important');
          parent.style.setProperty('overflow', 'visible', 'important');
          parent = parent.parentElement;
          depth++;
        }
        
        // Try to access iframe content
        try {
          var iframeDoc = iframe.contentDocument || (iframe.contentWindow && iframe.contentWindow.document);
          if (iframeDoc && iframeDoc.body) {
            console.log('VaultScapes: Iframe body accessible');
            
            // Force iframe body visibility with white background for readability
            iframeDoc.documentElement.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; background: white !important;';
            iframeDoc.body.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; background: white !important; color: #222 !important;';
            
            // Hide unwanted elements
            hideUnwantedElements(iframeDoc);
            
            console.log('VaultScapes: Iframe content height = ' + iframeDoc.body.scrollHeight);
          }
        } catch (e) {
          console.log('VaultScapes: Iframe access error: ' + e.message);
        }
      }
      
      // STEP 3: Hide unwanted elements (promotional/footer content)
      // CRITICAL: Only hide SMALL tables to avoid hiding main content
      function hideUnwantedElements(doc) {
        if (!doc) return;
        
        var hiddenCount = 0;
        var totalBodyHeight = doc.body ? doc.body.scrollHeight : 1000;
        
        // CSS injection for known classes only
        var style = doc.createElement('style');
        style.id = 'vaultscapes-hide';
        style.textContent = '.menu-bar { display: none !important; }';
        if (!doc.getElementById('vaultscapes-hide') && doc.head) {
          doc.head.appendChild(style);
        }
        
        // Find tables - but ONLY hide small ones that match patterns
        var tables = doc.querySelectorAll('table');
        tables.forEach(function(table) {
          var tableHeight = table.offsetHeight || 0;
          var tableText = (table.textContent || '').toLowerCase();
          var textLength = tableText.length;
          
          // SKIP large tables - they likely contain main content
          // If table is more than 30% of body height, don't hide it
          if (tableHeight > totalBodyHeight * 0.3) {
            return;
          }
          
          // SKIP tables with lots of text (likely main content)
          if (textLength > 2000) {
            return;
          }
          
          var shouldHide = false;
          
          // Pattern 1: Menu bar (header with social links)
          if (table.querySelector('.menu-bar') || 
              (tableText.indexOf('signup') !== -1 && tableText.indexOf('follow on x') !== -1)) {
            shouldHide = true;
          }
          
          // Pattern 2: Author section (small promotional block)
          if (tableText.indexOf("today's author") !== -1 && textLength < 500) {
            shouldHide = true;
          }
          
          // Pattern 3: Rating section (feedback buttons)
          if (tableText.indexOf("how was today") !== -1 && textLength < 300) {
            shouldHide = true;
          }
          
          // Pattern 4: Footer with unsubscribe (ONLY if small)
          if (tableText.indexOf('214 barton springs') !== -1 && textLength < 800) {
            shouldHide = true;
          }
          
          // Pattern 5: Promotion section
          if (tableText.indexOf('looking to promote') !== -1 && textLength < 500) {
            shouldHide = true;
          }
          
          if (shouldHide) {
            table.style.cssText = 'display: none !important;';
            hiddenCount++;
            console.log('VaultScapes: Hiding table with ' + textLength + ' chars, height ' + tableHeight);
          }
        });
        
        console.log('VaultScapes: Hidden ' + hiddenCount + ' unwanted elements (total body height: ' + totalBodyHeight + ')');
      }
      
      // MAIN: Execute processor
      function runProcessor() {
        console.log('VaultScapes: Running processor...');
        
        // Step 1: Force page visibility
        forcePageVisibility();
        
        // Step 2: Find and process all iframes
        var iframes = document.querySelectorAll('iframe');
        console.log('VaultScapes: Found ' + iframes.length + ' iframes');
        
        if (iframes.length === 0) {
          // No iframes yet, content might be loading
          console.log('VaultScapes: No iframes found, page might still be loading');
        }
        
        iframes.forEach(function(iframe) {
          processIframe(iframe);
          
          // Also set up load handler for future loads
          iframe.addEventListener('load', function() {
            console.log('VaultScapes: Iframe load event fired');
            processIframe(iframe);
          });
        });
        
        // Also process document directly (in case no iframe)
        hideUnwantedElements(document);
        
        // Log final state
        console.log('VaultScapes: Body dimensions = ' + document.body.offsetWidth + 'x' + document.body.offsetHeight);
        console.log('VaultScapes: Body computed style = display:' + getComputedStyle(document.body).display + ', visibility:' + getComputedStyle(document.body).visibility + ', opacity:' + getComputedStyle(document.body).opacity);
      }
      
      // Execute immediately
      runProcessor();
      
      // Retry to catch dynamically loaded content
      [100, 300, 600, 1000, 2000, 3500].forEach(function(delay) {
        setTimeout(runProcessor, delay);
      });
      
      // Watch for new iframes being added
      var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          mutation.addedNodes.forEach(function(node) {
            if (node.tagName === 'IFRAME') {
              console.log('VaultScapes: New iframe detected');
              setTimeout(function() { processIframe(node); }, 100);
            }
          });
        });
        // Also run full processor for any DOM changes
        runProcessor();
      });
      
      observer.observe(document.body, { childList: true, subtree: true });
      setTimeout(function() { observer.disconnect(); }, 10000);
      
      console.log('VaultScapes: === PROCESSOR INITIALIZED ===');
      return 'ok';
    })();
  ''';
  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    // Cancel any pending operations
    super.dispose();
  }

  /// Set a random loading message (only if mounted)
  void _setRandomLoadingText() {
    if (!mounted) return;
    final random = Random();
    setState(() {
      _loadingText = _loadingMessages[random.nextInt(_loadingMessages.length)];
    });
  }

  void _initWebView() {
    _setRandomLoadingText();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF)) // Set white background
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            debugPrint('WebView onPageStarted: $url');
            if (!mounted) return;
            setState(() {
              _hasError = false;
              _isContentReady = false;
            });
          },
          onPageFinished: (String url) async {
            debugPrint('WebView onPageFinished: $url');

            // Apply JavaScript to hide elements based on URL
            if (_isAlphaSignalEmailPage(url)) {
              debugPrint('WebView: Running hide elements JS');
              await _controller.runJavaScript(_hideEmailElementsJs);
            }

            // Small delay to ensure JS execution completes
            await Future.delayed(const Duration(milliseconds: 500));

            if (!mounted) return;
            debugPrint('WebView: Setting _isContentReady = true');
            setState(() {
              _isContentReady = true;
            });

            // Update back navigation state
            final canGoBack = await _controller.canGoBack();
            if (!mounted) return;
            setState(() {
              _canGoBack = canGoBack;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView onWebResourceError: ${error.description}');
            if (!mounted) return;
            setState(() {
              _hasError = true;
              _isContentReady = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(UrlConstants.alphaSignalUrl));
  }

  /// Check if URL is an AlphaSignal email page
  bool _isAlphaSignalEmailPage(String url) {
    return url == 'https://alphasignal.ai/last-email' ||
        url.contains('alphasignal.ai/email/');
  }

  /// Navigate back in WebView history, or reset to default URL
  Future<bool> _handleBackNavigation() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      // Update back state after navigation
      final canGoBack = await _controller.canGoBack();
      if (!mounted) return true;
      setState(() {
        _canGoBack = canGoBack;
      });
      return true;
    }
    return false; // Allow app to handle back navigation
  }

  /// Reset WebView to the default URL
  void _resetToDefaultUrl() {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _loadingProgress = 0;
      _canGoBack = false;
      _isContentReady = false;
    });
    _controller.loadRequest(Uri.parse(UrlConstants.alphaSignalUrl));
  }

  /// Load a specific URL in the main webview
  void _loadUrl(String url) {
    if (!mounted) return;
    _setRandomLoadingText();
    setState(() {
      _hasError = false;
      _loadingProgress = 0;
      _isContentReady = false;
      _isNavigating = false;
    });
    _controller.loadRequest(Uri.parse(url));
  }

  /// Show archive dialog/sheet
  void _showArchiveSheet() {
    bool hasHandledSelection = false; // Local debounce flag

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _ArchiveDialog(
        onEmailSelected: (url) {
          // Debounce: ignore duplicate calls
          if (hasHandledSelection) return;
          hasHandledSelection = true;

          // Check if parent widget is still mounted
          if (!mounted) return;

          // Set navigating state before closing
          setState(() {
            _isNavigating = true;
            _isContentReady = false;
          });
          _setRandomLoadingText();

          // Close dialog first, then load URL
          Navigator.of(dialogContext).pop();

          // Use post-frame callback to ensure dialog is closed before loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadUrl(url);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackNavigation();
        }
      },
      child: Scaffold(
        headers: [
          AppBar(
            leading: [
              if (_canGoBack)
                IconButton.ghost(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBackNavigation,
                ),
            ],
            title: const Text('Latest in AI'),
            trailing: [
              IconButton.ghost(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
              ),
              IconButton.ghost(
                icon: const Icon(Icons.home),
                onPressed: _resetToDefaultUrl,
              ),
            ],
          ),
        ],
        child: Stack(
          children: [
            Column(
              children: [
                // Content
                Expanded(
                  child: _hasError ? _buildErrorState() : _buildWebView(),
                ),
              ],
            ),
            // Archive FAB
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showArchiveSheet,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.archive_outlined,
                  color: theme.colorScheme.primaryForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    final theme = Theme.of(context);

    debugPrint(
      'Building WebView: _isContentReady=$_isContentReady, _isNavigating=$_isNavigating',
    );

    return Stack(
      children: [
        // Always show the WebView, don't hide it
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        // Show loading overlay until content is ready
        if (!_isContentReady || _isNavigating)
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _loadingProgress > 0 ? _loadingProgress : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadingText,
                      style: TextStyle(
                        color: theme.colorScheme.mutedForeground,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return AppErrorWidget.network(onRetry: _refresh);
  }

  void _refresh() {
    if (!mounted) return;
    _setRandomLoadingText();
    setState(() {
      _hasError = false;
      _loadingProgress = 0;
      _isContentReady = false;
    });
    _controller.reload();
  }
}

/// Floating Action Button widget
class FloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Widget child;

  const FloatingActionButton({
    super.key,
    required this.onPressed,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Archive Dialog with WebView
class _ArchiveDialog extends StatefulWidget {
  final Function(String url) onEmailSelected;

  const _ArchiveDialog({required this.onEmailSelected});

  @override
  State<_ArchiveDialog> createState() => _ArchiveDialogState();
}

class _ArchiveDialogState extends State<_ArchiveDialog> {
  late WebViewController _archiveController;
  bool _isLoading = true;
  double _loadingProgress = 0;
  String _archiveLoadingText = 'Loading archive...';
  bool _isHandlingEmailSelection = false; // Debounce flag

  static const String _archiveUrl = 'https://alphasignal.ai/archive';

  // Random loading messages for archive
  static const List<String> _archiveLoadingMessages = [
    'Loading archive...',
    'Fetching past editions...',
    'Getting the AI briefing collection...',
  ];

  // JavaScript to hide archive page header and footer
  // Archive page has direct DOM access (not iframe)
  static const String _hideArchiveElementsJs = '''
    (function() {
      // Inject CSS for immediate hiding of header and footer
      var style = document.createElement('style');
      style.id = 'vaultscapes-archive-hide-style';
      style.textContent = `
        header { display: none !important; visibility: hidden !important; height: 0 !important; overflow: hidden !important; }
        footer { display: none !important; visibility: hidden !important; height: 0 !important; overflow: hidden !important; }
        .backdrop-blur-sm { display: none !important; }
      `;
      if (!document.getElementById('vaultscapes-archive-hide-style')) {
        document.head.appendChild(style);
      }
      
      // Also remove elements from DOM
      function hideArchiveElements() {
        var header = document.querySelector('header');
        if (header) {
          header.style.setProperty('display', 'none', 'important');
        }
        
        var footers = document.querySelectorAll('footer');
        footers.forEach(function(footer) {
          footer.style.setProperty('display', 'none', 'important');
        });
        
        // Adjust body styling
        document.body.style.paddingTop = '0px';
        document.body.style.marginTop = '0px';
      }
      
      hideArchiveElements();
      setTimeout(hideArchiveElements, 100);
      setTimeout(hideArchiveElements, 300);
      setTimeout(hideArchiveElements, 500);
      
      return 'archive hiding complete';
    })();
  ''';

  // JavaScript to intercept all link clicks in archive page
  // CRITICAL: Archive page has relative URLs like /email/{id}
  // We need to detect these and convert to full URLs
  static const String _linkInterceptorJs = '''
    (function() {
      // Remove any existing listeners and debounce state
      if (window._vaultscapesLinkHandler) {
        document.removeEventListener('click', window._vaultscapesLinkHandler, true);
      }
      if (window._vaultscapesTouchHandler) {
        document.removeEventListener('touchend', window._vaultscapesTouchHandler, true);
      }
      
      // Debounce flag to prevent multiple messages
      window._vaultscapesLinkSent = false;
      
      // Function to handle link interception
      function handleLink(e, target) {
        // If already sent a message, ignore
        if (window._vaultscapesLinkSent) return false;
        
        var url = target.href;
        var pathname = target.pathname || '';
        
        // Check if this is an email link
        if (pathname.indexOf('/email/') !== -1 || 
            pathname === '/last-email' ||
            url.indexOf('alphasignal.ai/email/') !== -1 || 
            url.indexOf('alphasignal.ai/last-email') !== -1) {
          
          e.preventDefault();
          e.stopPropagation();
          e.stopImmediatePropagation();
          
          // Mark as sent immediately
          window._vaultscapesLinkSent = true;
          
          // Ensure we have full URL
          var fullUrl = url;
          if (!url.startsWith('http')) {
            fullUrl = 'https://alphasignal.ai' + pathname;
          }
          
          console.log('LinkHandler intercepted:', fullUrl);
          
          // Send URL to Flutter
          if (window.LinkHandler) {
            LinkHandler.postMessage(fullUrl);
          }
          return true;
        }
        return false;
      }
      
      // Define click handler
      window._vaultscapesLinkHandler = function(e) {
        var target = e.target;
        while (target && target.tagName !== 'A') {
          target = target.parentElement;
        }
        if (target && target.href) {
          handleLink(e, target);
        }
      };
      
      // Define touch handler (separate to avoid conflicts)
      window._vaultscapesTouchHandler = function(e) {
        // Skip if click handler already processed
        if (window._vaultscapesLinkSent) return;
        
        var target = e.target;
        while (target && target.tagName !== 'A') {
          target = target.parentElement;
        }
        if (target && target.href) {
          handleLink(e, target);
        }
      };
      
      // Add click listener (captures before default)
      document.addEventListener('click', window._vaultscapesLinkHandler, true);
      
      // Add touchend listener for mobile
      document.addEventListener('touchend', window._vaultscapesTouchHandler, true);
      
      return 'link interceptor installed for archive';
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _setRandomArchiveLoadingText();
    _initArchiveWebView();
  }

  void _setRandomArchiveLoadingText() {
    final random = Random();
    setState(() {
      _archiveLoadingText =
          _archiveLoadingMessages[random.nextInt(
            _archiveLoadingMessages.length,
          )];
    });
  }

  void _initArchiveWebView() {
    _archiveController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Add JavaScript channel to receive link clicks
      ..addJavaScriptChannel(
        'LinkHandler',
        onMessageReceived: (JavaScriptMessage message) {
          // Debounce: ignore if already handling
          if (_isHandlingEmailSelection) return;

          final url = message.message;
          debugPrint('LinkHandler received: $url');
          // Check if this is an email URL
          if (url.contains('alphasignal.ai/email/') ||
              url.contains('alphasignal.ai/last-email')) {
            // Mark as handling immediately
            _isHandlingEmailSelection = true;

            // Show loading immediately
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
            // Call the callback to load in main webview
            widget.onEmailSelected(url);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            // Apply JavaScript to hide header and footer
            await _archiveController.runJavaScript(_hideArchiveElementsJs);

            // Inject link interceptor
            await _archiveController.runJavaScript(_linkInterceptorJs);

            // Small delay to ensure JS execution completes
            await Future.delayed(const Duration(milliseconds: 300));

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Debounce: ignore if already handling
            if (_isHandlingEmailSelection) return NavigationDecision.prevent;

            final url = request.url;
            debugPrint('Archive onNavigationRequest: $url');

            // Check if this is an email link
            // Archive page may use relative URLs that get resolved to full URLs
            if (url.contains('alphasignal.ai/email/') ||
                url.contains('alphasignal.ai/last-email') ||
                url.contains('/email/')) {
              // Mark as handling immediately
              _isHandlingEmailSelection = true;

              // Show loading state immediately
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }

              // Ensure full URL
              String fullUrl = url;
              if (!url.startsWith('http')) {
                fullUrl = 'https://alphasignal.ai$url';
              }

              // Call the callback
              // Schedule callback after current frame to avoid navigation lock
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onEmailSelected(fullUrl);
              });
              return NavigationDecision.prevent;
            }

            // Allow navigation within archive page only
            if (url.contains('alphasignal.ai/archive') || url == _archiveUrl) {
              return NavigationDecision.navigate;
            }

            // Prevent all other navigation
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_archiveUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: screenWidth - 16,
          height: screenHeight * 0.75,
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Select Article from Archive',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                    ),
                    IconButton.ghost(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Loading indicator or WebView
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        WebViewWidget(controller: _archiveController),
                        if (_isLoading)
                          Container(
                            color: theme.colorScheme.background,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 200,
                                    child: LinearProgressIndicator(
                                      value: _loadingProgress > 0
                                          ? _loadingProgress
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _archiveLoadingText,
                                    style: TextStyle(
                                      color: theme.colorScheme.mutedForeground,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
