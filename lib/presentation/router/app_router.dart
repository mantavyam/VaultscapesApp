import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/home/semester_overview_screen.dart';
import '../screens/home/subject_detail_screen.dart';

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
        path: RouteConstants.home,
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
