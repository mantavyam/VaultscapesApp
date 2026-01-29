import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/swipe_disable_notifier.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/responsive/responsive.dart';
import 'feedback_form_tab.dart';
import 'collaborate_form_tab.dart';
import 'submission_success_screen.dart';

/// Form Spacing Constants following 8-point grid system
/// Use ResponsiveFormSpacing for responsive values
class FormSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  /// Get responsive spacing based on window size
  static double responsive(double baseValue, WindowSize windowSize) {
    if (windowSize.isMicro) return baseValue * 0.7;
    if (windowSize.isCompact) return baseValue * 0.85;
    return baseValue;
  }
}

/// Form Dimensions - Use ResponsiveFormDimensions for responsive values
class FormDimensions {
  static const double inputHeight = 56.0;
  static const double buttonHeight = 56.0;
  static const double minTouchTarget = 48.0;
  static const double borderRadius = 8.0;
  static const double cardRadius = 12.0;
  static const double sectionRadius = 16.0;
  static const double maxFormWidth = 640.0;

  /// Get responsive max form width based on window size
  static double getMaxFormWidth(WindowSize windowSize) {
    if (windowSize.isMicro) return double.infinity;
    if (windowSize.isCompact) return 480.0;
    if (windowSize.isMedium) return 560.0;
    return maxFormWidth;
  }

  /// Get responsive input height
  static double getInputHeight(WindowSize windowSize) {
    if (windowSize.isMicro) return 48.0;
    if (windowSize.isCompact) return 52.0;
    return inputHeight;
  }

  /// Get responsive button height
  static double getButtonHeight(WindowSize windowSize) {
    if (windowSize.isMicro) return 48.0;
    if (windowSize.isCompact) return 52.0;
    return buttonHeight;
  }
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

    return ResponsiveBuilder(
      builder: (context, windowSize) {
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
                  child: _buildAuthBarrier(context, theme, windowSize),
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
                    ? _buildSelectionScreen(theme, windowSize)
                    : _selectedSection == 'feedback'
                    ? FeedbackFormTab(
                        onSubmissionSuccess: () => _onSubmissionSuccess(
                          SubmissionSuccessType.feedback,
                        ),
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
      },
    );
  }

