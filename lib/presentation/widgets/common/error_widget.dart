import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Error widget for displaying error states
class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Factory for network errors
  factory AppErrorWidget.network({
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      message: 'Network Error',
      details: 'Please check your internet connection and try again.',
      onRetry: onRetry,
      icon: Icons.wifi_off,
    );
  }

  /// Factory for generic errors
  factory AppErrorWidget.generic({
    String? message,
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      message: message ?? 'Something went wrong',
      details: 'Please try again later.',
      onRetry: onRetry,
      icon: Icons.error_outline,
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
              size: 64,
              color: theme.colorScheme.destructive,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: TextStyle(
                  color: theme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: onRetry,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Try Again'),
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
