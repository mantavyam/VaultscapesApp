import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/webview_wrapper.dart';
import '../../services/url_service.dart';
import '../../providers/user_provider.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Get feedback URL, potentially with user email pre-filled
        final feedbackUrl = userProvider.isAuthenticated
            ? UrlService.getFeedbackUrlWithUserData(
                email: userProvider.currentUser?.email,
              )
            : UrlService.getFeedbackUrl();

        return WebViewWrapper(
          url: feedbackUrl,
          showAppBar: false, // No app bar for main navigation screens
          enablePullToRefresh: true,
          enableJavaScript: true,
        );
      },
    );
  }
}