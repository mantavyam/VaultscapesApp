import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../widgets/common/animated_gradient_border.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/responsive/responsive.dart';
import 'edit_profile_dialog.dart';

/// Profile screen with guest/authenticated views
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, windowSize) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Scaffold(
              child: authProvider.isAuthenticated
                  ? _AuthenticatedProfileView(authProvider: authProvider, windowSize: windowSize)
                  : _GuestProfileView(windowSize: windowSize),
            );
          },
        );
      },
    );
  }
}

/// Guest profile view
class _GuestProfileView extends StatelessWidget {
  final WindowSize windowSize;
  
  const _GuestProfileView({required this.windowSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Responsive sizing
    final padding = windowSize.isMicro ? 12.0 : 16.0;
    final topSpacing = windowSize.isMicro ? 24.0 : 40.0;
    final avatarSize = windowSize.isMicro ? 80.0 : 100.0;
    final avatarIconSize = windowSize.isMicro ? 40.0 : 50.0;
    final nameFontSize = windowSize.isMicro ? 20.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          SizedBox(height: topSpacing),
          // Guest Avatar using RadixIcons.avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              RadixIcons.avatar,
              size: avatarIconSize,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Guest User',
            style: TextStyle(fontSize: nameFontSize, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            windowSize.isMicro ? 'Sign in to unlock features' : 'Sign in to unlock all features',
            style: TextStyle(color: theme.colorScheme.mutedForeground),
          ),
          const SizedBox(height: 24),

          // Sign In Button - triggers auth flow directly
          PrimaryButton(
            onPressed: () => _signInWithGoogle(context),
            child: const Text('Sign In'),
          ),
          SizedBox(height: topSpacing),

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

  /// Navigate to welcome screen for authentication
  void _signInWithGoogle(BuildContext context) {
    context.go(RouteConstants.welcome);
  }

  Widget _buildSettingsSection(BuildContext context) {
    return _SettingsSection(windowSize: windowSize);
  }

  Widget _buildQuickLinksSection(BuildContext context) {
    return _QuickLinksSection(windowSize: windowSize);
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return _AppInfoSection(windowSize: windowSize);
  }
}

/// Authenticated profile view
class _AuthenticatedProfileView extends StatelessWidget {
  final AuthProvider authProvider;
  final WindowSize windowSize;

  const _AuthenticatedProfileView({required this.authProvider, required this.windowSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authProvider.user;
    final photoUrl = user?.photoUrl;
    
    // Responsive sizing
    final padding = windowSize.isMicro ? 12.0 : 16.0;
    final topSpacing = windowSize.isMicro ? 12.0 : 20.0;
    final avatarSize = windowSize.isMicro ? 80.0 : 100.0;
    final initialFontSize = windowSize.isMicro ? 32.0 : 40.0;
    final nameFontSize = windowSize.isMicro ? 20.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          SizedBox(height: topSpacing),
          // Profile Avatar with animated gradient border
          AnimatedGradientBorder(
            size: avatarSize,
            borderWidth: 3,
            animationDuration: const Duration(seconds: 3),
            child: photoUrl != null && photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: avatarSize,
                        height: avatarSize,
                        color: theme.colorScheme.primary,
                        child: Center(
                          child: Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ??
                                'U',
                            style: TextStyle(
                              fontSize: initialFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: avatarSize,
                    height: avatarSize,
                    color: theme.colorScheme.primary,
                    child: Center(
                      child: Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: initialFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // User Name with Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user?.displayName ?? 'User',
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.ghost(
                icon: Icon(Icons.edit, size: windowSize.isMicro ? 18 : 20),
                onPressed: () => _showEditProfileDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              color: theme.colorScheme.mutedForeground,
              fontSize: windowSize.isMicro ? 12.0 : 14.0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),

          // Settings Section
          _SettingsSection(windowSize: windowSize),
          const SizedBox(height: 24),

          // Quick Links Section
          _QuickLinksSection(windowSize: windowSize),
          const SizedBox(height: 24),

          // App Info Section
          _AppInfoSection(windowSize: windowSize),
          const SizedBox(height: 24),

          // Logout Button - Outlined red style
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _showLogoutConfirmation(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: windowSize.isMicro ? 10 : 12,
                  horizontal: windowSize.isMicro ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFDC2626),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: const Color(0xFFDC2626), size: windowSize.isMicro ? 18 : 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                        fontSize: windowSize.isMicro ? 13 : 14,
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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            OutlineButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            GestureDetector(
              onTap: () async {
                // Check internet connectivity first
                final connectivityService = ConnectivityService();
                final isConnected = await connectivityService
                    .checkConnectivity();

                if (!isConnected) {
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    showToast(
                      context: context,
                      builder: (context, overlay) {
                        return SurfaceCard(
                          child: Basic(
                            title: const Text('No Internet Connection'),
                            content: const Text(
                              'Please connect to the internet to sign out.',
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

                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                await authProvider.signOut();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
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
  final WindowSize windowSize;
  
  const _SettingsSection({required this.windowSize});
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    
    // Responsive sizing
    final sectionPadding = windowSize.isMicro ? 12.0 : 16.0;
    final titleFontSize = windowSize.isMicro ? 16.0 : 18.0;
    final themePaddingH = windowSize.isMicro ? 12.0 : 16.0;
    final themePaddingV = windowSize.isMicro ? 10.0 : 12.0;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(sectionPadding),
            child: Text(
              'Management',
              style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
            ),
          ),
          // Your Collaboration tile
          _SettingsListTile(
            icon: Icons.upload_file_outlined,
            title: 'Your Collaborations',
            subtitle: windowSize.isMicro ? 'View contributions' : 'View your submitted contributions',
            onTap: () => _navigateToCollaborationHistory(context),
            windowSize: windowSize,
          ),
          // Your Feedback tile
          _SettingsListTile(
            icon: Icons.feedback_outlined,
            title: 'Your Feedback',
            subtitle: windowSize.isMicro ? 'View feedback' : 'View your submitted feedback',
            onTap: () => _navigateToFeedbackHistory(context),
            windowSize: windowSize,
          ),
          // Inline Theme Selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: themePaddingH, vertical: themePaddingV),
            child: Row(
              children: [
                Icon(
                  LucideIcons.cloudMoon,
                  color: theme.colorScheme.mutedForeground,
                  size: windowSize.isMicro ? 20 : 24,
                ),
                SizedBox(width: windowSize.isMicro ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: windowSize.isMicro ? 13 : 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Set Preference',
                        style: TextStyle(
                          fontSize: windowSize.isMicro ? 11 : 12,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                // Segmented button for theme selection
                _ThemeSegmentedButton(themeProvider: themeProvider, windowSize: windowSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCollaborationHistory(BuildContext context) {
    context.push('/main/profile/collaboration-history');
  }

  void _navigateToFeedbackHistory(BuildContext context) {
    context.push('/main/profile/feedback-history');
  }
}

/// Theme segmented button widget
class _ThemeSegmentedButton extends StatelessWidget {
  final ThemeProvider themeProvider;
  final WindowSize windowSize;

  const _ThemeSegmentedButton({required this.themeProvider, required this.windowSize});

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
            color: isSelected
                ? theme.colorScheme.background
                : Colors.transparent,
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
  final WindowSize windowSize;
  
  const _QuickLinksSection({required this.windowSize});
  
  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final sectionPadding = windowSize.isMicro ? 12.0 : 16.0;
    final titleFontSize = windowSize.isMicro ? 16.0 : 18.0;
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(sectionPadding),
            child: Text(
              'Quick Links',
              style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
            ),
          ),
          _SettingsListTile(
            icon: BootstrapIcons.discord,
            title: 'Join your friends',
            onTap: () => _launchUrl('https://discord.com/invite/AQ7PNzdCnC'),
            windowSize: windowSize,
          ),
          _SettingsListTile(
            icon: Icons.people_outline,
            title: 'Collaborators',
            onTap: () => _launchUrl(
              'https://mantavyam.gitbook.io/vaultscapes/collaborators',
            ),
            windowSize: windowSize,
          ),
          _SettingsListTile(
            icon: Icons.help_outline,
            title: windowSize.isMicro ? 'How to use?' : 'How to use database?',
            onTap: () => _launchUrl(
              'https://mantavyam.gitbook.io/vaultscapes/how-to-use-database',
            ),
            windowSize: windowSize,
          ),
          _SettingsListTile(
            icon: Icons.handshake_outlined,
            title: windowSize.isMicro ? 'How to collaborate?' : 'How to collaborate?',
            onTap: () => _launchUrl(
              'https://mantavyam.gitbook.io/vaultscapes/how-to-collaborate',
            ),
            windowSize: windowSize,
          ),
          _SettingsListTile(
            icon: BootstrapIcons.github,
            title: 'Star Repo on Github',
            onTap: () =>
                _launchUrl('https://github.com/mantavyam/vaultscapesDB'),
            windowSize: windowSize,
          ),
          _SettingsListTile(
            icon: BootstrapIcons.googlePlay,
            title: 'Rate App on Play Store',
            onTap: () {
              showToast(
                context: context,
                builder: (context, overlay) {
                  return SurfaceCard(
                    child: Basic(
                      title: const Text('Coming soon'),
                      subtitle: const Text(
                        'Play Store review will be available after release',
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
            },
            windowSize: windowSize,
          ),
          _SettingsListTile(
            icon: Icons.description,
            title: 'Privacy Policy',
            onTap: () => context.push('/main/home/privacy-policy'),
            windowSize: windowSize,
          ),
          _SettingsListTile(
            icon: Icons.policy,
            title: 'Terms of Service',
            onTap: () => context.push('/main/home/terms-of-service'),
            windowSize: windowSize,
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
  final WindowSize windowSize;
  
  const _AppInfoSection({required this.windowSize});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Responsive sizing
    final padding = windowSize.isMicro ? 12.0 : 16.0;
    final iconSize = windowSize.isMicro ? 48.0 : 60.0;
    final fallbackIconSize = windowSize.isMicro ? 24.0 : 30.0;
    final titleFontSize = windowSize.isMicro ? 16.0 : 18.0;
    final descFontSize = windowSize.isMicro ? 11.0 : 12.0;

    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // Use app icon from assets
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/launcher.png',
                  width: iconSize,
                  height: iconSize,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school,
                        color: theme.colorScheme.primaryForeground,
                        size: fallbackIconSize,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppConstants.appName,
                style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Version ${AppConstants.appVersion}',
                style: TextStyle(
                  color: theme.colorScheme.mutedForeground,
                  fontWeight: FontWeight.w500,
                  fontSize: windowSize.isMicro ? 12.0 : 14.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                windowSize.isMicro 
                    ? 'Open Source Database by Mantavyam Studios'
                    : 'An Open Source Database for Collaborating at an Institution, Created with <3 by Mantavyam Studios (INDIA) Ltd.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.mutedForeground,
                  fontSize: descFontSize,
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
  final WindowSize windowSize;

  const _SettingsListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.windowSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Responsive sizing
    final paddingH = windowSize.isMicro ? 12.0 : 16.0;
    final paddingV = windowSize.isMicro ? 10.0 : 12.0;
    final iconSize = windowSize.isMicro ? 20.0 : 24.0;
    final titleFontSize = windowSize.isMicro ? 13.0 : 14.0;
    final subtitleFontSize = windowSize.isMicro ? 11.0 : 12.0;
    final iconSpacing = windowSize.isMicro ? 12.0 : 16.0;

    return Clickable(
      onPressed: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.mutedForeground, size: iconSize),
            SizedBox(width: iconSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: titleFontSize,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.mutedForeground, size: iconSize),
          ],
        ),
      ),
    );
  }
}
