import 'dart:math';

import 'package:flutter/material.dart' show Color, Material, showGeneralDialog;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/url_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/responsive/responsive.dart';

/// Breakthrough WebView screen (formerly Breakthrough.ai) - requires authentication
class BreakthroughWebViewScreen extends StatefulWidget {
  const BreakthroughWebViewScreen({super.key});

  @override
  State<BreakthroughWebViewScreen> createState() =>
      _BreakthroughWebViewScreenState();
}

class _BreakthroughWebViewScreenState extends State<BreakthroughWebViewScreen> {
  WebViewController? _controller;
  bool _isControllerInitialized = false;
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

  // JavaScript to inject dark mode CSS for email content pages
  // Based on Shadcn New York / Zinc Dark Palette
  static const String _darkModeEmailJs = '''
    (function() {
      const darkCSS = `
        /* Shadcn New York / Zinc Dark Palette */
        :root {
          --bg-background: #09090b;  /* Zinc 950 */
          --bg-card: #09090b;        /* Zinc 950 */
          --bg-popover: #09090b;     /* Zinc 950 */
          --text-primary: #fafafa;   /* Zinc 50 */
          --text-secondary: #a1a1aa; /* Zinc 400 */
          --text-muted: #71717a;     /* Zinc 500 */
          --border-zinc: #27272a;    /* Zinc 800 */
          --accent-orange: #f97316;  /* Orange 500 */
        }

        /* Base Backgrounds */
        body, table, td, .feedback-box { 
            background-color: var(--bg-background) !important; 
            color: var(--text-secondary) !important; 
            border-color: var(--border-zinc) !important; 
        }

        /* Text Color Resets */
        p, span, div, a, u, .h1, .p, td, tr { 
            color: var(--text-secondary) !important; 
            -webkit-text-fill-color: var(--text-secondary) !important;
        }

        /* Aggressive Targeting for Headings and Headlines - Pure Shadcn White */
        .h1, 
        td[class*="h1"], 
        td[style*="font-weight:bold"], 
        td[style*="font-weight: bold"], 
        p[style*="font-weight:bold"], 
        strong, b { 
            color: var(--text-primary) !important; 
            -webkit-text-fill-color: var(--text-primary) !important;
            letter-spacing: -0.025em !important; /* New York Style subtle tracking */
        }

        /* Target specifically the white content boxes - Zinc Surface */
        table[style*="background-color:#ffffff"], 
        table[style*="background-color: #ffffff"], 
        table[bgcolor="#ffffff"] { 
            background-color: var(--bg-card) !important; 
            border: 1px solid var(--border-zinc) !important; 
        }

        /* Maintain Greeting Block (Deepest Black) */
        table[style*="background-color:#000000"], 
        table[style*="background-color: #000000"], 
        table[bgcolor="#000000"] { 
            background-color: #000000 !important;
            border: 1px solid var(--border-zinc) !important;
        }

        /* Divider Lines - Thin Zinc 800 */
        td[style*="border-top"] { 
            border-color: var(--border-zinc) !important; 
        }

        /* Breakthrough Orange Accent */
        span[style*="color:#f74904"], 
        a[style*="color:#f74904"],
        td[style*="color:#f74904"],
        font[color="#f74904"] { 
            color: var(--accent-orange) !important;
            -webkit-text-fill-color: var(--accent-orange) !important;
        }

        /* Images and Icons - Modern Dimming */
        img { 
            border-color: var(--border-zinc) !important; 
            filter: grayscale(0.2) brightness(0.8) contrast(1.1);
            border-radius: 4px !important; 
        }

        /* Action Buttons - New York Black/White Style */
        .btn, td[bgcolor="#f74904"] { 
            background-color: var(--text-primary) !important; 
            border: 1px solid var(--text-primary) !important; 
        }
        .btn a, .btn span { 
            color: #000000 !important; 
            -webkit-text-fill-color: #000000 !important;
        }

        /* Metadata/Small Text - Muted Zinc */
        div[style*="color:#a1a1a1"], 
        td[style*="color:#999999"],
        td[style*="color:#a1a1a1"] { 
            color: var(--text-muted) !important; 
            -webkit-text-fill-color: var(--text-muted) !important;
        }

        /* Fix for nested link colors */
        a[style*="color:#000000"], a[style*="color: #000000"] {
            color: var(--text-primary) !important;
            -webkit-text-fill-color: var(--text-primary) !important;
            text-decoration-color: var(--border-zinc) !important;
        }
      `;
      
      function apply(doc) {
        if (!doc) return;
        const style = doc.createElement('style');
        style.id = 'vaultscapes-dark-mode-email';
        if (!doc.getElementById('vaultscapes-dark-mode-email')) {
          style.innerHTML = darkCSS;
          doc.head.appendChild(style);
        }
        
        /* Post-injection cleaning for elements with legacy MSO styles */
        doc.querySelectorAll('[style*="mso-color-alt"]').forEach(el => {
            el.style.setProperty('mso-color-alt', 'initial', 'important');
        });
      }
      
      /* Apply to main page */
      apply(document);

      /* Apply to all iframes (Newsletter container) */
      document.querySelectorAll('iframe').forEach(iframe => {
        try {
          const doc = iframe.contentDocument || iframe.contentWindow.document;
          apply(doc);
        } catch(e) {
          console.warn("VaultScapes Dark: Could not access iframe content due to cross-origin restrictions.");
        }
      });
      
      return 'dark mode email applied';
    })();
  ''';
  @override
  void initState() {
    super.initState();
    // Check auth state and initialize if authenticated
    _checkAndInitializeWebView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check when dependencies (like auth state) change
    _checkAndInitializeWebView();
  }

