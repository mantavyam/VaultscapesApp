import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/responsive/responsive.dart';

/// Welcome screen - first screen shown to users
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveBuilder(
      builder: (context, windowSize) {
        // Responsive sizing
        final padding = windowSize.isMicro ? 16.0 : 24.0;

        return Scaffold(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Check if we have enough height for Spacers
                  final hasEnoughHeight = constraints.maxHeight > 400;

                  if (hasEnoughHeight) {
                    // Normal layout with Spacers
                    return Column(
                      children: [
                        const Spacer(flex: 1),
                        // Hero Section
                        _buildHeroSection(context, theme, windowSize),
                        const Spacer(flex: 2),
                        // CTA Buttons
                        _buildCTAButtons(context, theme, windowSize),
                        SizedBox(height: windowSize.isMicro ? 20 : 32),
                      ],
                    );
                  } else {
                    // Scrollable layout for constrained heights
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: windowSize.isMicro ? 16 : 24),
                          // Hero Section
                          _buildHeroSection(context, theme, windowSize),
                          SizedBox(height: windowSize.isMicro ? 24 : 40),
                          // CTA Buttons
                          _buildCTAButtons(context, theme, windowSize),
                          SizedBox(height: windowSize.isMicro ? 20 : 32),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    // Responsive sizing
    final logoSize = windowSize.isMicro ? 80.0 : 100.0;
    final logoIconSize = windowSize.isMicro ? 40.0 : 48.0;
    final titleFontSize = windowSize.isMicro ? 26.0 : 32.0;
    final taglineFontSize = windowSize.isMicro ? 14.0 : 16.0;
    final descFontSize = windowSize.isMicro ? 12.0 : 14.0;

    return Column(
      children: [
        // Logo/Icon
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(windowSize.isMicro ? 20 : 24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.library_books_rounded,
            size: logoIconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: windowSize.isMicro ? 24 : 32),
        // App Name
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.foreground,
          ),
        ),
        SizedBox(height: windowSize.isMicro ? 8 : 12),
        // Tagline
        Text(
          'Stay Ahead of the Curve',
          style: TextStyle(
            fontSize: taglineFontSize,
            color: theme.colorScheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: windowSize.isMicro ? 12 : 20),
        // Description
        Text(
          windowSize.isMicro
              ? 'Access Academic Materials, Notes, Assignments, PYQs — All in One Place.'
              : 'Access Semester-Wise Academic Materials, Notes, Assignments, PYQs of UG BTECH + Signals and Breakthroughs in Latest AI Technological Developments — All in One Place.',
          style: TextStyle(
            fontSize: descFontSize,
            color: theme.colorScheme.mutedForeground,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCTAButtons(
    BuildContext context,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    final buttonHeight = windowSize.isMicro ? 44.0 : 48.0;
    final buttonSpacing = windowSize.isMicro ? 8.0 : 12.0;

    return Column(
      children: [
        // Get Started Button (Primary)
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: PrimaryButton(
            onPressed: () => _showAuthBottomSheet(context),
            child: const Text('Get Started'),
          ),
        ),
        SizedBox(height: buttonSpacing),
        // Explore Button (Ghost)
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const SizedBox(height: 16),
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
                style: TextStyle(color: theme.colorScheme.mutedForeground),
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
              const SizedBox(height: 12),
              // GitHub Sign In Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlineButton(
                  onPressed: () => _handleGithubSignIn(context, sheetContext),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(BootstrapIcons.github, size: 20),
                      SizedBox(width: 12),
                      Text('Continue with GitHub'),
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

  Future<void> _handleGoogleSignIn(
    BuildContext context,
    BuildContext sheetContext,
  ) async {
    // Check internet connectivity first
    final connectivityService = ConnectivityService();
    final isConnected = await connectivityService.checkConnectivity();

    if (!isConnected) {
      if (sheetContext.mounted) closeSheet(sheetContext); // Close bottom sheet
      if (context.mounted) {
        showToast(
          context: context,
          builder: (context, overlay) {
            return SurfaceCard(
              child: Basic(
                title: const Text('No Internet Connection'),
                content: const Text(
                  'Please connect to the internet to sign in with Google.',
                ),
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

    if (sheetContext.mounted) closeSheet(sheetContext); // Close bottom sheet

    if (!context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();

    final success = await authProvider.signInWithGoogle();

    if (success && context.mounted) {
      // Check Firebase for profile setup status (user might have set up profile before logout)
      if (authProvider.user?.uid != null) {
        await onboardingProvider.checkFirebaseProfileStatus(
          authProvider.user!.uid,
        );
      }
      if (!context.mounted) return;

      await onboardingProvider.completeOnboarding();
      if (!context.mounted) return;

      // Check if user has completed profile setup before (returning user)
      if (onboardingProvider.hasCompletedProfileSetup) {
        // Returning user - go directly to home
        onboardingProvider.markAsReturningUser();
        if (context.mounted) context.go(RouteConstants.home);
      } else {
        // First-time user - go to profile setup
        if (context.mounted) context.go(RouteConstants.profileSetup);
      }
    }
  }

  Future<void> _handleGithubSignIn(
    BuildContext context,
    BuildContext sheetContext,
  ) async {
    // Check internet connectivity first
    final connectivityService = ConnectivityService();
    final isConnected = await connectivityService.checkConnectivity();

    if (!isConnected) {
      if (sheetContext.mounted) closeSheet(sheetContext); // Close bottom sheet
      if (context.mounted) {
        showToast(
          context: context,
          builder: (context, overlay) {
            return SurfaceCard(
              child: Basic(
                title: const Text('No Internet Connection'),
                content: const Text(
                  'Please connect to the internet to sign in with GitHub.',
                ),
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

    if (sheetContext.mounted) closeSheet(sheetContext); // Close bottom sheet

    if (!context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();

    final success = await authProvider.signInWithGithub();

    if (success && context.mounted) {
      // Check Firebase for profile setup status (user might have set up profile before logout)
      if (authProvider.user?.uid != null) {
        await onboardingProvider.checkFirebaseProfileStatus(
          authProvider.user!.uid,
        );
      }
      if (!context.mounted) return;

      await onboardingProvider.completeOnboarding();
      if (!context.mounted) return;

      // Check if user has completed profile setup before (returning user)
      if (onboardingProvider.hasCompletedProfileSetup) {
        // Returning user - go directly to home
        onboardingProvider.markAsReturningUser();
        if (context.mounted) context.go(RouteConstants.home);
      } else {
        // First-time user - go to profile setup
        if (context.mounted) context.go(RouteConstants.profileSetup);
      }
    }
  }

  Future<void> _continueAsGuest(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();
    await authProvider.continueAsGuest();
    await onboardingProvider.completeOnboarding();
    if (context.mounted) {
      context.go(RouteConstants.home);
    }
  }
}
