import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../widgets/auth_bottom_sheet.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo Placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.school,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // App Name
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xs),
              
              // App Tagline
              Text(
                AppStrings.appTagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showAuthBottomSheet(context),
                  child: const Text(AppStrings.getStarted),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Explore Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _exploreAsGuest(context),
                  child: const Text(AppStrings.explore),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAuthBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuthBottomSheet(),
    );
  }

  void _exploreAsGuest(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final preferencesProvider = context.read<PreferencesProvider>();
    
    // Mark welcome as seen
    await preferencesProvider.markWelcomeSeen();
    
    // Create guest user
    final success = await userProvider.continueAsGuest();
    
    if (success) {
      // Navigate to home screen
      if (context.mounted) {
        context.go('/home');
      }
    } else {
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start guest session'),
          ),
        );
      }
    }
  }
}