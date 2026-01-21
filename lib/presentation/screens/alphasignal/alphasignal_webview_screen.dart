import 'dart:math';

import 'package:flutter/material.dart' show Color, Material, showGeneralDialog;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../../core/constants/url_constants.dart';

/// AlphaSignal WebView screen (Breakthrough) - requires authentication
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
  // FIRST PRINCIPLES: Hide page chrome, maximize iframe, hide unwanted iframe content
  static const String _hideEmailElementsJs = '''
    (function() {
      console.log('VaultScapes: === EMAIL PAGE PROCESSOR START ===');
      console.log('VaultScapes: URL = ' + window.location.href);
      
      // STEP 1: Hide page-level elements (header, back link, title, footer)
      // These are OUTSIDE the iframe and should be completely removed
      function hidePageChrome() {
        // Inject CSS to hide page chrome immediately
        var style = document.createElement('style');
        style.id = 'vaultscapes-page-hide';
        style.textContent = `
          /* Hide header with Advertise button */
          header { display: none !important; }
          
          /* Hide footer elements */
          footer { display: none !important; }
          
          /* Hide back link and heading (title + timestamp) */
          .container > a[href="/archive"],
          .container > a[href*="archive"],
          .heading,
          .container > .heading { display: none !important; }
          
          /* Make iframe container take full height */
          .my-5, .my-5 > div {
            margin: 0 !important;
            padding: 0 !important;
            min-height: 100vh !important;
          }
          
          /* Make container full width and no margins */
          .container {
            max-width: 100% !important;
            padding: 0 !important;
            margin: 0 !important;
            margin-bottom: 0 !important;
          }
          
          /* Hide archive-page specific elements */
          .archive-page > header,
          .archive-page footer { display: none !important; }
          
          /* Ensure #__next takes full space */
          #__next, #__next > div, .min-h-screen {
            min-height: 100vh !important;
          }
          
          /* Remove body padding/margin */
          body {
            padding: 0 !important;
            margin: 0 !important;
            background: white !important;
          }
        `;
        if (!document.getElementById('vaultscapes-page-hide')) {
          document.head.appendChild(style);
        }
        
        // Also directly hide elements
        var elementsToHide = [
          'header',
          'footer',
          '.heading',
          'a[href="/archive"]',
          'a[href*="archive"]:not(iframe *)'
        ];
        
        elementsToHide.forEach(function(selector) {
          var elements = document.querySelectorAll(selector);
          elements.forEach(function(el) {
            // Don't hide elements inside iframe
            if (!el.closest('iframe')) {
              el.style.setProperty('display', 'none', 'important');
            }
          });
        });
        
        console.log('VaultScapes: Page chrome hidden');
      }
      
      // STEP 2: Process iframe (maximize and clean content)
      function processIframe(iframe) {
        if (!iframe) return;
        
        console.log('VaultScapes: Processing iframe');
        
        // Make iframe full-screen
        iframe.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; width: 100% !important; min-height: 100vh !important; height: auto !important; border: none !important; background: white !important; margin: 0 !important; padding: 0 !important;';
        
        // Make all parent containers visible and full-height
        var parent = iframe.parentElement;
        var depth = 0;
        while (parent && parent !== document.body && depth < 20) {
          parent.style.setProperty('display', 'block', 'important');
          parent.style.setProperty('visibility', 'visible', 'important');
          parent.style.setProperty('opacity', '1', 'important');
          parent.style.setProperty('overflow', 'visible', 'important');
          parent.style.setProperty('min-height', '100vh', 'important');
          parent.style.setProperty('margin', '0', 'important');
          parent.style.setProperty('padding', '0', 'important');
          parent = parent.parentElement;
          depth++;
        }
        
        // Try to access and clean iframe content
        try {
          var iframeDoc = iframe.contentDocument || (iframe.contentWindow && iframe.contentWindow.document);
          if (iframeDoc && iframeDoc.body) {
            console.log('VaultScapes: Iframe body accessible');
            
            // Force iframe body visibility
            iframeDoc.documentElement.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; background: white !important;';
            iframeDoc.body.style.cssText = 'display: block !important; visibility: visible !important; opacity: 1 !important; background: white !important; color: #222 !important;';
            
            // Hide unwanted elements inside iframe
            hideUnwantedElements(iframeDoc);
            
            console.log('VaultScapes: Iframe content height = ' + iframeDoc.body.scrollHeight);
          }
        } catch (e) {
          console.log('VaultScapes: Iframe access error: ' + e.message);
        }
      }
      
      // STEP 3: Hide unwanted elements inside iframe (promotional/footer content)
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
          
          // SKIP large tables - they contain main content
          if (tableHeight > totalBodyHeight * 0.3) return;
          if (textLength > 2000) return;
          
          var shouldHide = false;
          
          // Pattern 1: Menu bar (header with social links)
          if (table.querySelector('.menu-bar') || 
              (tableText.indexOf('signup') !== -1 && tableText.indexOf('follow on x') !== -1)) {
            shouldHide = true;
          }
          
          // Pattern 2: Author section
          if (tableText.indexOf("today's author") !== -1 && textLength < 500) {
            shouldHide = true;
          }
          
          // Pattern 3: Rating section
          if (tableText.indexOf("how was today") !== -1 && textLength < 300) {
            shouldHide = true;
          }
          
          // Pattern 4: Footer with address (ONLY if small)
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
            console.log('VaultScapes: Hiding table with ' + textLength + ' chars');
          }
        });
        
        console.log('VaultScapes: Hidden ' + hiddenCount + ' unwanted elements');
      }
      
      // MAIN: Execute processor
      function runProcessor() {
        console.log('VaultScapes: Running processor...');
        
        // Step 1: Hide page chrome
        hidePageChrome();
        
        // Step 2: Find and process all iframes
        var iframes = document.querySelectorAll('iframe');
        console.log('VaultScapes: Found ' + iframes.length + ' iframes');
        
        iframes.forEach(function(iframe) {
          processIframe(iframe);
          
          iframe.addEventListener('load', function() {
            console.log('VaultScapes: Iframe load event fired');
            processIframe(iframe);
          });
        });
        
        // Log final state
        console.log('VaultScapes: Body dimensions = ' + document.body.offsetWidth + 'x' + document.body.offsetHeight);
      }
      
      // Execute immediately and retry
      runProcessor();
      [100, 300, 600, 1000, 2000, 3500].forEach(function(delay) {
        setTimeout(runProcessor, delay);
      });
      
      // Watch for new iframes
      var observer = new MutationObserver(function() { runProcessor(); });
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

  /// Show archive dialog (styled like bottom sheet for scroll support)
  void _showArchiveSheet() {
    bool hasHandledSelection = false; // Local debounce flag

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Archive',
      barrierColor: const Color(0x8A000000), // Black with 54% opacity
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _ArchiveDialog(
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
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Slide up from bottom animation
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show auth barrier if not authenticated
        if (!authProvider.isAuthenticated) {
          return _buildAuthBarrier(context, theme);
        }

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
      },
    );
  }

  /// Build authentication barrier widget
  Widget _buildAuthBarrier(BuildContext context, ThemeData theme) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Latest in AI'),
        ),
      ],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Exclusive Content',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.foreground,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'Sign in to access the latest AI briefings and archive. Stay ahead with daily curated AI news, models, papers, and repositories.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 32),
              // Sign in button
              PrimaryButton(
                onPressed: () {
                  // Navigate to profile tab to trigger auth
                  // Or show auth dialog directly
                  _showAuthPrompt(context);
                },
                child: const Text('Sign Up / Login to proceed'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show authentication prompt
  void _showAuthPrompt(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    authProvider.signInWithGoogle();
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

/// Archive Dialog (styled like bottom sheet but with proper scroll support)
class _ArchiveDialog extends StatefulWidget {
  final Function(String url) onEmailSelected;

  const _ArchiveDialog({required this.onEmailSelected});

  @override
  State<_ArchiveDialog> createState() => _ArchiveDialogState();
}

class _ArchiveDialogState extends State<_ArchiveDialog> {
  late WebViewController _archiveController;
  bool _isLoading = true;
  bool _hasNetworkError = false;
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

  // JavaScript to hide archive page header and footer, and fix scroll
  static const String _hideArchiveElementsJs = '''
    (function() {
      // Inject CSS for immediate hiding and scroll fix
      var style = document.createElement('style');
      style.id = 'vaultscapes-archive-hide-style';
      style.textContent = `
        header { display: none !important; visibility: hidden !important; height: 0 !important; overflow: hidden !important; }
        footer { display: none !important; visibility: hidden !important; height: 0 !important; overflow: hidden !important; }
        .backdrop-blur-sm { display: none !important; }
        
        /* Enable smooth scrolling */
        html, body {
          overflow-y: auto !important;
          -webkit-overflow-scrolling: touch !important;
          touch-action: pan-y !important;
        }
        
        /* Adjust container for better scrolling */
        .container {
          padding-top: 10px !important;
          margin-top: 0 !important;
        }
      `;
      if (!document.getElementById('vaultscapes-archive-hide-style')) {
        document.head.appendChild(style);
      }
      
      // Remove elements from DOM
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
        document.body.style.overflow = 'auto';
        document.body.style.touchAction = 'pan-y';
      }
      
      hideArchiveElements();
      setTimeout(hideArchiveElements, 100);
      setTimeout(hideArchiveElements, 300);
      setTimeout(hideArchiveElements, 500);
      
      return 'archive hiding complete';
    })();
  ''';

  // JavaScript to intercept link clicks - prevents default and sends to Flutter
  static const String _linkInterceptorJs = '''
    (function() {
      // Remove any existing listeners
      if (window._vaultscapesLinkHandler) {
        document.removeEventListener('click', window._vaultscapesLinkHandler, true);
      }
      
      // Debounce flag
      window._vaultscapesLinkSent = false;
      
      // Handle link interception
      function handleLink(e, target) {
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
          
          window._vaultscapesLinkSent = true;
          
          var fullUrl = url;
          if (!url.startsWith('http')) {
            fullUrl = 'https://alphasignal.ai' + pathname;
          }
          
          console.log('LinkHandler intercepted:', fullUrl);
          
          if (window.LinkHandler) {
            LinkHandler.postMessage(fullUrl);
          }
          return true;
        }
        return false;
      }
      
      // Click handler
      window._vaultscapesLinkHandler = function(e) {
        var target = e.target;
        while (target && target.tagName !== 'A') {
          target = target.parentElement;
        }
        if (target && target.href) {
          handleLink(e, target);
        }
      };
      
      document.addEventListener('click', window._vaultscapesLinkHandler, true);
      
      return 'link interceptor installed';
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
      ..addJavaScriptChannel(
        'LinkHandler',
        onMessageReceived: (JavaScriptMessage message) {
          if (_isHandlingEmailSelection) return;

          final url = message.message;
          debugPrint('LinkHandler received: $url');

          if (url.contains('alphasignal.ai/email/') ||
              url.contains('alphasignal.ai/last-email')) {
            _isHandlingEmailSelection = true;

            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
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
                _hasNetworkError = false;
              });
            }
          },
          onPageFinished: (String url) async {
            await _archiveController.runJavaScript(_hideArchiveElementsJs);
            await _archiveController.runJavaScript(_linkInterceptorJs);
            await Future.delayed(const Duration(milliseconds: 300));

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Archive WebView error: ${error.description}');
            if (mounted) {
              setState(() {
                _hasNetworkError = true;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_isHandlingEmailSelection) return NavigationDecision.prevent;

            final url = request.url;
            debugPrint('Archive onNavigationRequest: $url');

            if (url.contains('alphasignal.ai/email/') ||
                url.contains('alphasignal.ai/last-email') ||
                url.contains('/email/')) {
              _isHandlingEmailSelection = true;

              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }

              String fullUrl = url;
              if (!url.startsWith('http')) {
                fullUrl = 'https://alphasignal.ai$url';
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onEmailSelected(fullUrl);
              });
              return NavigationDecision.prevent;
            }

            if (url.contains('alphasignal.ai/archive') || url == _archiveUrl) {
              return NavigationDecision.navigate;
            }

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

    // Dialog positioned at bottom half of screen, full width
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: screenHeight * 0.5, // Half screen height
          width: screenWidth, // Full width
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle with gesture support
              GestureDetector(
                onVerticalDragEnd: (details) {
                  // Close dialog if dragged down with sufficient velocity
                  if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.muted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // Content area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // WebView with full sizing
                        if (!_hasNetworkError)
                          SizedBox.expand(
                            child: WebViewWidget(controller: _archiveController),
                          ),
                        // Network error state
                        if (_hasNetworkError)
                          Positioned.fill(
                            child: Container(
                              color: theme.colorScheme.background,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wifi_off_rounded,
                                      size: 64,
                                      color: theme.colorScheme.mutedForeground,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Network Error',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.foreground,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Unable to load archive. Please check your internet connection.',
                                      style: TextStyle(
                                        color: theme.colorScheme.mutedForeground,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    OutlineButton(
                                      onPressed: () {
                                        setState(() {
                                          _hasNetworkError = false;
                                          _isLoading = true;
                                          _loadingProgress = 0;
                                        });
                                        _archiveController.loadRequest(Uri.parse(_archiveUrl));
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Loading state
                        if (_isLoading && !_hasNetworkError)
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
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
