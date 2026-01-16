import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/webview_wrapper.dart';
import '../../services/url_service.dart';
import '../../providers/user_provider.dart';

class CollaborateScreen extends StatelessWidget {
  const CollaborateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Get collaborate URL, potentially with user email pre-filled
        final collaborateUrl = userProvider.isAuthenticated
            ? UrlService.getCollaborateUrlWithUserData(
                email: userProvider.currentUser?.email,
              )
            : UrlService.getCollaborateUrl();

        return WebViewWrapper(
          url: collaborateUrl,
          showAppBar: false, // No app bar for main navigation screens
          enablePullToRefresh: true,
          enableJavaScript: true,
        );
      },
    );
  }
}