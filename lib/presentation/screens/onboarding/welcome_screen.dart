import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';

/// Welcome screen - first screen shown to users
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Hero Section
              _buildHeroSection(context, theme),
              const Spacer(flex: 2),
              // CTA Buttons
              _buildCTAButtons(context, theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Logo/Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.library_books_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        // App Name
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.foreground,
          ),
        ),
        const SizedBox(height: 12),
        // Tagline
        Text(
          'Your Academic Resource Hub',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Description
        Text(
          'Access semester-wise academic materials, notes, assignments, and previous year questions — all in one place.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.mutedForeground,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCTAButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Get Started Button (Primary)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: PrimaryButton(
            onPressed: () => _showAuthBottomSheet(context),
            child: const Text('Get Started'),
          ),
        ),
        const SizedBox(height: 12),
        // Explore Button (Ghost)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlineButton(
            onPressed: () => _continueAsGuest(context),
            child: const Text('Explore as Guest'),
          ),
        ),
      ],
    );
  }

  void _showAuthBottomSheet(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AuthBottomSheet(),
    );
  }

  void _continueAsGuest(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.continueAsGuest();
    if (context.mounted) {
      context.go(RouteConstants.home);
    }
  }
}

/// Authentication bottom sheet
class _AuthBottomSheet extends StatefulWidget {
  const _AuthBottomSheet();

  @override
  State<_AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<_AuthBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Welcome to ${AppConstants.appName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sign in to personalize your experience',
            style: TextStyle(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          // Auth Options
          if (_isLoading)
            const _LoadingAuth()
          else
            _AuthOptions(
              onMockAuth: _handleMockAuth,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleMockAuth() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.mockAuthenticate();

    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
      if (success && context.mounted) {
        context.go(RouteConstants.home); // Navigate to home
      }
    }
  }
}

class _AuthOptions extends StatelessWidget {
  final VoidCallback onMockAuth;

  const _AuthOptions({required this.onMockAuth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Mock Auth Button (Phase 1)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: PrimaryButton(
            onPressed: onMockAuth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.login_rounded, size: 20),
                SizedBox(width: 8),
                Text('Sign In'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Google Sign In (Phase 2 - Placeholder)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlineButton(
            onPressed: null, // Disabled for Phase 1
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.g_mobiledata_rounded,
                  size: 20,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Google (Coming Soon)',
                    style: TextStyle(
                      color: theme.colorScheme.mutedForeground,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingAuth extends StatelessWidget {
  const _LoadingAuth();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Signing you in...',
          style: TextStyle(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
