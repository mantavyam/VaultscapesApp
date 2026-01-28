import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/swipe_disable_notifier.dart';
import '../../../core/constants/route_constants.dart';
import 'feedback_form_tab.dart';
import 'collaborate_form_tab.dart';
import 'submission_success_screen.dart';

/// Form Spacing Constants following 8-point grid system
class FormSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

/// Form Dimensions
class FormDimensions {
  static const double inputHeight = 56.0;
  static const double buttonHeight = 56.0;
  static const double minTouchTarget = 48.0;
  static const double borderRadius = 8.0;
  static const double cardRadius = 12.0;
  static const double sectionRadius = 16.0;
  static const double maxFormWidth = 640.0;
}

/// Feedback and Collaboration screen with two stacked cards
class SynergyScreen extends StatefulWidget {
  const SynergyScreen({super.key});

  @override
  State<SynergyScreen> createState() => _SynergyScreenState();
}

class _SynergyScreenState extends State<SynergyScreen> {
  String? _selectedSection;
  SubmissionSuccessType? _showSuccess;

  void _updateSwipeState() {
    // Notify parent to disable swipe when inside a form
    // Swipe should be enabled only on the selection screen
    final shouldDisable = _selectedSection != null || _showSuccess != null;
    SwipeDisableNotifier.setSwipeDisabled(context, shouldDisable);
  }

  void _goBack() {
    if (_showSuccess != null) {
      // From success screen, go back to selection
      setState(() {
        _showSuccess = null;
        _selectedSection = null;
      });
    } else if (_selectedSection != null) {
      setState(() => _selectedSection = null);
    }
    // Re-enable swipe when returning to selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSwipeState();
    });
  }

  void _selectSection(String section) {
    setState(() => _selectedSection = section);
    // Disable swipe when entering a form
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSwipeState();
    });
  }

  void _onSubmissionSuccess(SubmissionSuccessType type) {
    setState(() => _showSuccess = type);
    // Keep swipe disabled on success screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSwipeState();
    });
  }

  @override
  void dispose() {
    // Re-enable swipe when this screen is disposed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SwipeDisableNotifier.setSwipeDisabled(context, false);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show success screen if submission was successful
    if (_showSuccess != null) {
      return SubmissionSuccessScreen(type: _showSuccess!, onDone: _goBack);
    }

    return PopScope(
      // When at selection screen (_selectedSection == null), prevent pop
      // to avoid triggering parent PageView navigation
      // The main navigation screen handles app exit when on this tab
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_selectedSection != null) {
            _goBack();
          }
          // If at selection screen, do nothing - main nav handles exit
        }
      },
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Check if user is authenticated for form sections
          if (_selectedSection != null && !authProvider.isAuthenticated) {
            return Scaffold(
              headers: [
                AppBar(
                  leading: [
                    IconButton.ghost(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _goBack,
                    ),
                  ],
                  title: Text(
                    _selectedSection == 'feedback'
                        ? 'Provide Feedback'
                        : 'Collaborate Now',
                  ),
                ),
              ],
              child: _buildAuthBarrier(context, theme),
            );
          }

          return Scaffold(
            headers: _selectedSection != null
                ? [
                    AppBar(
                      leading: [
                        IconButton.ghost(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _goBack,
                        ),
                      ],
                      title: Text(
                        _selectedSection == 'feedback'
                            ? 'Provide Feedback'
                            : 'Collaborate Now',
                      ),
                    ),
                  ]
                : [],
            child: _selectedSection == null
                ? _buildSelectionScreen(theme)
                : _selectedSection == 'feedback'
                ? FeedbackFormTab(
                    onSubmissionSuccess: () =>
                        _onSubmissionSuccess(SubmissionSuccessType.feedback),
                  )
                : CollaborateFormTab(
                    onSubmissionSuccess: () => _onSubmissionSuccess(
                      SubmissionSuccessType.collaboration,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildAuthBarrier(BuildContext context, ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(FormSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon with subtle background
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              const SizedBox(height: FormSpacing.xl),
              Text(
                'Sign In Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.foreground,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FormSpacing.sm),
              Text(
                'This feature is available for free to all logged-in users of Vaultscapes.',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.mutedForeground,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FormSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: FormDimensions.buttonHeight,
                child: PrimaryButton(
                  onPressed: () {
                    // Navigate to welcome screen for authentication
                    context.go(RouteConstants.welcome);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, size: 20),
                      SizedBox(width: FormSpacing.sm),
                      Text(
                        'Sign Up / Login to proceed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionScreen(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(FormSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FormSpacing.md),

              // Feedback Card
              Expanded(
                child: _buildSelectionCard(
                  context: context,
                  theme: theme,
                  icon: Icons.bolt_rounded,
                  title: 'Provide\nFeedback',
                  subtitle: 'Report · Suggest · Improve',
                  badgeText: 'Help Us Serve You Better',
                  onTap: () => _selectSection('feedback'),
                ),
              ),

              const SizedBox(height: FormSpacing.md),

              // Collaborate Card
              Expanded(
                child: _buildSelectionCard(
                  context: context,
                  theme: theme,
                  icon: Icons.handshake_rounded,
                  title: 'Collaborate\nNow',
                  subtitle: 'Submit · Share · Contribute',
                  badgeText: 'Join the Community',
                  onTap: () => _selectSection('collaborate'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final cardWidth = constraints.maxWidth;
        final minDimension = cardHeight < cardWidth ? cardHeight : cardWidth;

        // Proportional sizing (relative to card height)
        final iconSize = (minDimension * 0.12).clamp(24.0, 36.0);
        final titleFontSize = (minDimension * 0.14).clamp(22.0, 38.0);
        final subtitleFontSize = (minDimension * 0.06).clamp(12.0, 16.0);
        final badgeFontSize = (minDimension * 0.05).clamp(10.0, 14.0);
        final buttonSize = (minDimension * 0.20).clamp(44.0, 60.0);
        final padding = (minDimension * 0.10).clamp(20.0, 32.0);
        final buttonIconSize = buttonSize * 0.45;

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              borderRadius: BorderRadius.circular(FormSpacing.lg),
              border: Border.all(color: theme.colorScheme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top-left icon
                Icon(icon, size: iconSize, color: theme.colorScheme.foreground),

                const Spacer(flex: 2),

                // Title section
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.foreground,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: minDimension * 0.03),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.mutedForeground,
                    letterSpacing: 0.3,
                  ),
                ),

                const Spacer(flex: 1),

                // Bottom row with badge and circle button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bottom-left badge
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.6,
                          vertical: padding * 0.35,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    SizedBox(width: padding * 0.5),

                    // Bottom-right circle button with tilted arrow
                    Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Transform.rotate(
                        angle: -math.pi / 4, // -45 degrees (tilted up-right)
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: buttonIconSize,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
