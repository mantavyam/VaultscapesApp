import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import 'edit_profile_dialog.dart';

/// Profile screen with guest/authenticated views
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          child: authProvider.isAuthenticated
              ? _AuthenticatedProfileView(authProvider: authProvider)
              : const _GuestProfileView(),
        );
      },
    );
  }
}

/// Guest profile view
class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Guest Avatar using RadixIcons.avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              RadixIcons.avatar,
              size: 50,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Guest User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to unlock all features',
            style: TextStyle(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),

          // Sign In Button - triggers auth flow directly
          PrimaryButton(
            onPressed: () => _signInWithGoogle(context),
            child: const Text('Sign In'),
          ),
          const SizedBox(height: 40),

          // Settings Section
          _buildSettingsSection(context),
          const SizedBox(height: 24),

          // Quick Links Section
          _buildQuickLinksSection(context),
          const SizedBox(height: 24),

          // App Info Section
          _buildAppInfoSection(context),
        ],
      ),
    );
  }

  /// Trigger Google Sign In directly
  void _signInWithGoogle(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithGoogle();
  }

  Widget _buildSettingsSection(BuildContext context) {
    return _SettingsSection();
  }

  Widget _buildQuickLinksSection(BuildContext context) {
    return _QuickLinksSection();
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return _AppInfoSection();
  }
}

/// Authenticated profile view
class _AuthenticatedProfileView extends StatelessWidget {
  final AuthProvider authProvider;

  const _AuthenticatedProfileView({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authProvider.user;
    final photoUrl = user?.photoUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Avatar - use Google profile image if available
          if (photoUrl != null && photoUrl.isNotEmpty)
            ClipOval(
              child: Image.network(
                photoUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Avatar(
                    size: 100,
                    initials: user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                    backgroundColor: theme.colorScheme.primary,
                  );
                },
              ),
            )
          else
            Avatar(
              size: 100,
              initials: user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
              backgroundColor: theme.colorScheme.primary,
            ),
          const SizedBox(height: 16),

          // User Name with Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user?.displayName ?? 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.ghost(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditProfileDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 32),

          // Settings Section
          _SettingsSection(),
          const SizedBox(height: 24),

          // Quick Links Section
          _QuickLinksSection(),
          const SizedBox(height: 24),

          // App Info Section
          _AppInfoSection(),
          const SizedBox(height: 24),

          // Logout Button - Red color with proper destructive styling
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _showLogoutConfirmation(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            OutlineButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                await authProvider.signOut();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Settings section widget
class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Inline Theme Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  color: theme.colorScheme.mutedForeground,
                  size: 22,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Theme',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                // Segmented button for theme selection
                _ThemeSegmentedButton(themeProvider: themeProvider),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _SettingsListTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              showToast(
                context: context,
                builder: (context, overlay) {
                  return SurfaceCard(
                    child: Basic(
                      title: const Text('Coming soon'),
                      subtitle: const Text('Notification settings will be available in a future update'),
                      trailing: IconButton.ghost(
                        icon: const Icon(Icons.close),
                        onPressed: () => overlay.close(),
                      ),
                    ),
                  );
                },
                location: ToastLocation.bottomCenter,
              );
            },
          ),
          _SettingsListTile(
            icon: Icons.download,
            title: 'Downloads',
            subtitle: 'Manage downloaded content',
            onTap: () {
              showToast(
                context: context,
                builder: (context, overlay) {
                  return SurfaceCard(
                    child: Basic(
                      title: const Text('Coming soon'),
                      subtitle: const Text('Download management will be available in a future update'),
                      trailing: IconButton.ghost(
                        icon: const Icon(Icons.close),
                        onPressed: () => overlay.close(),
                      ),
                    ),
                  );
                },
                location: ToastLocation.bottomCenter,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Theme segmented button widget
class _ThemeSegmentedButton extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _ThemeSegmentedButton({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMode = themeProvider.themeMode;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reordered: Light, System, Dark
          _ThemeOption(
            icon: Icons.light_mode,
            tooltip: 'Light',
            isSelected: currentMode == ThemeMode.light,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
          ),
          _ThemeOption(
            icon: Icons.phone_android,
            tooltip: 'System',
            isSelected: currentMode == ThemeMode.system,
            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
          ),
          _ThemeOption(
            icon: Icons.dark_mode,
            tooltip: 'Dark',
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

/// Individual theme option in the segmented button
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      tooltip: (context) => Text(tooltip),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.background : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}

/// Quick links section widget
class _QuickLinksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Quick Links',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _SettingsListTile(
            icon: Icons.help_outline,
            title: 'How to use database?',
            onTap: () => _launchUrl('https://mantavyam.gitbook.io/vaultscapes/how-to-use-database'),
          ),
          _SettingsListTile(
            icon: Icons.handshake_outlined,
            title: 'How to collaborate?',
            onTap: () => _launchUrl('https://mantavyam.gitbook.io/vaultscapes/how-to-collaborate'),
          ),
          _SettingsListTile(
            icon: Icons.people_outline,
            title: 'Collaborators',
            onTap: () => _launchUrl('https://mantavyam.gitbook.io/vaultscapes/collaborators'),
          ),
          _SettingsListTile(
            icon: Icons.star_outline,
            title: 'Rate App on Play Store',
            onTap: () {
              showToast(
                context: context,
                builder: (context, overlay) {
                  return SurfaceCard(
                    child: Basic(
                      title: const Text('Coming soon'),
                      subtitle: const Text('Play Store review will be available after release'),
                      trailing: IconButton.ghost(
                        icon: const Icon(Icons.close),
                        onPressed: () => overlay.close(),
                      ),
                    ),
                  );
                },
                location: ToastLocation.bottomCenter,
              );
            },
          ),
          _SettingsListTile(
            icon: Icons.description,
            title: 'Privacy Policy',
            onTap: () => context.push('/main/home/privacy-policy'),
          ),
          _SettingsListTile(
            icon: Icons.policy,
            title: 'Terms of Service',
            onTap: () => context.push('/main/home/terms-of-service'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// App info section widget
class _AppInfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Use app icon from assets
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/launcher.png',
                  width: 60,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school,
                        color: theme.colorScheme.primaryForeground,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version ${AppConstants.appVersion}',
                style: TextStyle(
                  color: theme.colorScheme.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'An Open Source Database for Collaborating at an Institution, Created with <3 by Mantavyam Studios (INDIA) Ltd.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.mutedForeground,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings list tile widget
class _SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Clickable(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
