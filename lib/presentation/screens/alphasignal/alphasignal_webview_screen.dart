import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../../core/constants/url_constants.dart';

/// AlphaSignal WebView screen
class AlphaSignalWebViewScreen extends StatefulWidget {
  const AlphaSignalWebViewScreen({super.key});

  @override
  State<AlphaSignalWebViewScreen> createState() =>
      _AlphaSignalWebViewScreenState();
}

class _AlphaSignalWebViewScreenState extends State<AlphaSignalWebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  double _loadingProgress = 0;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            // Update back navigation state
            final canGoBack = await _controller.canGoBack();
            setState(() {
              _canGoBack = canGoBack;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(UrlConstants.alphaSignalUrl));
  }

  /// Navigate back in WebView history, or reset to default URL
  Future<bool> _handleBackNavigation() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      // Update back state after navigation
      final canGoBack = await _controller.canGoBack();
      setState(() {
        _canGoBack = canGoBack;
      });
      return true;
    }
    return false; // Allow app to handle back navigation
  }

  /// Reset WebView to the default URL
  void _resetToDefaultUrl() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadingProgress = 0;
      _canGoBack = false;
    });
    _controller.loadRequest(Uri.parse(UrlConstants.alphaSignalUrl));
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            // Loading Progress Bar
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadingProgress,
              ),
            // Content
            Expanded(
              child: _hasError ? _buildErrorState() : _buildWebView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading && _loadingProgress < 0.3)
          Container(
            color: Theme.of(context).colorScheme.background,
            child: const LoadingIndicator(message: 'Loading content...'),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return AppErrorWidget.network(
      onRetry: _refresh,
    );
  }

  void _refresh() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadingProgress = 0;
    });
    _controller.reload();
  }
}
