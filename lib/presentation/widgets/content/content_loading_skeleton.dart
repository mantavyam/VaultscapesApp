import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Loading skeleton placeholder for markdown content
class ContentLoadingSkeleton extends StatelessWidget {
  const ContentLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          _buildSkeleton(250, 32, theme),
          const SizedBox(height: 24),
          
          // Paragraph skeletons
          _buildSkeleton(double.infinity, 16, theme),
          const SizedBox(height: 8),
          _buildSkeleton(double.infinity, 16, theme),
          const SizedBox(height: 8),
          _buildSkeleton(280, 16, theme),
          const SizedBox(height: 24),
          
          // Section heading
          _buildSkeleton(180, 24, theme),
          const SizedBox(height: 16),
          
          // More paragraphs
          _buildSkeleton(double.infinity, 16, theme),
          const SizedBox(height: 8),
          _buildSkeleton(double.infinity, 16, theme),
          const SizedBox(height: 8),
          _buildSkeleton(double.infinity, 16, theme),
          const SizedBox(height: 8),
          _buildSkeleton(200, 16, theme),
          const SizedBox(height: 24),
          
          // List items
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeleton(double.infinity, 16, theme),
                    const SizedBox(height: 12),
                    _buildSkeleton(double.infinity, 16, theme),
                    const SizedBox(height: 12),
                    _buildSkeleton(220, 16, theme),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Code block skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeleton(180, 14, theme),
                const SizedBox(height: 8),
                _buildSkeleton(220, 14, theme),
                const SizedBox(height: 8),
                _buildSkeleton(160, 14, theme),
                const SizedBox(height: 8),
                _buildSkeleton(200, 14, theme),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Image skeleton
          _buildSkeleton(double.infinity, 200, theme),
          const SizedBox(height: 8),
          _buildSkeleton(150, 14, theme),
          const SizedBox(height: 24),
          
          // More paragraphs
          _buildSkeleton(double.infinity, 16, theme),
          const SizedBox(height: 8),
          _buildSkeleton(double.infinity, 16, theme),
          const SizedBox(height: 8),
          _buildSkeleton(300, 16, theme),
        ],
      ),
    );
  }

  Widget _buildSkeleton(double width, double height, ThemeData theme) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Error widget for content loading failures
class ContentErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const ContentErrorWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              RadixIcons.crossCircled,
              size: 48,
              color: theme.colorScheme.destructive,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.typography.h4,
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(details!).muted(),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: onRetry,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(RadixIcons.reload, size: 16),
                    SizedBox(width: 8),
                    Text('Retry'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
