import 'package:flutter/material.dart';

import '../../widgets/webview_wrapper.dart';
import '../../services/url_service.dart';

class WebViewScreen extends StatelessWidget {
  final String linkType;

  const WebViewScreen({super.key, required this.linkType});

  @override
  Widget build(BuildContext context) {
    final url = UrlService.getWebViewUrl(linkType);
    final title = UrlService.getWebViewTitle(linkType);

    return WebViewWrapper(
      url: url,
      title: title,
      showAppBar: true,
      enablePullToRefresh: true,
      enableJavaScript: true,
    );
  }
}