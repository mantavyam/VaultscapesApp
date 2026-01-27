import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/home/semester_overview_screen.dart';
import '../screens/home/subject_detail_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';
import '../screens/profile/terms_of_service_screen.dart';
import '../screens/profile/feedback_history_screen.dart';
import '../screens/profile/collaboration_history_screen.dart';
import '../screens/content/gitbook_content_screen.dart';

/// Custom page transition builder for slide animations
Page<dynamic> _buildPageWithSlideTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Slide from right to left when entering (push)
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var slideTween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      var offsetAnimation = animation.drive(slideTween);

      // Slide from left to right when exiting (pop)
      var secondarySlideTween = Tween(
        begin: Offset.zero,
        end: const Offset(-0.3, 0.0), // Subtle parallax effect on background
      ).chain(CurveTween(curve: curve));

      var secondaryOffsetAnimation =
          secondaryAnimation.drive(secondarySlideTween);

      return SlideTransition(
        position: offsetAnimation,
        child: SlideTransition(
          position: secondaryOffsetAnimation,
          child: child,
        ),
      );
    },
  );
}

/// App router configuration using go_router
/// Uses splash screen as initial route to properly handle auth restoration
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final onboardingProvider = context.read<OnboardingProvider>();
      final authProvider = context.read<AuthProvider>();
      final isOnSplash = state.matchedLocation == RouteConstants.splash;

      // Never redirect away from splash - it handles its own navigation
      if (isOnSplash) {
        return null;
      }

      // If still loading, stay on current page (shouldn't happen after splash)
      if (onboardingProvider.isLoading || authProvider.isLoading) {
        return null;
      }

      final isOnWelcomePage = state.matchedLocation == RouteConstants.welcome;
      final isOnProfileSetup =
          state.matchedLocation == RouteConstants.profileSetup;
      final hasCompletedOnboarding = onboardingProvider.hasCompletedOnboarding;
      final isAuthenticated = authProvider.isAuthenticated;
      final hasCompletedProfileSetup =
          onboardingProvider.hasCompletedProfileSetup;

      // If user has completed onboarding and is on welcome page, redirect to home
      if (hasCompletedOnboarding && isOnWelcomePage) {
        // For authenticated users who haven't completed profile setup, redirect to profile setup
        if (isAuthenticated &&
            !hasCompletedProfileSetup &&
            !onboardingProvider.isReturningUser) {
          return RouteConstants.profileSetup;
        }
        return RouteConstants.home;
      }

      // Prevent going to profile setup if not authenticated
      if (isOnProfileSetup && !isAuthenticated) {
        return RouteConstants.welcome;
      }

      return null;
    },
    routes: [
      // Splash Screen - neutral initial route for auth restoration
      GoRoute(
        path: RouteConstants.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Welcome/Onboarding Screen
      GoRoute(
        path: RouteConstants.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Profile Setup Screen (for first-time authenticated users)
      GoRoute(
        path: RouteConstants.profileSetup,
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Main Navigation (with bottom nav bar)
      GoRoute(
        path: '/main/home',
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
        routes: [
          // Semester Overview - uses PageView internally, so NO custom animation
          GoRoute(
            path: 'semester/:semesterId',
            name: 'semester',
            builder: (context, state) {
              final semesterId = state.pathParameters['semesterId']!;
              return SemesterOverviewScreen(semesterId: semesterId);
            },
            routes: [
              // Subject Detail - also uses swipeable content, so NO custom animation
              GoRoute(
                path: 'subject/:subjectId',
                name: 'subject',
                builder: (context, state) {
                  final semesterId = state.pathParameters['semesterId']!;
                  final subjectId = state.pathParameters['subjectId']!;
                  return SubjectDetailScreen(
                    semesterId: semesterId,
                    subjectId: subjectId,
                  );
                },
              ),
            ],
          ),
          // Privacy Policy
          GoRoute(
            path: 'privacy-policy',
            name: 'privacy-policy',
            pageBuilder: (context, state) => _buildPageWithSlideTransition(
              context,
              state,
              const PrivacyPolicyScreen(),
            ),
          ),
          // Terms of Service
          GoRoute(
            path: 'terms-of-service',
            name: 'terms-of-service',
            pageBuilder: (context, state) => _buildPageWithSlideTransition(
              context,
              state,
              const TermsOfServiceScreen(),
            ),
          ),
          // Gitbook Content Screen (for dynamic content)
          GoRoute(
            path: 'content',
            name: 'content',
            pageBuilder: (context, state) {
              final title = state.uri.queryParameters['title'] ?? 'Content';
              final gitbookUrl = state.uri.queryParameters['url'] ?? '';
              final subtitle = state.uri.queryParameters['subtitle'];
              return _buildPageWithSlideTransition(
                context,
                state,
                GitbookContentScreen(
                  title: title,
                  gitbookUrl: gitbookUrl,
                  subtitle: subtitle,
                ),
              );
            },
          ),
        ],
      ),
      // Profile sub-routes (accessible from profile screen)
      GoRoute(
        path: '/main/profile/feedback-history',
        name: 'feedback-history',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const FeedbackHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/main/profile/collaboration-history',
        name: 'collaboration-history',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const CollaborationHistoryScreen(),
        ),
      ),
      // Synergy route for navigating from empty history states
      GoRoute(
        path: '/main/synergy',
        name: 'synergy',
        builder: (context, state) => const MainNavigationScreen(initialTab: 2),
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

/// Error screen for invalid routes
class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '404',
            style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Page not found', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.go(RouteConstants.home),
            child: const Text(
              'Go to Home',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
