import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../../core/constants/route_constants.dart';

/// Splash screen - neutral initial route that waits for auth and onboarding
/// state restoration before routing to the correct destination.
/// This prevents any flash of the wrong screen (e.g., welcome screen for logged-in users).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Check state after first frame to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (_hasNavigated) return;

    final authProvider = context.read<AuthProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();

    // If both providers are done loading, navigate to the correct destination
    if (!authProvider.isLoading && !onboardingProvider.isLoading) {
      _navigateToDestination(authProvider, onboardingProvider);
    } else {
      // Listen for changes if still loading
      authProvider.addListener(_onProviderChanged);
      onboardingProvider.addListener(_onProviderChanged);
    }
  }

  void _onProviderChanged() {
    if (_hasNavigated) return;

    final authProvider = context.read<AuthProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();

    if (!authProvider.isLoading && !onboardingProvider.isLoading) {
      // Remove listeners before navigating
      authProvider.removeListener(_onProviderChanged);
      onboardingProvider.removeListener(_onProviderChanged);
      _navigateToDestination(authProvider, onboardingProvider);
    }
  }

  Future<void> _navigateToDestination(
    AuthProvider authProvider,
    OnboardingProvider onboardingProvider,
  ) async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final hasCompletedOnboarding = onboardingProvider.hasCompletedOnboarding;
    final isAuthenticated = authProvider.isAuthenticated;
    final isGuest = authProvider.isGuest;

    String destination;

    // If user is not authenticated (not signed in and not guest), go to welcome/login
    if (!isAuthenticated && !isGuest) {
      // Always go to welcome screen for unauthenticated users
      // This serves as both onboarding for new users and login for returning users
      destination = RouteConstants.welcome;
      if (mounted) context.go(destination);
      return;
    }

    // If user is a guest, go directly to home
    if (isGuest) {
      if (mounted) context.go(RouteConstants.home);
      return;
    }

    // User is authenticated - check Firebase for profile setup status
    final user = authProvider.user;
    if (user != null) {
      // Check Firebase to see if this user has already completed profile setup
      await onboardingProvider.checkFirebaseProfileStatus(user.uid);
    }

    // Re-check profile setup status after Firebase check
    final hasCompletedProfileSetup =
        onboardingProvider.hasCompletedProfileSetup;
    final isReturningUser = onboardingProvider.isReturningUser;

    if (hasCompletedOnboarding) {
      // User has been through onboarding before
      if (!hasCompletedProfileSetup && !isReturningUser) {
        // Authenticated but hasn't completed profile setup (and not returning)
        destination = RouteConstants.profileSetup;
      } else {
        // Go directly to home
        destination = RouteConstants.home;
      }
    } else {
      // New user - show welcome/onboarding
      destination = RouteConstants.welcome;
    }

    // Use go with replace to prevent back navigation to splash
    if (mounted) context.go(destination);
  }

  @override
  void dispose() {
    // Clean up listeners if they were added
    try {
      final authProvider = context.read<AuthProvider>();
      final onboardingProvider = context.read<OnboardingProvider>();
      authProvider.removeListener(_onProviderChanged);
      onboardingProvider.removeListener(_onProviderChanged);
    } catch (_) {
      // Ignore if context is no longer valid
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      child: Container(
        color: theme.colorScheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 50,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                'Vaultscapes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.foreground,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
