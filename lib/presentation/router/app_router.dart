import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/home/semester_overview_screen.dart';
import '../screens/home/subject_detail_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';
import '../screens/profile/terms_of_service_screen.dart';
import '../screens/content/gitbook_content_screen.dart';

/// App router configuration using go_router
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.welcome,
    debugLogDiagnostics: true,
    routes: [
      // Welcome/Onboarding Screen
      GoRoute(
        path: RouteConstants.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Main Navigation (with bottom nav bar)
      GoRoute(
        path: '/main/home',
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
        routes: [
          // Semester Overview
          GoRoute(
            path: 'semester/:semesterId',
            name: 'semester',
            builder: (context, state) {
              final semesterId = state.pathParameters['semesterId']!;
              return SemesterOverviewScreen(semesterId: semesterId);
            },
            routes: [
              // Subject Detail
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
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          // Terms of Service
          GoRoute(
            path: 'terms-of-service',
            name: 'terms-of-service',
            builder: (context, state) => const TermsOfServiceScreen(),
          ),
          // Gitbook Content Screen (for dynamic content)
          GoRoute(
            path: 'content',
            name: 'content',
            builder: (context, state) {
              final title = state.uri.queryParameters['title'] ?? 'Content';
              final gitbookUrl = state.uri.queryParameters['url'] ?? '';
              final subtitle = state.uri.queryParameters['subtitle'];
              return GitbookContentScreen(
                title: title,
                gitbookUrl: gitbookUrl,
                subtitle: subtitle,
              );
            },
          ),
        ],
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
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Page not found',
            style: TextStyle(fontSize: 24),
          ),
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