  /// Check auth state and initialize WebView if authenticated and not yet initialized
  void _checkAndInitializeWebView() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && !_isControllerInitialized) {
      _initWebView();
    }
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
    if (_isControllerInitialized) return; // Prevent re-initialization

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

            // Safety fallback: If progress reaches 100% but content isn't ready after 3s, force it
            if (progress >= 100 && !_isContentReady) {
              Future.delayed(const Duration(milliseconds: 3000), () {
                if (mounted && !_isContentReady) {
                  debugPrint(
                    'WebView: Forcing _isContentReady=true (progress fallback)',
                  );
                  setState(() {
                    _isContentReady = true;
                  });
                }
              });
            }
          },
          onPageStarted: (String url) {
            debugPrint('WebView onPageStarted: $url');
            if (!mounted) return;
            setState(() {
              _hasError = false;
              _isContentReady = false;
            });

            // Safety timeout: If page doesn't finish in 10s, show content anyway
            Future.delayed(const Duration(seconds: 10), () {
              if (mounted && !_isContentReady) {
                debugPrint(
                  'WebView: Forcing _isContentReady=true (10s timeout)',
                );
                setState(() {
                  _isContentReady = true;
                });
              }
            });
          },
          onPageFinished: (String url) async {
            debugPrint('WebView onPageFinished: $url');

            // Get theme before async operations
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            // Apply JavaScript to hide elements based on URL
            if (_isBreakthroughEmailPage(url)) {
              debugPrint('WebView: Running hide elements JS');
              try {
                await _controller!.runJavaScript(_hideEmailElementsJs);

                // Inject user's name and remove logo
                await _injectUserNameAndRemoveLogo();

                // Apply dark mode if device theme is dark
                if (isDarkMode) {
                  debugPrint('WebView: Applying dark mode for email content');
                  await _controller!.runJavaScript(_darkModeEmailJs);
                }
              } catch (e) {
                debugPrint('WebView: JS injection error (non-fatal): $e');
              }
            }

            // Add extra delay to ensure all injections are fully applied
            // But use a shorter delay for first load reliability
            await Future.delayed(const Duration(milliseconds: 800));

            if (!mounted) return;
            debugPrint('WebView: Setting _isContentReady = true');
            setState(() {
              _isContentReady = true;
            });

            // Update back navigation state
            try {
              final canGoBack = await _controller!.canGoBack();
              if (!mounted) return;
              setState(() {
                _canGoBack = canGoBack;
              });
            } catch (e) {
              debugPrint('WebView: canGoBack check error: $e');
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'WebView onWebResourceError: ${error.description}, isForMainFrame: ${error.isForMainFrame}',
            );

            // Only show error for main frame failures, ignore subresource errors
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _hasError = true;
                _isContentReady =
                    false; // Ensure loading overlay shows while error state renders
              });
            }
            // Ignore subresource errors (images, scripts, etc.) - they don't affect page usability
          },
        ),
      )
      ..loadRequest(Uri.parse(UrlConstants.breakthroughUrl));

    _isControllerInitialized = true;
    if (mounted) setState(() {});
  }

  /// Inject logged-in user's name and remove Breakthrough logo
  Future<void> _injectUserNameAndRemoveLogo() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userName = authProvider.user?.displayName ?? 'Reader';
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      final injectionJs =
          '''
        (function() {
          // Remove AlphaSignal/Breakthrough logo
          var logoSelectors = [
            'img[alt="Breakthrough Logo"]',
            'img[alt="AlphaSignal Logo"]',
            'img[src*="alphasignal.ai/image"]',
            'img[src*="1764279764256"]'
          ];
          
          logoSelectors.forEach(function(selector) {
            var logos = document.querySelectorAll(selector);
            logos.forEach(function(logo) {
              logo.style.display = 'none';
              // Also hide the divider/table after logo if exists
              var nextEl = logo.nextElementSibling;
              if (nextEl && (nextEl.tagName === 'TABLE' || nextEl.tagName === 'HR')) {
                nextEl.style.display = 'none';
              }
              // Hide parent cell/table if it only contains the logo
              var parent = logo.parentElement;
              if (parent && parent.children.length === 1) {
                parent.style.display = 'none';
              }
            });
          });
          
          // Try to access iframe and inject user name / remove logo
          var iframes = document.querySelectorAll('iframe');
          iframes.forEach(function(iframe) {
            try {
              var iframeDoc = iframe.contentDocument || (iframe.contentWindow && iframe.contentWindow.document);
              if (iframeDoc) {
                // Remove logo in iframe with multiple selectors
                logoSelectors.forEach(function(selector) {
                  var iframeLogos = iframeDoc.querySelectorAll(selector);
                  iframeLogos.forEach(function(logo) {
                    logo.style.display = 'none';
                    var nextEl = logo.nextElementSibling;
                    if (nextEl && (nextEl.tagName === 'TABLE' || nextEl.tagName === 'HR')) {
                      nextEl.style.display = 'none';
                    }
                    // Hide parent if only contains logo
                    var parent = logo.parentElement;
                    if (parent && parent.children.length === 1) {
                      parent.style.display = 'none';
                    }
                  });
                });
                
                // Also hide the white divider table after logo
                var dividerTables = iframeDoc.querySelectorAll('table[style*="margin:0 0 20px"]');
                dividerTables.forEach(function(table) {
                  var prevEl = table.previousElementSibling;
                  if (prevEl && prevEl.tagName === 'IMG') {
                    table.style.display = 'none';
                  }
                });
                
                // Inject user's name
                var greetings = iframeDoc.querySelectorAll('p, td, span');
                greetings.forEach(function(el) {
                  var text = el.textContent || '';
                  if (text.indexOf('{{FIRSTNAME}}') !== -1 || text.indexOf('Hey {{FIRSTNAME}}') !== -1) {
                    el.innerHTML = el.innerHTML.replace(/{{FIRSTNAME}}/g, '$userName');
                  }
                });
              }
            } catch (e) {
              console.log('VaultScapes: Cannot access iframe:', e);
            }
          });
          
          // Also try direct replacement in main document
          var mainGreetings = document.querySelectorAll('p, td, span');
          mainGreetings.forEach(function(el) {
            var text = el.textContent || '';
            if (text.indexOf('{{FIRSTNAME}}') !== -1) {
              el.innerHTML = el.innerHTML.replace(/{{FIRSTNAME}}/g, '$userName');
            }
          });
          
          return 'injection complete';
        })();
      ''';

      await _controller?.runJavaScript(injectionJs);

      // Retry after delays to catch dynamically loaded content
      // Also reapply dark mode if needed
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted && _controller != null) {
          await _controller!.runJavaScript(injectionJs);
          if (isDarkMode) {
            await _controller!.runJavaScript(_darkModeEmailJs);
          }
        }
      });
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (mounted && _controller != null) {
          await _controller!.runJavaScript(injectionJs);
          if (isDarkMode) {
            await _controller!.runJavaScript(_darkModeEmailJs);
          }
        }
      });
    } catch (e) {
      debugPrint('Error injecting user name: $e');
    }
  }

  /// Check if URL is a Breakthrough email page
  bool _isBreakthroughEmailPage(String url) {
    return url == 'https://alphasignal.ai/last-email' ||
        url.contains('alphasignal.ai/email/');
  }

  /// Navigate back in WebView history, or reset to default URL
  Future<bool> _handleBackNavigation() async {
    if (_controller == null) return false;
    if (await _controller!.canGoBack()) {
      await _controller!.goBack();
      // Update back state after navigation
      final canGoBack = await _controller!.canGoBack();
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
    if (!mounted || _controller == null) return;
    setState(() {
      _hasError = false;
      _loadingProgress = 0;
      _canGoBack = false;
      _isContentReady = false;
    });
    _controller!.loadRequest(Uri.parse(UrlConstants.breakthroughUrl));
  }

  /// Load a specific URL in the main webview
  void _loadUrl(String url) {
    if (!mounted || _controller == null) return;
    _setRandomLoadingText();
    setState(() {
      _hasError = false;
      _loadingProgress = 0;
      _isContentReady = false;
      _isNavigating = false;
    });
    _controller!.loadRequest(Uri.parse(url));
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
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
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

        // Initialize WebView if authenticated but not yet initialized
        // This handles the case when user signs in while on this screen
        if (!_isControllerInitialized) {
          // Schedule initialization for after this build frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isControllerInitialized) {
              _initWebView();
            }
          });
        }

        return PopScope(
          // Always prevent pop - we handle back navigation internally or let it exit app
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop) {
              // If webview can go back, navigate within webview
              if (_canGoBack) {
                await _handleBackNavigation();
              }
              // If webview can't go back, do nothing - we're at the root of this tab
              // The main navigation screen will handle exiting the app if needed
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

  /// Build authentication barrier widget with responsive layout
  Widget _buildAuthBarrier(BuildContext context, ThemeData theme) {
    return ResponsiveBuilder(
      builder: (context, windowSize) {
        // Responsive sizing based on viewport
        final isCompressed = windowSize.height < 480;
        final padding = windowSize.isMicro ? 24.0 : 32.0;
        final iconContainerSize = windowSize.isMicro ? 96.0 : 120.0;
        final iconSize = windowSize.isMicro ? 48.0 : 64.0;
        final titleFontSize = windowSize.isMicro ? 20.0 : 24.0;
        final descFontSize = windowSize.isMicro ? 14.0 : 16.0;
        final buttonHeight = windowSize.isMicro ? 44.0 : 48.0;
        
        return Scaffold(
          headers: [AppBar(title: const Text('Latest in AI'))],
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use scroll for compressed heights
                if (isCompressed) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildAuthBarrierContent(
                        theme,
                        iconContainerSize,
                        iconSize,
                        titleFontSize,
                        descFontSize,
                        buttonHeight,
                      ),
                    ),
                  );
                }
                
                // Center content for normal heights
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildAuthBarrierContent(
                        theme,
                        iconContainerSize,
                        iconSize,
                        titleFontSize,
                        descFontSize,
                        buttonHeight,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Build auth barrier content widgets (reusable for both layouts)
  List<Widget> _buildAuthBarrierContent(
    ThemeData theme,
    double iconContainerSize,
    double iconSize,
    double titleFontSize,
    double descFontSize,
    double buttonHeight,
  ) {
    return [
      // Lock icon
      Container(
        width: iconContainerSize,
        height: iconContainerSize,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.lock_outline,
          size: iconSize,
          color: theme.colorScheme.primary,
        ),
      ),
      const SizedBox(height: 24),
      // Title
      Text(
        'Exclusive Content',
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.foreground,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      // Description
      Text(
        'Sign in to access the latest AI briefings and archive. Stay ahead with daily curated AI news, models, papers, and repositories.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: descFontSize,
          color: theme.colorScheme.mutedForeground,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 32),
      // Sign in button
      SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: PrimaryButton(
          onPressed: () {
            // Navigate to profile tab to trigger auth
            // Or show auth dialog directly
            _showAuthPrompt(context);
          },
          child: const Text('Sign Up / Login to proceed'),
        ),
      ),
    ];
  }

  /// Show authentication prompt - navigates to welcome screen
  void _showAuthPrompt(BuildContext context) {
    context.go(RouteConstants.welcome);
  }

  Widget _buildWebView() {
    final theme = Theme.of(context);

    // Guard: if controller not initialized, show loading
    if (!_isControllerInitialized || _controller == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: TextStyle(color: theme.colorScheme.mutedForeground),
            ),
          ],
        ),
      );
    }

    debugPrint(
      'Building WebView: _isContentReady=$_isContentReady, _isNavigating=$_isNavigating',
    );

    return Stack(
      children: [
        // Only show WebView if no error, otherwise keep it hidden
        if (!_hasError)
          Positioned.fill(child: WebViewWidget(controller: _controller!)),
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 72,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: 24),
            Text(
              'Network Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load content. Please check your internet connection and try again.',
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlineButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  void _refresh() {
    if (!mounted || _controller == null) return;
    _setRandomLoadingText();
    setState(() {
      _hasError = false;
      _loadingProgress = 0;
      _isContentReady = false;
    });
    _controller!.reload();
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

  // JavaScript to inject light mode CSS when app is in light theme
  static const String _lightModeArchiveJs = '''
    (function() {
      const style = document.createElement('style');
      style.id = 'vaultscapes-light-mode';
      style.innerHTML = `
        body, .archive-page, #__next > div > div {
          background-color: #ffffff !important;
          color: #000000 !important;
        }
        header, footer {
          background-color: #ffffff !important;
          border-color: #e5e7eb !important;
        }
        h2, h3, h4, h5, p, span, a {
          color: #111827 !important;
        }
        svg path {
          fill: #000000 !important;
        }
        div[class*="hover:bg-gray-50/5"]:hover {
          background-color: rgba(0,0,0,0.05) !important;
        }
        .text-gray-500 {
          color: #6b7280 !important;
        }
        button {
          color: #000000 !important;
          border-color: #000000 !important;
        }
      `;
      if (!document.getElementById('vaultscapes-light-mode')) {
        document.head.appendChild(style);
      }
      return 'light mode applied';
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
            // Get theme before async operations to avoid context warning
            final isLightMode =
                Theme.of(context).brightness == Brightness.light;

            await _archiveController.runJavaScript(
              _ArchiveDialogState._hideArchiveElementsJs,
            );

            // Apply light mode if app is in light theme
            if (isLightMode) {
              await _archiveController.runJavaScript(
                _ArchiveDialogState._lightModeArchiveJs,
              );
            }

            await _archiveController.runJavaScript(_linkInterceptorJs);
            await Future.delayed(const Duration(milliseconds: 300));

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'Archive WebView error: ${error.description}, isForMainFrame: ${error.isForMainFrame}',
            );

            // Only show error for main frame failures
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _hasNetworkError = true;
                _isLoading = false;
              });
            }
            // Ignore subresource errors
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
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 300) {
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
                            child: WebViewWidget(
                              controller: _archiveController,
                            ),
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
                                        color:
                                            theme.colorScheme.mutedForeground,
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
                                        _archiveController.loadRequest(
                                          Uri.parse(_archiveUrl),
                                        );
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
                                        color:
                                            theme.colorScheme.mutedForeground,
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