  Widget _buildAuthBarrier(
    BuildContext context,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    // Responsive sizing
    final maxWidth = windowSize.isMicro ? double.infinity : 400.0;
    final iconContainerSize = windowSize.isMicro ? 72.0 : 96.0;
    final iconSize = windowSize.isMicro ? 36.0 : 48.0;
    final titleFontSize = windowSize.isMicro ? 20.0 : 24.0;
    final subtitleFontSize = windowSize.isMicro ? 13.0 : 15.0;
    final buttonHeight = FormDimensions.getButtonHeight(windowSize);
    final padding = FormSpacing.responsive(FormSpacing.xl, windowSize);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon with subtle background
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: iconSize,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              SizedBox(
                height: FormSpacing.responsive(FormSpacing.xl, windowSize),
              ),
              Text(
                'Sign In Required',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.foreground,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: FormSpacing.responsive(FormSpacing.sm, windowSize),
              ),
              Text(
                windowSize.isMicro
                    ? 'Sign in to access this feature.'
                    : 'This feature is available for free to all logged-in users of Vaultscapes.',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: theme.colorScheme.mutedForeground,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: FormSpacing.responsive(FormSpacing.xl, windowSize),
              ),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: PrimaryButton(
                  onPressed: () {
                    // Navigate to welcome screen for authentication
                    context.go(RouteConstants.welcome);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: windowSize.isMicro ? 18 : 20,
                      ),
                      SizedBox(
                        width: FormSpacing.responsive(
                          FormSpacing.sm,
                          windowSize,
                        ),
                      ),
                      Text(
                        windowSize.isMicro
                            ? 'Sign In'
                            : 'Sign Up / Login to proceed',
                        style: TextStyle(
                          fontSize: windowSize.isMicro ? 14.0 : 16.0,
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

  Widget _buildSelectionScreen(ThemeData theme, WindowSize windowSize) {
    // Responsive padding
    final outerPadding = FormSpacing.responsive(FormSpacing.md, windowSize);
    final cardSpacing = FormSpacing.responsive(FormSpacing.md, windowSize);

    // Use horizontal layout when:
    // 1. Wide viewports (expanded+), OR
    // 2. Height is compressed (landscape/split-screen)
    final useHorizontalLayout =
        windowSize.isWide || windowSize.isHeightCompressed;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (useHorizontalLayout) {
          // Horizontal layout for wide viewports or compressed height
          final isCompressed = windowSize.isHeightCompressed;
          return Padding(
            padding: EdgeInsets.all(isCompressed ? 8.0 : outerPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Feedback Card
                Expanded(
                  child: _buildSelectionCard(
                    context: context,
                    theme: theme,
                    windowSize: windowSize,
                    icon: Icons.bolt_rounded,
                    title: isCompressed ? 'Feedback' : 'Provide\nFeedback',
                    subtitle: isCompressed
                        ? 'Report · Suggest'
                        : 'Report · Suggest · Improve',
                    badgeText: isCompressed
                        ? 'Help Us'
                        : 'Help Us Serve You Better',
                    onTap: () => _selectSection('feedback'),
                  ),
                ),
                SizedBox(width: isCompressed ? 8.0 : cardSpacing),
                // Collaborate Card
                Expanded(
                  child: _buildSelectionCard(
                    context: context,
                    theme: theme,
                    windowSize: windowSize,
                    icon: Icons.handshake_rounded,
                    title: isCompressed ? 'Collaborate' : 'Collaborate\nNow',
                    subtitle: isCompressed
                        ? 'Submit · Share'
                        : 'Submit · Share · Contribute',
                    badgeText: isCompressed ? 'Join In' : 'Join the Community',
                    onTap: () => _selectSection('collaborate'),
                  ),
                ),
              ],
            ),
          );
        }

        // Default vertical layout
        return Padding(
          padding: EdgeInsets.all(outerPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: cardSpacing),

              // Feedback Card
              Expanded(
                child: _buildSelectionCard(
                  context: context,
                  theme: theme,
                  windowSize: windowSize,
                  icon: Icons.bolt_rounded,
                  title: windowSize.isMicro
                      ? 'Provide Feedback'
                      : 'Provide\nFeedback',
                  subtitle: windowSize.isMicro
                      ? 'Report · Suggest'
                      : 'Report · Suggest · Improve',
                  badgeText: windowSize.isMicro
                      ? 'Help Us'
                      : 'Help Us Serve You Better',
                  onTap: () => _selectSection('feedback'),
                ),
              ),

              SizedBox(height: cardSpacing),

              // Collaborate Card
              Expanded(
                child: _buildSelectionCard(
                  context: context,
                  theme: theme,
                  windowSize: windowSize,
                  icon: Icons.handshake_rounded,
                  title: windowSize.isMicro
                      ? 'Collaborate Now'
                      : 'Collaborate\nNow',
                  subtitle: windowSize.isMicro
                      ? 'Submit · Share'
                      : 'Submit · Share · Contribute',
                  badgeText: windowSize.isMicro
                      ? 'Join In'
                      : 'Join the Community',
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
    required WindowSize windowSize,
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

        // Responsive adjustments for micro viewports
        final baseSizeFactor = windowSize.isMicro ? 0.85 : 1.0;

        // Proportional sizing (relative to card height)
        final iconSize = (minDimension * 0.12 * baseSizeFactor).clamp(
          20.0,
          36.0,
        );
        final titleFontSize = (minDimension * 0.14 * baseSizeFactor).clamp(
          18.0,
          38.0,
        );
        final subtitleFontSize = (minDimension * 0.06 * baseSizeFactor).clamp(
          10.0,
          16.0,
        );
        final badgeFontSize = (minDimension * 0.05 * baseSizeFactor).clamp(
          9.0,
          14.0,
        );
        final buttonSize = (minDimension * 0.20 * baseSizeFactor).clamp(
          36.0,
          60.0,
        );
        final padding = (minDimension * 0.10 * baseSizeFactor).clamp(
          12.0,
          32.0,
        );
        final buttonIconSize = buttonSize * 0.45;

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(
              windowSize.isHeightCompressed ? padding * 0.75 : padding,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              borderRadius: BorderRadius.circular(
                FormSpacing.responsive(FormSpacing.lg, windowSize),
              ),
              border: Border.all(color: theme.colorScheme.border, width: 1),
            ),
            child: windowSize.isHeightCompressed
                ? _buildCompactCardContent(
                    theme: theme,
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    badgeText: badgeText,
                    iconSize: iconSize,
                    titleFontSize: titleFontSize * 0.85,
                    subtitleFontSize: subtitleFontSize,
                    badgeFontSize: badgeFontSize,
                    buttonSize: buttonSize * 0.8,
                    buttonIconSize: buttonIconSize * 0.8,
                    isDark: isDark,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top-left icon
                      Icon(
                        icon,
                        size: iconSize,
                        color: theme.colorScheme.foreground,
                      ),

                      const Spacer(flex: 2),

                      // Title section
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.foreground,
                          height: windowSize.isMicro ? 1.15 : 1.05,
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
                              angle:
                                  -math.pi / 4, // -45 degrees (tilted up-right)
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

  /// Build compact card content for compressed height layouts
  Widget _buildCompactCardContent({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required double iconSize,
    required double titleFontSize,
    required double subtitleFontSize,
    required double badgeFontSize,
    required double buttonSize,
    required double buttonIconSize,
    required bool isDark,
  }) {
    // Simplified layout without Spacers for compressed height
    return Row(
      children: [
        // Left side: Icon + Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize * 0.8,
                color: theme.colorScheme.foreground,
              ),
              const SizedBox(height: 4),
              Text(
                title.replaceAll('\n', ' '),
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.foreground,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleFontSize * 0.9,
                  color: theme.colorScheme.mutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Right side: Arrow button
        Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            shape: BoxShape.circle,
          ),
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: Icon(
              Icons.arrow_forward_rounded,
              size: buttonIconSize,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
