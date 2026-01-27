import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/services/connectivity_service.dart';

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
    openSheet(
      context: context,
      position: OverlayPosition.bottom,
      draggable: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Welcome to ${AppConstants.appName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to personalize your experience',
                style: TextStyle(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 32),
              // Google Sign In Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlineButton(
                  onPressed: () => _handleGoogleSignIn(context, sheetContext),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(BootstrapIcons.google, size: 20),
                      SizedBox(width: 12),
                      Text('Continue with Google'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, BuildContext sheetContext) async {
    // Check internet connectivity first
    final connectivityService = ConnectivityService();
    final isConnected = await connectivityService.checkConnectivity();
    
    if (!isConnected) {
      closeSheet(sheetContext); // Close bottom sheet
      if (context.mounted) {
        showToast(
          context: context,
          builder: (context, overlay) {
            return SurfaceCard(
              child: Basic(
                title: const Text('No Internet Connection'),
                content: const Text('Please connect to the internet to sign in with Google.'),
                leading: Icon(
                  Icons.wifi_off_rounded,
                  color: Theme.of(context).colorScheme.destructive,
                ),
                trailing: IconButton.ghost(
                  icon: const Icon(Icons.close),
                  onPressed: () => overlay.close(),
                ),
              ),
            );
          },
          location: ToastLocation.bottomCenter,
        );
      }
      return;
    }
    
    closeSheet(sheetContext); // Close bottom sheet
    
    final authProvider = context.read<AuthProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();
    
    final success = await authProvider.signInWithGoogle();
    
    if (success && context.mounted) {
      await onboardingProvider.completeOnboarding();
      
      // Check if user has completed profile setup before (returning user)
      if (onboardingProvider.hasCompletedProfileSetup) {
        // Returning user - go directly to home
        onboardingProvider.markAsReturningUser();
        context.go(RouteConstants.home);
      } else {
        // First-time user - go to profile setup
        context.go(RouteConstants.profileSetup);
      }
    }
  }

  void _continueAsGuest(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();
    await authProvider.continueAsGuest();
    await onboardingProvider.completeOnboarding();
    if (context.mounted) {
      context.go(RouteConstants.home);
    }
  }
}
