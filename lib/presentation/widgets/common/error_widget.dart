import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Error widget for displaying error states
class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool hideDetailedError;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.hideDetailedError = false,
  });

  /// Factory for network errors
  factory AppErrorWidget.network({
    VoidCallback? onRetry,
    bool hideDetailedError = false,
  }) {
    return AppErrorWidget(
      message: 'No Internet Connection',
      details: 'Please check your internet connection and try again.',
      onRetry: onRetry,
      icon: Icons.wifi_off,
      hideDetailedError: hideDetailedError,
    );
  }

  /// Factory for generic errors
  factory AppErrorWidget.generic({
    String? message,
    VoidCallback? onRetry,
    bool hideDetailedError = false,
  }) {
    return AppErrorWidget(
      message: message ?? 'Something went wrong',
      details: 'Please try again later.',
      onRetry: onRetry,
      icon: Icons.error_outline,
      hideDetailedError: hideDetailedError,
    );
  }

  /// Filter out technical error details that shouldn't be shown to users
  String? _filterErrorDetails(String? details) {
    if (details == null || hideDetailedError) return null;
    
    // Remove technical host lookup errors
    if (details.contains('Failed host lookup') || 
        details.contains('mantavyam.gitbook.io') ||
        details.contains('SocketException') ||
        details.contains('HttpException')) {
      return null; // Return null to not show technical details
    }
    
    return details;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredDetails = _filterErrorDetails(details);

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
            if (filteredDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                filteredDetails,
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
