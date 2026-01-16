import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/webview_wrapper.dart';
import '../../providers/preferences_provider.dart';
import '../../services/url_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesProvider>(
      builder: (context, preferencesProvider, child) {
        // Get home URL based on semester preference
        final homeUrl = UrlService.getHomeUrl(
          semesterPreference: preferencesProvider.semesterPreference,
        );

        return WebViewWrapper(
          url: homeUrl,
          showAppBar: false, // No app bar for main navigation screens
          enablePullToRefresh: true,
          enableJavaScript: true,
          onPageStarted: (url) {
            // Update last active timestamp when user starts browsing
            preferencesProvider.updateLastActive();
          },
        );
      },
    );
  }
}