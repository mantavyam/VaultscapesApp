import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/quick_link_tile.dart';
import '../../widgets/semester_dropdown.dart';
import '../../services/url_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<UserProvider, PreferencesProvider>(
          builder: (context, userProvider, preferencesProvider, child) {
            if (userProvider.isGuest) {
              return _buildGuestView(context, userProvider);
            } else if (userProvider.isAuthenticated) {
              return _buildAuthenticatedView(context, userProvider, preferencesProvider);
            } else {
              return _buildLoadingView();
            }
          },
        ),
      ),
    );
  }

  Widget _buildAuthenticatedView(
    BuildContext context, 
    UserProvider userProvider, 
    PreferencesProvider preferencesProvider,
  ) {
    final user = userProvider.currentUser!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          // User Information Section
          _buildUserInfoSection(context, user, userProvider),
          
          const SizedBox(height: AppSpacing.lg),
          _buildDivider(),
          const SizedBox(height: AppSpacing.lg),
          
          // Quick Links Section
          _buildQuickLinksSection(context),
          
          const SizedBox(height: AppSpacing.lg),
          _buildDivider(),
          const SizedBox(height: AppSpacing.lg),
          
          // Settings Section
          _buildSettingsSection(context, preferencesProvider),
          
          const SizedBox(height: AppSpacing.lg),
          _buildDivider(),
          const SizedBox(height: AppSpacing.lg),
          
          // Account Actions Section
          _buildAccountActionsSection(context, userProvider),
        ],
      ),
    );
  }

  Widget _buildGuestView(BuildContext context, UserProvider userProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          // Guest Call to Action
          _buildGuestCallToAction(context, userProvider),
          
          const SizedBox(height: AppSpacing.lg),
          _buildDivider(),
          const SizedBox(height: AppSpacing.lg),
          
          // Quick Links (available for guests too)
          _buildQuickLinksSection(context),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context, user, UserProvider userProvider) {
    return Column(
      children: [
        // Avatar
        ProfileAvatar(
          photoURL: user.photoURL,
          initials: user.initials,
          size: AppSizes.avatarLarge,
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Name (editable)
        if (_isEditingName) 
          _buildNameEditor(context, user, userProvider)
        else
          _buildNameDisplay(context, user),
        
        const SizedBox(height: AppSpacing.xs),
        
        // Email
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNameDisplay(BuildContext context, user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () {
            setState(() {
              _isEditingName = true;
              _nameController.text = user.displayName;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNameEditor(BuildContext context, user, UserProvider userProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onSubmitted: (value) => _saveName(userProvider),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, size: 20),
          onPressed: () => _saveName(userProvider),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () {
            setState(() {
              _isEditingName = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildGuestCallToAction(BuildContext context, UserProvider userProvider) {
    return Column(
      children: [
        // Generic avatar
        const ProfileAvatar(
          initials: 'G',
          size: AppSizes.avatarLarge,
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        Text(
          AppStrings.welcomeGuest,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        
        const SizedBox(height: AppSpacing.xs),
        
        Text(
          AppStrings.signInToSavePrefs,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Create Profile Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _navigateToAuth(context),
            child: const Text(AppStrings.createProfile),
          ),
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Login Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _navigateToAuth(context),
            child: const Text(AppStrings.login),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        const QuickLinkTile(
          icon: Icons.search,
          title: AppStrings.searchDatabase,
          linkType: QuickLinkType.searchDatabase,
        ),
        const QuickLinkTile(
          icon: Icons.code,
          title: AppStrings.githubRepository,
          linkType: QuickLinkType.githubRepository,
        ),
        const QuickLinkTile(
          icon: Icons.chat,
          title: AppStrings.discordCommunity,
          linkType: QuickLinkType.discordCommunity,
        ),
        const QuickLinkTile(
          icon: Icons.help_outline,
          title: AppStrings.howToUseDatabase,
          linkType: QuickLinkType.howToUseDatabase,
        ),
        const QuickLinkTile(
          icon: Icons.people_outline,
          title: AppStrings.howToCollaborate,
          linkType: QuickLinkType.howToCollaborate,
        ),
        const QuickLinkTile(
          icon: Icons.groups,
          title: AppStrings.collaborators,
          linkType: QuickLinkType.collaborators,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, PreferencesProvider preferencesProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        const SemesterDropdown(),
      ],
    );
  }

  Widget _buildAccountActionsSection(BuildContext context, UserProvider userProvider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _showLogoutDialog(context, userProvider),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.logout),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
    );
  }

  void _saveName(UserProvider userProvider) async {
    final newName = _nameController.text.trim();
    if (newName.length >= AppStrings.nameMinLength && 
        newName.length <= AppStrings.nameMaxLength) {
      
      final success = await userProvider.updateUserName(newName);
      
      if (success && mounted) {
        setState(() {
          _isEditingName = false;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update name')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Name must be ${AppStrings.nameMinLength}-${AppStrings.nameMaxLength} characters',
          ),
        ),
      );
    }
  }

  void _navigateToAuth(BuildContext context) {
    context.go('/welcome');
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(AppStrings.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await userProvider.signOut();
              if (success && mounted) {
                context.go('/welcome');
              }
            },
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}