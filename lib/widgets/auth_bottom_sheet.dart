import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/constants/app_constants.dart';
import '../providers/user_provider.dart';
import '../providers/preferences_provider.dart';

class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.borderRadiusLarge),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.cardPadding,
          AppSpacing.sm,
          AppSpacing.cardPadding,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.cardPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: AppSizes.dragHandleWidth,
              height: AppSizes.dragHandleHeight,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(AppSizes.dragHandleHeight / 2),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Heading
            Text(
              AppStrings.signInToContinue,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppSpacing.xs),
            
            // Subheading
            Text(
              AppStrings.savePreferencesSubtext,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Google Sign-In Button
            _buildAuthButton(
              onPressed: _isLoading ? null : () => _signInWithGoogle(context),
              icon: Icons.g_mobiledata, // Placeholder for Google icon
              text: AppStrings.continueWithGoogle,
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // GitHub Sign-In Button
            _buildAuthButton(
              onPressed: _isLoading ? null : () => _signInWithGitHub(context),
              icon: Icons.code, // Placeholder for GitHub icon
              text: AppStrings.continueWithGitHub,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Loading Indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Terms Disclaimer
            Text(
              AppStrings.termsDisclaimer,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey[300]!),
          elevation: 1,
        ),
      ),
    );
  }

  void _signInWithGoogle(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final preferencesProvider = context.read<PreferencesProvider>();
      
      final success = await userProvider.signInWithGoogle();
      
      if (success && mounted) {
        // Mark welcome as seen
        await preferencesProvider.markWelcomeSeen();
        
        // Close bottom sheet
        Navigator.of(context).pop();
        
        // Navigate to name customization or home
        context.go('/name-customization');
      } else if (mounted) {
        _showError(context, AppStrings.signInFailed);
      }
    } catch (e) {
      if (mounted) {
        _showError(context, AppStrings.signInFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signInWithGitHub(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final preferencesProvider = context.read<PreferencesProvider>();
      
      final success = await userProvider.signInWithGitHub();
      
      if (success && mounted) {
        // Mark welcome as seen
        await preferencesProvider.markWelcomeSeen();
        
        // Close bottom sheet
        Navigator.of(context).pop();
        
        // Navigate to name customization or home
        context.go('/name-customization');
      } else if (mounted) {
        _showError(context, AppStrings.signInFailed);
      }
    } catch (e) {
      if (mounted) {
        _showError(context, AppStrings.signInFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}