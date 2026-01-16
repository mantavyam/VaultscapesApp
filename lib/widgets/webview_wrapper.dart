import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/constants/app_constants.dart';

class WebViewWrapper extends StatefulWidget {
  final String url;
  final bool showAppBar;
  final String? title;
  final bool enablePullToRefresh;
  final bool enableJavaScript;
  final Function(String)? onPageStarted;
  final Function(String)? onPageFinished;
  final Function(String)? onNavigationRequest;

  const WebViewWrapper({
    super.key,
    required this.url,
    this.showAppBar = true,
    this.title,
    this.enablePullToRefresh = true,
    this.enableJavaScript = true,
    this.onPageStarted,
    this.onPageFinished,
    this.onNavigationRequest,
  });

  @override
  State<WebViewWrapper> createState() => _WebViewWrapperState();
}

class _WebViewWrapperState extends State<WebViewWrapper> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(widget.enableJavaScript 
          ? JavaScriptMode.unrestricted 
          : JavaScriptMode.disabled)
      ..setUserAgent('VaultScapes Mobile App')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _loadingProgress = 0.0;
            });
            widget.onPageStarted?.call(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            widget.onPageFinished?.call(url);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            widget.onNavigationRequest?.call(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(widget.title ?? 'VaultScapes'),
              bottom: _isLoading
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(AppSizes.progressIndicatorHeight),
                      child: LinearProgressIndicator(
                        value: _loadingProgress,
                      ),
                    )
                  : null,
            )
          : null,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      onRefresh: widget.enablePullToRefresh ? _refreshWebView : () async {},
      child: WebViewWidget(controller: _controller),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load content',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tap to retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshWebView() async {
    await _controller.reload();
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  // Public methods for external control
  Future<void> reload() async {
    await _controller.reload();
  }

  Future<bool> canGoBack() async {
    return await _controller.canGoBack();
  }

  Future<bool> canGoForward() async {
    return await _controller.canGoForward();
  }

  Future<void> goBack() async {
    if (await canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> goForward() async {
    if (await canGoForward()) {
      await _controller.goForward();
    }
  }

  Future<void> evaluateJavascript(String javascriptString) async {
    await _controller.runJavaScript(javascriptString);
  }

  Future<void> loadUrl(String url) async {
    await _controller.loadRequest(Uri.parse(url));
  }
}