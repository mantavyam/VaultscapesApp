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
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('AlphaSignal.AI'),
          trailing: [
            IconButton.ghost(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
            IconButton.ghost(
              icon: const Icon(Icons.open_in_browser),
              onPressed: _openInBrowser,
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

  void _openInBrowser() {
    // Use url_launcher to open in external browser
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            title: const Text('Opening in browser...'),
            leading: const Icon(Icons.open_in_browser),
            trailing: IconButton.ghost(
              icon: const Icon(Icons.close),
              onPressed: () => overlay.close(),
            ),
          ),
        );
      },
      location: ToastLocation.bottomCenter,
    );
  }
}
