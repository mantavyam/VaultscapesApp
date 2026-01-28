import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/cards/subject_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../../data/models/semester_model.dart';
import '../../../core/constants/route_constants.dart';

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
                      return _buildSemesterContent(context, semester);
                    },
                  ),
                  // Animated bottom navigation cards
                  _buildBottomNavigationCards(
                    context,
                    previousSemester,
                    nextSemester,
                    theme,
                  ),
                ],
              ),
            ),
            // Animated sidebar overlay
            if (_isSidebarOpen ||
                _sidebarAnimationController.status == AnimationStatus.reverse)
              _buildAnimatedSidebar(theme, currentSemester),
          ],
        );
      },
    );
  }

  /// Build animated sidebar with slide and fade animation
  Widget _buildAnimatedSidebar(ThemeData theme, SemesterModel semester) {
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
                offset: Offset(280 * _sidebarSlideAnimation.value, 0),
                child: _buildHierarchicalSidebar(theme, semester),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build hierarchical sidebar with Overview at top, then Core and Specialization subjects
  Widget _buildHierarchicalSidebar(ThemeData theme, SemesterModel semester) {
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

    return Container(
      width: 280,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  RadixIcons.file,
                  size: 18,
                  color: theme.colorScheme.foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Contents - ${semester.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.foreground,
                    ),
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Overview item at the top (highlighted as current page)
                if (semester.overviewGitbookUrl != null) ...[
                  _buildSidebarSectionHeader(theme, 'Overview'),
                  _buildOverviewItem(theme, semester, isSelected: true),
                  const SizedBox(height: 16),
                ],
                // Core Subjects Section
                if (coreTopLevel.isNotEmpty) ...[
                  _buildSidebarSectionHeader(theme, 'Core Subjects'),
                  ..._buildSubjectList(
                    theme,
                    semester,
                    coreTopLevel,
                    hierarchy,
                  ),
                  const SizedBox(height: 16),
                ],
                // Specialization Subjects Section
                if (specTopLevel.isNotEmpty) ...[
                  _buildSidebarSectionHeader(theme, 'Specialization'),
                  ..._buildSubjectList(
                    theme,
                    semester,
                    specTopLevel,
                    hierarchy,
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
  ) {
    final widgets = <Widget>[];

    for (final subject in subjects) {
      final children = hierarchy[subject] ?? [];
      final hasChildren = children.isNotEmpty;
      final isExpanded = _expandedAccordionItems.contains(subject.id);

      if (hasChildren) {
        // Parent subject with accordion
        widgets.add(
          _buildAccordionItem(theme, semester, subject, children, isExpanded),
        );
      } else {
        // Single subject without children
        widgets.add(_buildSubjectItem(theme, semester, subject));
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
  ) {
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
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    size: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          parent.code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Child count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${children.length}',
                    style: TextStyle(
                      fontSize: 10,
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
                margin: const EdgeInsets.only(
                  left: 24,
                  right: 12,
                  top: 2,
                  bottom: 2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      RadixIcons.file,
                      size: 12,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.foreground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            child.code.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
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

  Widget _buildSidebarSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
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
    SemesterModel semester, {
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () {
        _closeSidebar();
        // Already on overview page, no navigation needed
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              size: 18,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: 12),
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
                      fontSize: 13,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Syllabus, resources & info',
                    style: TextStyle(
                      fontSize: 11,
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
  ) {
    return GestureDetector(
      onTap: () {
        _closeSidebar();
        _navigateToSubjectContent(context, semester, subject);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 22), // Indent to align with accordion items
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: theme.colorScheme.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subject.code.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
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
  ) {
    // Don't show if no prev/next available
    if (previousSemester == null && nextSemester == null) {
      return const SizedBox.shrink();
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      left: 16,
      right: 16,
      bottom: _showNavigationCards ? 16 : -100,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: theme.colorScheme.mutedForeground,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Previous',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              Text(
                                'SEM ${previousSemester.id}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
            const SizedBox(width: 12),
            // Next semester card
            if (nextSemester != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToSemester(_currentPageIndex + 1),
                  child: Container(
                    padding: const EdgeInsets.all(10),
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
                                  fontSize: 10,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              Text(
                                'SEM ${nextSemester.id}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: theme.colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.mutedForeground,
                          size: 20,
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

  Widget _buildSemesterContent(BuildContext context, SemesterModel semester) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semester Header Card
          _buildHeader(context, semester, theme),
          const SizedBox(height: 16),

          // View Semester Overview Button (navigates to Gitbook content)
          if (semester.overviewGitbookUrl != null) ...[
            _buildOverviewButton(context, semester, theme),
            const SizedBox(height: 24),
          ],

          // Core Subjects Section
          if (semester.coreSubjects.isNotEmpty) ...[
            _buildSectionHeader(context, 'Core Subjects', theme),
            const SizedBox(height: 12),
            ...semester.coreSubjects.map(
              (subject) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SubjectCard(
                  subject: subject,
                  onTap: () =>
                      _navigateToSubjectContent(context, semester, subject),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Specialization Subjects Section
          if (semester.specializationSubjects.isNotEmpty) ...[
            _buildSectionHeader(context, 'Specialization Subjects', theme),
            const SizedBox(height: 12),
            ...semester.specializationSubjects.map(
              (subject) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SubjectCard(
                  subject: subject,
                  onTap: () =>
                      _navigateToSubjectContent(context, semester, subject),
                ),
              ),
            ),
          ],

          // Bottom spacing for navigation cards
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SemesterModel semester,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
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
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${semester.allSubjects.length} subjects',
                  style: TextStyle(
                    color: theme.colorScheme.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              semester.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              semester.description,
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
                fontSize: 15,
              ),
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
  ) {
    return Card(
      child: Clickable(
        onPressed: () => _navigateToOverviewContent(context, semester),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Semester Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View complete syllabus, resources & information',
                      style: TextStyle(
                        color: theme.colorScheme.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
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
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.foreground,
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
