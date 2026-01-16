import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../services/url_service.dart';

class QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final QuickLinkType linkType;
  final VoidCallback? onTap;

  const QuickLinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.linkType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: AppSizes.iconMedium,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: AppSizes.iconMedium,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap ?? () => _handleDefaultTap(context),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
    );
  }

  void _handleDefaultTap(BuildContext context) {
    // Special handling for search (goes to dedicated search screen)
    if (linkType == QuickLinkType.searchDatabase) {
      context.push('/search');
    } else {
      // All other links go to generic webview screen
      final linkTypeString = _getLinkTypeString();
      context.push('/webview/$linkTypeString');
    }
  }

  String _getLinkTypeString() {
    switch (linkType) {
      case QuickLinkType.searchDatabase:
        return 'search-database';
      case QuickLinkType.githubRepository:
        return 'github-repository';
      case QuickLinkType.discordCommunity:
        return 'discord-community';
      case QuickLinkType.howToUseDatabase:
        return 'how-to-use-database';
      case QuickLinkType.howToCollaborate:
        return 'how-to-collaborate';
      case QuickLinkType.collaborators:
        return 'collaborators';
    }
  }
}