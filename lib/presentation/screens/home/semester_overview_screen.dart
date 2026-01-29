import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/cards/subject_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../../data/models/semester_model.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/responsive/responsive.dart';

/// Semester overview screen displaying subjects in a semester
/// Uses PageView for natural swipe navigation between semesters (like main app screens)
/// Includes hamburger sidebar for quick navigation to overview and subjects
class SemesterOverviewScreen extends StatefulWidget {
  final String semesterId;

  const SemesterOverviewScreen({super.key, required this.semesterId});

  @override
  State<SemesterOverviewScreen> createState() => _SemesterOverviewScreenState();
}

class _SemesterOverviewScreenState extends State<SemesterOverviewScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late ScrollController _scrollController;
  int _currentPageIndex = 0;
  bool _isPageAnimating = false;

  // Sidebar state and animation
  bool _isSidebarOpen = false;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarSlideAnimation;
  late Animation<double> _sidebarFadeAnimation;

  // Track expanded accordion items by subject id
  final Set<String> _expandedAccordionItems = {};

  // For bottom navigation cards animation on scroll
  bool _showNavigationCards = true;
  double _lastScrollOffset = 0;
  bool _hasScrolledDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initialize sidebar animation
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _sidebarSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _sidebarAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _sidebarFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sidebarAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize PageController with default page 0
    // Will be updated in postFrameCallback after semesters are loaded
    _pageController = PageController();

    // Listen to page changes to update appbar only when page actually settles
    _pageController.addListener(_onPageScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semId = int.tryParse(widget.semesterId);
      if (semId != null) {
        context.read<NavigationProvider>().selectSemester(semId);
        // Find the correct page index for this semester
        final navProvider = context.read<NavigationProvider>();
        final semesters = navProvider.semesters;
        final index = semesters.indexWhere((s) => s.id == semId);
        if (index != -1 && index != 0) {
          setState(() {
            _currentPageIndex = index;
          });
          // Jump to the correct page (no animation needed on initial load)
          _pageController.jumpToPage(index);
        } else if (index == 0) {
          setState(() {
            _currentPageIndex = 0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    if (_isSidebarOpen) {
      _closeSidebar();
    } else {
      _openSidebar();
    }
  }

  void _openSidebar() {
    setState(() => _isSidebarOpen = true);
    _sidebarAnimationController.forward();
  }

  void _closeSidebar() {
    _sidebarAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isSidebarOpen = false);
      }
    });
  }

  /// Listen to page scroll and only update index when page has settled
  void _onPageScroll() {
    if (!_pageController.hasClients) return;

    // Only update when the page has fully settled (no partial values)
    final page = _pageController.page;
    if (page != null && page == page.roundToDouble()) {
      final newIndex = page.round();
      if (newIndex != _currentPageIndex) {
        _updateCurrentPage(newIndex);
      }
    }
  }

  void _updateCurrentPage(int index) {
    if (_isPageAnimating) return;

    final navProvider = context.read<NavigationProvider>();
    final semesters = navProvider.semesters;
    if (index >= 0 && index < semesters.length) {
      setState(() {
        _currentPageIndex = index;
      });
      // Update URL without navigating (keeps history clean)
      final semester = semesters[index];
      context.go(RouteConstants.semesterPath(semester.id.toString()));
    }
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;

    // Scrolling down - hide cards (only if we've scrolled down before or now)
    if (currentOffset > _lastScrollOffset && currentOffset > 50) {
      _hasScrolledDown = true;
      if (_showNavigationCards) {
        setState(() => _showNavigationCards = false);
      }
    }
    // Scrolling up - show cards (only if we've scrolled down first)
    else if (currentOffset < _lastScrollOffset && _hasScrolledDown) {
      if (!_showNavigationCards) {
        setState(() => _showNavigationCards = true);
      }
    }

    _lastScrollOffset = currentOffset;
  }

  void _onPageChanged(int index) {
    // Page change is now handled by _onPageScroll listener
    // This callback is kept for compatibility but the actual update
    // only happens when the page has fully settled
  }

  void _navigateToSemester(int index) {
    if (index < 0) return;
    final navProvider = context.read<NavigationProvider>();
    if (index >= navProvider.semesters.length) return;

    setState(() {
      _isPageAnimating = true;
    });

    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          setState(() {
            _isPageAnimating = false;
          });
          // Explicitly update the current page after animation completes
          // This ensures appbar and navigation cards sync when using button navigation
          _updateCurrentPage(index);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        final semesters = navProvider.semesters;

        if (navProvider.isLoading && semesters.isEmpty) {
          return Scaffold(
            headers: [
              AppBar(
                leading: [
                  IconButton.ghost(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                ],
                title: const Text('Loading...'),
              ),
            ],
            child: const LoadingIndicator(),
          );
        }

        if (semesters.isEmpty) {
          return Scaffold(
            headers: [
              AppBar(
                leading: [
                  IconButton.ghost(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                ],
                title: const Text('No Semesters Found'),
              ),
            ],
            child: AppErrorWidget.generic(
              message: 'No semesters available',
              onRetry: () => navProvider.loadSemesters(),
            ),
          );
        }

        // Get previous and next semesters based on current page index
        final previousSemester = _currentPageIndex > 0
            ? semesters[_currentPageIndex - 1]
            : null;
        final nextSemester = _currentPageIndex < semesters.length - 1
            ? semesters[_currentPageIndex + 1]
            : null;
        final currentSemester = _currentPageIndex < semesters.length
            ? semesters[_currentPageIndex]
            : semesters.first;

        final theme = Theme.of(context);

        // Wrap with ResponsiveBuilder for viewport awareness
        return ResponsiveBuilder(
          builder: (context, windowSize) {
            return Stack(
              children: [
                Scaffold(
                  headers: [
                    AppBar(
                      leading: [
                        IconButton.ghost(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.pop(),
                        ),
                      ],
                      title: Text(currentSemester.name),
                      trailing: [
                        // Hamburger menu to show sidebar with navigation
                        IconButton.ghost(
                          icon: Icon(
                            _isSidebarOpen
                                ? RadixIcons.cross1
                                : RadixIcons.hamburgerMenu,
                          ),
                          onPressed: _toggleSidebar,
                        ),
                      ],
                    ),
                  ],
                  child: Stack(
                    children: [
                      // PageView for natural swipe navigation
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        physics: const PageScrollPhysics(),
                        itemCount: semesters.length,
                        itemBuilder: (context, index) {
                          final semester = semesters[index];
                          return _buildSemesterContent(context, semester, windowSize);
                        },
                      ),
                      // Animated bottom navigation cards
                      _buildBottomNavigationCards(
                        context,
                        previousSemester,
                        nextSemester,
                        theme,
                        windowSize,
                      ),
                    ],
                  ),
                ),
                // Animated sidebar overlay
                if (_isSidebarOpen ||
                    _sidebarAnimationController.status == AnimationStatus.reverse)
                  _buildAnimatedSidebar(theme, currentSemester, windowSize),
              ],
            );
          },
        );
      },
    );
  }

  /// Build animated sidebar with slide and fade animation
  Widget _buildAnimatedSidebar(ThemeData theme, SemesterModel semester, WindowSize windowSize) {
    // Responsive sidebar width
    final sidebarWidth = ResponsiveLayout.getSidebarWidth(context);
    
    return AnimatedBuilder(
      animation: _sidebarAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Semi-transparent backdrop with fade animation
            GestureDetector(
              onTap: _closeSidebar,
              child: AnimatedOpacity(
                opacity: _sidebarFadeAnimation.value * 0.3,
                duration: Duration.zero,
                child: Container(color: Colors.black),
              ),
            ),
            // Sidebar with slide animation from right
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(sidebarWidth * _sidebarSlideAnimation.value, 0),
                child: _buildHierarchicalSidebar(theme, semester, windowSize, sidebarWidth),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build hierarchical sidebar with Overview at top, then Core and Specialization subjects
  Widget _buildHierarchicalSidebar(ThemeData theme, SemesterModel semester, WindowSize windowSize, double sidebarWidth) {
    // Get hierarchy for subjects with parent-child relationships
    final hierarchy = semester.subjectHierarchy;
    final topLevelSubjects = semester.topLevelSubjects;

    // Separate core and spec subjects at top level
    final coreTopLevel = topLevelSubjects
        .where((s) => semester.coreSubjects.any((c) => c.id == s.id))
        .toList();
    final specTopLevel = topLevelSubjects
        .where((s) => semester.specializationSubjects.any((c) => c.id == s.id))
        .toList();

    // Responsive sizing
    final headerPadding = windowSize.isMicro ? 12.0 : 16.0;
    final headerIconSize = windowSize.isMicro ? 16.0 : 18.0;
    final headerFontSize = windowSize.isMicro ? 12.0 : 14.0;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(left: BorderSide(color: theme.colorScheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar header
          Container(
            padding: EdgeInsets.all(headerPadding),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  RadixIcons.file,
                  size: headerIconSize,
                  color: theme.colorScheme.foreground,
                ),
                SizedBox(width: windowSize.isMicro ? 8 : 12),
                Expanded(
                  child: Text(
                    windowSize.isMicro ? semester.name : 'Contents - ${semester.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: headerFontSize,
                      color: theme.colorScheme.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton.ghost(
                  icon: const Icon(RadixIcons.cross1),
                  onPressed: _closeSidebar,
                ),
              ],
            ),
          ),
          // Navigation list
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: windowSize.isMicro ? 6 : 8),
              children: [
                // Overview item at the top (highlighted as current page)
                if (semester.overviewGitbookUrl != null) ...[
                  _buildSidebarSectionHeader(theme, 'Overview', windowSize),
                  _buildOverviewItem(theme, semester, windowSize, isSelected: true),
                  SizedBox(height: windowSize.isMicro ? 12 : 16),
                ],
                // Core Subjects Section
                if (coreTopLevel.isNotEmpty) ...[
                  _buildSidebarSectionHeader(theme, 'Core Subjects', windowSize),
                  ..._buildSubjectList(
                    theme,
                    semester,
                    coreTopLevel,
                    hierarchy,
                    windowSize,
                  ),
                  SizedBox(height: windowSize.isMicro ? 12 : 16),
                ],
                // Specialization Subjects Section
                if (specTopLevel.isNotEmpty) ...[
                  _buildSidebarSectionHeader(theme, windowSize.isMicro ? 'Spec' : 'Specialization', windowSize),
                  ..._buildSubjectList(
                    theme,
                    semester,
                    specTopLevel,
                    hierarchy,
                    windowSize,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSubjectList(
    ThemeData theme,
    SemesterModel semester,
    List<SubjectInfo> subjects,
    Map<SubjectInfo, List<SubjectInfo>> hierarchy,
    WindowSize windowSize,
  ) {
    final widgets = <Widget>[];

    for (final subject in subjects) {
      final children = hierarchy[subject] ?? [];
      final hasChildren = children.isNotEmpty;
      final isExpanded = _expandedAccordionItems.contains(subject.id);

      if (hasChildren) {
        // Parent subject with accordion
        widgets.add(
          _buildAccordionItem(theme, semester, subject, children, isExpanded, windowSize),
        );
      } else {
        // Single subject without children
        widgets.add(_buildSubjectItem(theme, semester, subject, windowSize));
      }
    }

    return widgets;
  }

  Widget _buildAccordionItem(
    ThemeData theme,
    SemesterModel semester,
    SubjectInfo parent,
    List<SubjectInfo> children,
    bool isExpanded,
    WindowSize windowSize,
  ) {
    // Responsive sizing
    final horizontalMargin = windowSize.isMicro ? 8.0 : 12.0;
    final horizontalPadding = windowSize.isMicro ? 8.0 : 12.0;
    final verticalPadding = windowSize.isMicro ? 8.0 : 10.0;
    final chevronSize = windowSize.isMicro ? 12.0 : 14.0;
    final nameFontSize = windowSize.isMicro ? 11.0 : 13.0;
    final codeFontSize = windowSize.isMicro ? 9.0 : 10.0;
    final badgePaddingH = windowSize.isMicro ? 4.0 : 6.0;
    final badgeFontSize = windowSize.isMicro ? 9.0 : 10.0;
    
    return Column(
      children: [
        // Parent item (clickable to expand/collapse)
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedAccordionItems.remove(parent.id);
              } else {
                _expandedAccordionItems.add(parent.id);
              }
            });
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 2),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Animated expand/collapse icon
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.25 : 0,
                  child: Icon(
                    RadixIcons.chevronRight,
                    size: chevronSize,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                SizedBox(width: windowSize.isMicro ? 6 : 8),
                // Subject name first, then code below
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _closeSidebar();
                      _navigateToSubjectContent(context, semester, parent);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parent.name,
                          style: TextStyle(
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          parent.code.toUpperCase(),
                          style: TextStyle(
                            fontSize: codeFontSize,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Child count badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: badgePaddingH,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${children.length}',
                    style: TextStyle(
                      fontSize: badgeFontSize,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Children (shown when expanded)
        if (isExpanded)
          ...children.map((child) {
            return GestureDetector(
              onTap: () {
                _closeSidebar();
                _navigateToSubjectContent(context, semester, child);
              },
              child: Container(
                margin: EdgeInsets.only(
                  left: windowSize.isMicro ? 18 : 24,
                  right: horizontalMargin,
                  top: 2,
                  bottom: 2,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: windowSize.isMicro ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      RadixIcons.file,
                      size: windowSize.isMicro ? 10 : 12,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    SizedBox(width: windowSize.isMicro ? 6 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: TextStyle(
                              fontSize: windowSize.isMicro ? 10 : 12,
                              color: theme.colorScheme.foreground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            child.code.toUpperCase(),
                            style: TextStyle(
                              fontSize: windowSize.isMicro ? 8 : 9,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSidebarSectionHeader(ThemeData theme, String title, WindowSize windowSize) {
    final horizontalPadding = windowSize.isMicro ? 12.0 : 16.0;
    final verticalPadding = windowSize.isMicro ? 6.0 : 8.0;
    final indicatorHeight = windowSize.isMicro ? 12.0 : 14.0;
    final fontSize = windowSize.isMicro ? 9.0 : 10.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: Row(
        children: [
          Container(
            width: 3,
            height: indicatorHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: windowSize.isMicro ? 6 : 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.mutedForeground,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
    ThemeData theme,
    SemesterModel semester,
    WindowSize windowSize, {
    bool isSelected = false,
  }) {
    final horizontalMargin = windowSize.isMicro ? 8.0 : 12.0;
    final horizontalPadding = windowSize.isMicro ? 8.0 : 12.0;
    final verticalPadding = windowSize.isMicro ? 8.0 : 10.0;
    final iconSize = windowSize.isMicro ? 16.0 : 18.0;
    final titleFontSize = windowSize.isMicro ? 11.0 : 13.0;
    final subtitleFontSize = windowSize.isMicro ? 9.0 : 11.0;
    
    return GestureDetector(
      onTap: () {
        _closeSidebar();
        // Already on overview page, no navigation needed
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: iconSize,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.mutedForeground,
            ),
            SizedBox(width: windowSize.isMicro ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semester.overviewName ?? 'Semester Overview',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: titleFontSize,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    windowSize.isMicro ? 'Syllabus & info' : 'Syllabus, resources & info',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectItem(
    ThemeData theme,
    SemesterModel semester,
    SubjectInfo subject,
    WindowSize windowSize,
  ) {
    final horizontalMargin = windowSize.isMicro ? 8.0 : 12.0;
    final horizontalPadding = windowSize.isMicro ? 8.0 : 12.0;
    final verticalPadding = windowSize.isMicro ? 8.0 : 10.0;
    final indentWidth = windowSize.isMicro ? 16.0 : 22.0;
    final nameFontSize = windowSize.isMicro ? 11.0 : 13.0;
    final codeFontSize = windowSize.isMicro ? 9.0 : 10.0;
    
    return GestureDetector(
      onTap: () {
        _closeSidebar();
        _navigateToSubjectContent(context, semester, subject);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(width: indentWidth), // Indent to align with accordion items
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: nameFontSize,
                      color: theme.colorScheme.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subject.code.toUpperCase(),
                    style: TextStyle(
                      fontSize: codeFontSize,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationCards(
    BuildContext context,
    SemesterModel? previousSemester,
    SemesterModel? nextSemester,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    // Don't show if no prev/next available
    if (previousSemester == null && nextSemester == null) {
      return const SizedBox.shrink();
    }

    // Responsive sizing
    final horizontalMargin = windowSize.isMicro ? 12.0 : 16.0;
    final bottomOffset = windowSize.isMicro ? 12.0 : 16.0;
    final hiddenOffset = windowSize.isMicro ? -80.0 : -100.0;
    final containerPadding = windowSize.isMicro ? 8.0 : 12.0;
    final cardPadding = windowSize.isMicro ? 8.0 : 10.0;
    final borderRadius = windowSize.isMicro ? 10.0 : 12.0;
    final iconSize = windowSize.isMicro ? 18.0 : 20.0;
    final labelFontSize = windowSize.isMicro ? 9.0 : 10.0;
    final semFontSize = windowSize.isMicro ? 11.0 : 13.0;
    final gapWidth = windowSize.isMicro ? 8.0 : 12.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      left: horizontalMargin,
      right: horizontalMargin,
      bottom: _showNavigationCards ? bottomOffset : hiddenOffset,
      child: Container(
        padding: EdgeInsets.all(containerPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: theme.colorScheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Previous semester card
            if (previousSemester != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToSemester(_currentPageIndex - 1),
                  child: Container(
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: theme.colorScheme.mutedForeground,
                          size: iconSize,
                        ),
                        SizedBox(width: windowSize.isMicro ? 4 : 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                windowSize.isMicro ? 'Prev' : 'Previous',
                                style: TextStyle(
                                  fontSize: labelFontSize,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              Text(
                                'SEM ${previousSemester.id}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: semFontSize,
                                  color: theme.colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            SizedBox(width: gapWidth),
            // Next semester card
            if (nextSemester != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToSemester(_currentPageIndex + 1),
                  child: Container(
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: labelFontSize,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              Text(
                                'SEM ${nextSemester.id}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: semFontSize,
                                  color: theme.colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: windowSize.isMicro ? 4 : 6),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.mutedForeground,
                          size: iconSize,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterContent(BuildContext context, SemesterModel semester, WindowSize windowSize) {
    final theme = Theme.of(context);
    
    // Responsive padding
    final contentPadding = windowSize.isMicro ? 12.0 : 16.0;
    final sectionSpacing = windowSize.isMicro ? 12.0 : 16.0;
    final headerBottomSpacing = windowSize.isMicro ? 18.0 : 24.0;
    final cardBottomSpacing = windowSize.isMicro ? 6.0 : 8.0;
    final bottomSpacing = windowSize.isMicro ? 100.0 : 120.0;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semester Header Card
          _buildHeader(context, semester, theme, windowSize),
          SizedBox(height: sectionSpacing),

          // View Semester Overview Button (navigates to Gitbook content)
          if (semester.overviewGitbookUrl != null) ...[
            _buildOverviewButton(context, semester, theme, windowSize),
            SizedBox(height: headerBottomSpacing),
          ],

          // Core Subjects Section
          if (semester.coreSubjects.isNotEmpty) ...[
            _buildSectionHeader(context, 'Core Subjects', theme, windowSize),
            SizedBox(height: windowSize.isMicro ? 8 : 12),
            ...semester.coreSubjects.map(
              (subject) => Padding(
                padding: EdgeInsets.only(bottom: cardBottomSpacing),
                child: SubjectCard(
                  subject: subject,
                  onTap: () =>
                      _navigateToSubjectContent(context, semester, subject),
                ),
              ),
            ),
            SizedBox(height: sectionSpacing),
          ],

          // Specialization Subjects Section
          if (semester.specializationSubjects.isNotEmpty) ...[
            _buildSectionHeader(context, windowSize.isMicro ? 'Spec Subjects' : 'Specialization Subjects', theme, windowSize),
            SizedBox(height: windowSize.isMicro ? 8 : 12),
            ...semester.specializationSubjects.map(
              (subject) => Padding(
                padding: EdgeInsets.only(bottom: cardBottomSpacing),
                child: SubjectCard(
                  subject: subject,
                  onTap: () =>
                      _navigateToSubjectContent(context, semester, subject),
                ),
              ),
            ),
          ],

          // Bottom spacing for navigation cards
          SizedBox(height: bottomSpacing),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SemesterModel semester,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    // Responsive sizing
    final cardPadding = windowSize.isMicro ? 14.0 : 20.0;
    final badgePaddingH = windowSize.isMicro ? 8.0 : 12.0;
    final badgePaddingV = windowSize.isMicro ? 4.0 : 6.0;
    final badgeFontSize = windowSize.isMicro ? 10.0 : 12.0;
    final subjectCountFontSize = windowSize.isMicro ? 11.0 : 13.0;
    final titleFontSize = windowSize.isMicro ? 20.0 : 24.0;
    final descriptionFontSize = windowSize.isMicro ? 13.0 : 15.0;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: badgePaddingH,
                    vertical: badgePaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SEM ${semester.id}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: badgeFontSize,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${semester.allSubjects.length} subjects',
                  style: TextStyle(
                    color: theme.colorScheme.mutedForeground,
                    fontSize: subjectCountFontSize,
                  ),
                ),
              ],
            ),
            SizedBox(height: windowSize.isMicro ? 8 : 12),
            Text(
              semester.name,
              style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: windowSize.isMicro ? 2 : 4),
            Text(
              semester.description,
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
                fontSize: descriptionFontSize,
              ),
              maxLines: windowSize.isMicro ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewButton(
    BuildContext context,
    SemesterModel semester,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    // Responsive sizing
    final outerPadding = windowSize.isMicro ? 12.0 : 16.0;
    final iconContainerPadding = windowSize.isMicro ? 10.0 : 12.0;
    final iconContainerRadius = windowSize.isMicro ? 10.0 : 12.0;
    final titleFontSize = windowSize.isMicro ? 14.0 : 16.0;
    final subtitleFontSize = windowSize.isMicro ? 11.0 : 13.0;
    
    return Card(
      child: Clickable(
        onPressed: () => _navigateToOverviewContent(context, semester),
        child: Padding(
          padding: EdgeInsets.all(outerPadding),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconContainerPadding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(iconContainerRadius),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: theme.colorScheme.primary,
                  size: windowSize.isMicro ? 20 : 24,
                ),
              ),
              SizedBox(width: windowSize.isMicro ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semester Overview',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: windowSize.isMicro ? 2 : 4),
                    Text(
                      windowSize.isMicro 
                          ? 'Syllabus, resources & info'
                          : 'View complete syllabus, resources & information',
                      style: TextStyle(
                        color: theme.colorScheme.mutedForeground,
                        fontSize: subtitleFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.mutedForeground,
                size: windowSize.isMicro ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    ThemeData theme,
    WindowSize windowSize,
  ) {
    final indicatorWidth = windowSize.isMicro ? 3.0 : 4.0;
    final indicatorHeight = windowSize.isMicro ? 16.0 : 20.0;
    final fontSize = windowSize.isMicro ? 14.0 : 16.0;
    
    return Row(
      children: [
        Container(
          width: indicatorWidth,
          height: indicatorHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: windowSize.isMicro ? 8 : 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.foreground,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _navigateToOverviewContent(
    BuildContext context,
    SemesterModel semester,
  ) {
    if (semester.overviewGitbookUrl == null) return;

    final encodedUrl = Uri.encodeComponent(semester.overviewGitbookUrl!);
    final title = Uri.encodeComponent(
      semester.overviewName ?? '${semester.name} Overview',
    );
    final subtitle = Uri.encodeComponent('Semester ${semester.id}');
    final semesterId = semester.id.toString();

    context.push(
      '/main/home/content?title=$title&url=$encodedUrl&subtitle=$subtitle&semesterId=$semesterId',
    );
  }

  void _navigateToSubjectContent(
    BuildContext context,
    SemesterModel semester,
    SubjectInfo subject,
  ) {
    // Navigate to subject detail screen (not generic content screen)
    context.push(
      RouteConstants.subjectPath(semester.id.toString(), subject.code),
    );
  }
}
