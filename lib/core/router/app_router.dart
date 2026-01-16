import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../screens/onboarding/welcome_screen.dart';
import '../../screens/onboarding/name_customization_screen.dart';
import '../../screens/main/main_navigation.dart';
import '../../screens/main/home_screen.dart';
import '../../screens/main/collaborate_screen.dart';
import '../../screens/main/feedback_screen.dart';
import '../../screens/main/profile_screen.dart';
import '../../screens/webview/webview_screen.dart';
import '../../screens/webview/search_screen.dart';
import '../../providers/preferences_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Root route with redirect logic
      GoRoute(
        path: '/',
        redirect: (context, state) {
          // Check if user has seen welcome screen
          final prefsProvider = context.read<PreferencesProvider>();
          if (!prefsProvider.preferences.hasSeenWelcome) {
            return '/welcome';
          }
          return '/home';
        },
      ),

      // Welcome screen
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Name customization screen
      GoRoute(
        path: '/name-customization',
        name: 'name-customization',
        builder: (context, state) => const NameCustomizationScreen(),
      ),

      // Main app with shell route for bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/collaborate',
            name: 'collaborate',
            builder: (context, state) => const CollaborateScreen(),
          ),
          GoRoute(
            path: '/feedback',
            name: 'feedback',
            builder: (context, state) => const FeedbackScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Generic webview screen for quick links
      GoRoute(
        path: '/webview/:type',
        name: 'webview',
        builder: (context, state) {
          final type = state.pathParameters['type']!;
          return WebViewScreen(linkType: type);
        },
      ),

      // Search screen
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],

    // Global error handler
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64),
            SizedBox(height: 16),
            Text('Page not found'),
          ],
        ),
      ),
    ),
  );
}