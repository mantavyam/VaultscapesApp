import 'dart:async';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/responsive/responsive.dart';

/// List of rotating motivational phrases (4 specific ones, 10s rotation)
const List<String> _rotatingPhrases = [
  'Did you checked out today\'s AI News?',
  'Collaborate Qs Paper, Notes and More with us',
  'Please Provide Feedback about your Experience',
  'What would you like to study today?',
  'Have you ever thought of building a Startup?',
];

/// Root homepage screen displaying semester cards with swipeable carousel
class RootHomepageScreen extends StatefulWidget {
  const RootHomepageScreen({super.key});

  @override
  State<RootHomepageScreen> createState() => _RootHomepageScreenState();
}

class _RootHomepageScreenState extends State<RootHomepageScreen> {
  int _currentSemesterIndex = 0;
  int _currentPhraseIndex = 0;
  late PageController _pageController;
  Timer? _phraseTimer;
  double _phraseProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85, // Will be updated dynamically in build
      initialPage: 0,
    );
    _startPhraseRotation();
  }

  void _startPhraseRotation() {
    // Reset progress
    _phraseProgress = 0.0;

    // Progress timer - updates every 50ms for smooth animation
    // 10 second rotation: 50ms * 200 = 10000ms = 10 seconds
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _phraseProgress += 0.005; // 50ms * 200 = 10000ms = 10 seconds
          if (_phraseProgress >= 1.0) {
            _phraseProgress = 0.0;
            _currentPhraseIndex =
                (_currentPhraseIndex + 1) % _rotatingPhrases.length;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phraseTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No AppBar - removed as requested
    return Scaffold(child: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    return Consumer2<AuthProvider, NavigationProvider>(
      builder: (context, authProvider, navProvider, child) {
        final theme = Theme.of(context);

        if (navProvider.isLoading && navProvider.semesters.isEmpty) {
          return const LoadingIndicator(message: 'Loading semesters...');
        }

        if (navProvider.errorMessage != null && navProvider.semesters.isEmpty) {
          return AppErrorWidget.generic(
            message: navProvider.errorMessage,
            onRetry: () => navProvider.loadSemesters(),
          );
        }

        return SafeArea(
          child: ResponsiveBuilder(
            builder: (context, windowSize) {
              // Use horizontal layout when height is compressed (landscape/split-screen)
              if (windowSize.isHeightCompressed) {
                return _buildLandscapeLayout(
                  context,
                  authProvider,
                  navProvider,
                  theme,
                  windowSize,
                );
              }

              // Adaptive spacing based on viewport
              final greetingBottomSpacing = windowSize.isMicro ? 16.0 : 24.0;
              final carouselBottomSpacing = windowSize.isMicro ? 12.0 : 16.0;
              final bottomPadding = windowSize.isMicro ? 16.0 : 24.0;
              final showDots = ResponsiveLayout.shouldShowDotIndicators(
                context,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Section with rotating text
                  _buildGreetingSection(
                    context,
                    authProvider,
                    theme,
                    windowSize,
                  ),
                  SizedBox(height: greetingBottomSpacing),
                  // Swipeable Semester Cards or Grid based on viewport
                  _buildSemesterCarousel(context, navProvider, windowSize),
                  SizedBox(height: carouselBottomSpacing),
                  // Dot Indicator (hidden in very narrow viewports)
                  if (showDots)
                    _buildDotIndicator(
                      navProvider.semesters.length,
                      windowSize,
                    ),
                  SizedBox(height: bottomPadding),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGreetingSection(
    BuildContext context,
    AuthProvider authProvider,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    final userName = authProvider.isAuthenticated
        ? authProvider.user?.displayName
        : null;

    // Split greeting for name on newline if name is long
    final greeting = Helpers.getGreeting(name: null);

    // Responsive sizing
    final horizontalPadding = windowSize.isMicro ? 16.0 : 20.0;
    final topPadding = windowSize.isMicro ? 12.0 : 16.0;
    final greetingFontSize = windowSize.isMicro ? 20.0 : 24.0;
    final nameFontSize = windowSize.isMicro ? 26.0 : 32.0;
    final phraseFontSize = (windowSize.width * 0.04).clamp(13.0, 16.0);
    final progressIndicatorSize = windowSize.isMicro ? 16.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: windowSize.isMicro ? 4 : 8),
          // Greeting text
          Text(
            greeting,
            style: TextStyle(
              fontSize: greetingFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          // User name on new line if authenticated (bigger than greeting)
          if (userName != null && userName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              userName,
              style: TextStyle(
                fontSize: nameFontSize,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          SizedBox(height: windowSize.isMicro ? 8 : 12),
          // Rotating phrase with progress indicator
          Row(
            children: [
              // Radial progress indicator
              SizedBox(
                width: progressIndicatorSize,
                height: progressIndicatorSize,
                child: CircularProgressIndicator(
                  value: _phraseProgress,
                  strokeWidth: windowSize.isMicro ? 1.5 : 2,
                  backgroundColor: theme.colorScheme.muted,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: windowSize.isMicro ? 8 : 12),
              // Animated phrase
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _rotatingPhrases[_currentPhraseIndex],
                    key: ValueKey<int>(_currentPhraseIndex),
                    style: TextStyle(
                      color: theme.colorScheme.mutedForeground,
                      fontSize: phraseFontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterCarousel(
    BuildContext context,
    NavigationProvider navProvider,
    WindowSize windowSize,
  ) {
    final semesters = navProvider.semesters;

    // Calculate viewport fraction based on window size
    final viewportFraction =
        ResponsiveLayout.getCarouselViewportFractionFromSize(windowSize);

    // Update page controller if viewport fraction changed significantly
    if ((_pageController.viewportFraction - viewportFraction).abs() > 0.01) {
      // Recreate controller with new viewport fraction on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final currentPage =
              _pageController.hasClients &&
                  _pageController.position.hasContentDimensions
              ? _pageController.page?.round() ?? _currentSemesterIndex
              : _currentSemesterIndex;
          setState(() {
            _pageController = PageController(
              viewportFraction: viewportFraction,
              initialPage: currentPage,
            );
          });
        }
      });
    }

    // Responsive horizontal padding
    final horizontalPadding = windowSize.isMicro ? 4.0 : 8.0;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamic card height based on available viewport - fill completely
          final availableHeight = constraints.maxHeight;
          final cardHeight = availableHeight; // Use 100% of available height

          return PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentSemesterIndex = index;
              });
            },
            itemCount: semesters.length,
            itemBuilder: (context, index) {
              final semester = semesters[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  double opacity = 1.0;
                  if (_pageController.position.haveDimensions) {
                    final pageOffset = _pageController.page! - index;
                    // Non-active cards are 85% height, active card is 100%
                    // In micro mode, reduce the scale difference for tighter spacing
                    final scaleReduction = windowSize.isMicro ? 0.10 : 0.15;
                    scale = (1 - (pageOffset.abs() * scaleReduction)).clamp(
                      0.85,
                      1.0,
                    );
                    // Slight opacity fade for non-active cards
                    opacity = (1 - (pageOffset.abs() * 0.2)).clamp(0.7, 1.0);
                  }
                  return Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      height: scale * cardHeight,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: opacity,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildThemedSemesterCard(
                    context,
                    semester,
                    windowSize,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Build a theme-based semester card (SYNERGY card styling with tilted arrow)
  Widget _buildThemedSemesterCard(
    BuildContext context,
    dynamic semester,
    WindowSize windowSize,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate proportional sizes based on card dimensions
        final cardHeight = constraints.maxHeight;
        final cardWidth = constraints.maxWidth;
        final minDimension = cardHeight < cardWidth ? cardHeight : cardWidth;

        // Adjust proportions for micro viewport
        final proportionMultiplier = windowSize.isMicro ? 0.9 : 1.0;

        // Proportional sizing (relative to card height)
        final iconSize = (minDimension * 0.10 * proportionMultiplier).clamp(
          18.0,
          32.0,
        );
        final titleFontSize = (minDimension * 0.14 * proportionMultiplier)
            .clamp(18.0, 36.0);
        final subtitleFontSize = (minDimension * 0.065 * proportionMultiplier)
            .clamp(11.0, 18.0);
        final badgeFontSize = (minDimension * 0.055 * proportionMultiplier)
            .clamp(9.0, 16.0);
        final buttonSize = (minDimension * 0.22 * proportionMultiplier).clamp(
          36.0,
          64.0,
        );
        final padding = (minDimension * 0.10 * proportionMultiplier).clamp(
          12.0,
          32.0,
        );
        final buttonIconSize = buttonSize * 0.42;
        final borderRadius = windowSize.isMicro ? 24.0 : 32.0;

        return GestureDetector(
          onTap: () {
            context.push(RouteConstants.semesterPath(semester.id.toString()));
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: theme.colorScheme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top-left icon (book icon for semester)
                Icon(
                  Icons.book_outlined,
                  size: iconSize,
                  color: theme.colorScheme.foreground,
                ),

                // Flexible spacer to push content down
                const Spacer(flex: 2),

                // Title section (Semester name)
                Text(
                  semester.name,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.foreground,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: minDimension * 0.025),
                Text(
                  semester.description,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  maxLines: windowSize.isMicro ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Flexible spacer before bottom row
                const Spacer(flex: 1),

                // Bottom row with badge and circle button (tilted arrow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Bottom-left badge (subject count)
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.5,
                          vertical: padding * 0.3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${semester.allSubjects.length} subjects',
                          style: TextStyle(
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.w500,
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
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_outward,
                        size: buttonIconSize,
                        color: isDark ? Colors.black : Colors.white,
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

  Widget _buildDotIndicator(int count, WindowSize windowSize) {
    final theme = Theme.of(context);

    // Responsive sizing for dot indicators
    final dotHeight = windowSize.isMicro ? 6.0 : 8.0;
    final activeWidth = windowSize.isMicro ? 18.0 : 24.0;
    final inactiveWidth = windowSize.isMicro ? 6.0 : 8.0;
    final horizontalMargin = windowSize.isMicro ? 3.0 : 4.0;
    final borderRadius = windowSize.isMicro ? 3.0 : 4.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentSemesterIndex;
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? activeWidth : inactiveWidth,
            height: dotHeight,
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        );
      }),
    );
  }

  /// Landscape/compressed-height layout with horizontal card list
  Widget _buildLandscapeLayout(
    BuildContext context,
    AuthProvider authProvider,
    NavigationProvider navProvider,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    final semesters = navProvider.semesters;
    final userName = authProvider.isAuthenticated
        ? authProvider.user?.displayName
        : null;
    // Don't pass name to getGreeting since we display it separately below
    final greeting = Helpers.getGreeting();

    return Row(
      children: [
        // Left side - Greeting (narrower in landscape)
        SizedBox(
          width: windowSize.width * 0.28,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                if (userName != null && userName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                // Rotating phrase (compact version)
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        value: _phraseProgress,
                        strokeWidth: 1.5,
                        backgroundColor: theme.colorScheme.muted,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _rotatingPhrases[_currentPhraseIndex],
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Divider
        Container(width: 1, color: theme.colorScheme.border),
        // Right side - Horizontal scrolling semester cards
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: semesters.length,
            itemBuilder: (context, index) {
              final semester = semesters[index];
              return _buildLandscapeSemesterCard(
                context,
                semester,
                theme,
                windowSize,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build compact semester card for landscape layout
  Widget _buildLandscapeSemesterCard(
    BuildContext context,
    dynamic semester,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final cardWidth = windowSize.width * 0.35; // Cards take 35% of width

    return Container(
      width: cardWidth.clamp(180.0, 280.0),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          context.push(RouteConstants.semesterPath(semester.id.toString()));
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with icon and arrow button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 18,
                    color: theme.colorScheme.foreground,
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_outward,
                      size: 14,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Title
              Text(
                semester.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                semester.description,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.mutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${semester.subjectCount} Subjects',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
