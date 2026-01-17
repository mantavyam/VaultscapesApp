import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Empty state widget for displaying when no data is available
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  /// Factory for no results state
  factory EmptyStateWidget.noResults({String? searchTerm}) {
    return EmptyStateWidget(
      title: 'No results found',
      description: searchTerm != null
          ? 'No results found for "$searchTerm"'
          : 'Try adjusting your search criteria.',
      icon: Icons.search_off,
    );
  }

  /// Factory for no content state
  factory EmptyStateWidget.noContent({String? contentType}) {
    return EmptyStateWidget(
      title: 'No ${contentType ?? 'content'} available',
      description: 'Check back later for updates.',
      icon: Icons.folder_open,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(
                  color: theme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
