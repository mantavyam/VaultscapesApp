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
      viewportFraction: 0.85,
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
            _currentPhraseIndex = (_currentPhraseIndex + 1) % _rotatingPhrases.length;
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
    return Scaffold(
      child: _buildBody(context),
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section with rotating text
              _buildGreetingSection(context, authProvider, theme),
              const SizedBox(height: 24),
              // Swipeable Semester Cards
              _buildSemesterCarousel(context, navProvider),
              const SizedBox(height: 16),
              // Dot Indicator
              _buildDotIndicator(navProvider.semesters.length),
              const SizedBox(height: 24), // Reduced bottom padding for full-height cards
            ],
          ),
        );
      },
    );
  }

  Widget _buildGreetingSection(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    final userName = authProvider.isAuthenticated 
        ? authProvider.user?.displayName 
        : null;
    
    // Split greeting for name on newline if name is long
    final greeting = Helpers.getGreeting(name: null);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Greeting text
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // User name on new line if authenticated (bigger than greeting)
          if (userName != null && userName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              userName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Rotating phrase with progress indicator
          Row(
            children: [
              // Radial progress indicator
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _phraseProgress,
                  strokeWidth: 2,
                  backgroundColor: theme.colorScheme.muted,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
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
                      fontSize: 15,
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

  Widget _buildSemesterCarousel(BuildContext context, NavigationProvider navProvider) {
    final semesters = navProvider.semesters;
    
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
                    scale = (1 - (pageOffset.abs() * 0.15)).clamp(0.85, 1.0);
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
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildThemedSemesterCard(context, semester),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Build a theme-based semester card (SYNERGY card styling with tilted arrow)
  Widget _buildThemedSemesterCard(BuildContext context, dynamic semester) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate proportional sizes based on card dimensions
        final cardHeight = constraints.maxHeight;
        final cardWidth = constraints.maxWidth;
        final minDimension = cardHeight < cardWidth ? cardHeight : cardWidth;
        
        // Proportional sizing (relative to card height)
        final iconSize = (minDimension * 0.10).clamp(20.0, 32.0);
        final titleFontSize = (minDimension * 0.14).clamp(20.0, 36.0);
        final subtitleFontSize = (minDimension * 0.065).clamp(12.0, 18.0);
        final badgeFontSize = (minDimension * 0.055).clamp(10.0, 16.0);
        final buttonSize = (minDimension * 0.22).clamp(40.0, 64.0);
        final padding = (minDimension * 0.10).clamp(16.0, 32.0);
        final buttonIconSize = buttonSize * 0.42;

        return GestureDetector(
          onTap: () {
            context.push(RouteConstants.semesterPath(semester.id.toString()));
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.border,
                width: 1,
              ),
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
                  maxLines: 2,
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

  Widget _buildDotIndicator(int count) {
    final theme = Theme.of(context);
    
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
            width: isActive ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.muted,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
