import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/services/markdown_content_service.dart';
import '../../../data/services/markdown_parser.dart';
import '../../../data/models/semester_model.dart';
import '../../widgets/content/markdown_content_renderer.dart';
import '../../widgets/content/content_loading_skeleton.dart';
import '../../providers/navigation_provider.dart';
import '../../../core/constants/route_constants.dart';

/// Overview content screen for displaying semester overview Gitbook content
/// Uses the same sidebar and navigation pattern as SubjectDetailScreen
/// Supports swipe navigation to the first subject in the semester
class GitbookContentScreen extends StatefulWidget {
  final String title;
  final String gitbookUrl;
  final String? subtitle;
  final String? semesterId; // Optional semester context for navigation

  const GitbookContentScreen({
    super.key,
    required this.title,
    required this.gitbookUrl,
    this.subtitle,
    this.semesterId,
  });

  @override
  State<GitbookContentScreen> createState() => _GitbookContentScreenState();
}

class _GitbookContentScreenState extends State<GitbookContentScreen>
    with SingleTickerProviderStateMixin {
  final MarkdownContentService _contentService = MarkdownContentService();
  final MarkdownParser _parser = MarkdownParser();

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isFromCache = false;
  String? _errorMessage;
  MarkdownErrorType? _errorType;
  List<ContentBlock> _contentBlocks = [];

  // Sidebar state
  bool _isSidebarOpen = false;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarSlideAnimation;
  late Animation<double> _sidebarFadeAnimation;

  // Navigation state
  SemesterModel? _semester;
  SubjectInfo? _nextSubject; // First subject for navigation
  bool _showNavigationCards = true;
  double _lastScrollOffset = 0;
  bool _hasScrolledDown = false;

  // Track expanded accordion items (for hierarchical sidebar)
  final Set<String> _expandedAccordionItems = {};

  // For tracking swipe gesture
  double _horizontalDragStart = 0;
  double _verticalDragStart = 0;
  bool _isHorizontalSwipe = false;

  @override
  void initState() {
    super.initState();

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

    _loadContent();
    _loadSemesterContext();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _loadSemesterContext() {
    if (widget.semesterId == null) return;

    // Load semester data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navProvider = context.read<NavigationProvider>();
      final semesterIdInt = int.tryParse(widget.semesterId!);
      if (semesterIdInt == null) return;
      final semester = navProvider.getSemesterById(semesterIdInt);
      if (mounted && semester != null) {
        setState(() {
          _semester = semester;
          // Set the first subject for swipe navigation
          if (semester.allSubjects.isNotEmpty) {
            _nextSubject = semester.allSubjects.first;
          }
        });
      }
    });
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
    });

    try {
      await _contentService.init();
      final result = await _contentService.fetchContent(widget.gitbookUrl);

      if (result.isSuccess && result.content != null) {
        final blocks = _parser.parse(result.content!);
        setState(() {
          _contentBlocks = blocks;
          _isFromCache = result.fromCache;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to load content';
          _errorType = result.errorType;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _errorType = MarkdownErrorType.unknown;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshContent() async {
    setState(() => _isRefreshing = true);
    await _contentService.clearCacheFor(widget.gitbookUrl);
    await _loadContent();
    setState(() => _isRefreshing = false);
  }

  Future<void> _retryLoadContent() async {
    setState(() {
      _errorMessage = null;
      _errorType = null;
      _isLoading = true;
    });
    await _contentService.clearCacheFor(widget.gitbookUrl);
    await _loadContent();
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

  void _navigateToSubject(SubjectInfo subject) {
    _closeSidebar();
    if (_semester != null) {
      context.push(
        RouteConstants.subjectPath(_semester!.id.toString(), subject.code),
      );
    }
  }

  /// Navigate to a subject by its code (for internal card links)
  void _navigateToSubjectByCode(String subjectCode) {
    if (_semester == null) return;

    // Find the subject in the semester by code (case-insensitive)
    final allSubjects = [
      ..._semester!.coreSubjects,
      ..._semester!.specializationSubjects,
    ];

    final subject = allSubjects.firstWhere(
      (s) => s.code.toLowerCase() == subjectCode.toLowerCase(),
      orElse: () => allSubjects.first, // Fallback, shouldn't happen
    );

    _navigateToSubject(subject);
  }

  /// Get all known subject codes from the current semester for internal navigation
  Set<String> _getKnownSubjectCodes() {
    if (_semester == null) return {};

    final codes = <String>{};
    for (final subject in _semester!.coreSubjects) {
      codes.add(subject.code.toUpperCase());
    }
    for (final subject in _semester!.specializationSubjects) {
      codes.add(subject.code.toUpperCase());
    }
    return codes;
  }

  /// Build breadcrumb with horizontal scroll: BTECH / CSE-IT / SEM-X / OVERVIEW
  Widget _buildBreadcrumb(ThemeData theme) {
    if (_semester == null) {
      return Text(widget.title);
    }

    final items = ['BTECH', 'CSE-IT', 'SEM${_semester!.id}', 'OVERVIEW'];

    // Horizontally scrollable breadcrumb - swipe to reveal hidden text
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '/',
                  style: TextStyle(
                    color: theme.colorScheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ),
            Text(
              items[i],
              style: TextStyle(
                color: i == items.length - 1
                    ? theme.colorScheme.foreground
                    : theme.colorScheme.mutedForeground,
                fontWeight: i == items.length - 1
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSemesterContext = _semester != null;

    return GestureDetector(
      // Track horizontal swipe for navigation to first subject
      onHorizontalDragStart: (details) {
        _horizontalDragStart = details.globalPosition.dx;
        _verticalDragStart = details.globalPosition.dy;
        _isHorizontalSwipe = false;
      },
      onHorizontalDragUpdate: (details) {
        final horizontalDelta =
            (details.globalPosition.dx - _horizontalDragStart).abs();
        final verticalDelta = (details.globalPosition.dy - _verticalDragStart)
            .abs();
        // Only consider it a horizontal swipe if horizontal movement is 2x vertical
        if (horizontalDelta > 50 && horizontalDelta > verticalDelta * 2) {
          _isHorizontalSwipe = true;
        }
      },
      onHorizontalDragEnd: (details) {
        if (!_isHorizontalSwipe) return;
        if (details.primaryVelocity == null) return;

        final horizontalDelta = details.primaryVelocity!;
        // Swipe right to left - go to first subject
        if (horizontalDelta < -500 && _nextSubject != null) {
          _navigateToSubject(_nextSubject!);
        }
        // Swipe left to right - go back (pop)
        else if (horizontalDelta > 500) {
          context.pop();
        }
        _isHorizontalSwipe = false;
      },
      child: Stack(
        children: [
          // Main content
          Scaffold(
            headers: [
              AppBar(
                leading: [
                  IconButton.ghost(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                ],
                // Breadcrumb title with horizontal scroll (same as subject_detail_screen)
                title: hasSemesterContext
                    ? _buildBreadcrumb(theme)
                    : Text(widget.title),
                trailing: [
                  // Refresh button in appbar
                  if (!_isLoading)
                    IconButton.ghost(
                      icon: const Icon(RadixIcons.reload),
                      onPressed: _isRefreshing
                          ? null
                          : () {
                              if (_errorMessage != null) {
                                _retryLoadContent();
                              } else {
                                _refreshContent();
                              }
                            },
                    ),
                  // Hierarchical sidebar toggle button (only when semester context is available)
                  if (hasSemesterContext)
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
            child: Column(
              children: [
                // Header with subtitle and cache indicator
                _buildSubHeader(theme),
                // Content area with scroll tracking
                Expanded(child: _buildMainContent(theme)),
              ],
            ),
          ),
          // Animated sidebar overlay (same pattern as subject_detail_screen)
          if (_isSidebarOpen ||
              _sidebarAnimationController.status == AnimationStatus.reverse)
            _buildAnimatedSidebar(theme),
          // Loading overlay (on top of everything)
          if (_isLoading || _isRefreshing) _buildLoadingOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildSubHeader(ThemeData theme) {
    final showHeader = widget.subtitle != null || _isFromCache;
    if (!showHeader) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Row(
        children: [
          if (widget.subtitle != null)
            Expanded(child: Text(widget.subtitle!).muted),
          if (_isFromCache)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    RadixIcons.clock,
                    size: 12,
                    color: theme.colorScheme.secondaryForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cached',
                    style: theme.typography.xSmall.copyWith(
                      color: theme.colorScheme.secondaryForeground,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    const accentColor = Color(0xFF0EA5E9);

    return AnimatedOpacity(
      opacity: _isLoading || _isRefreshing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: theme.colorScheme.background.withValues(alpha: 0.85),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        RadixIcons.reader,
                        size: 28,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isRefreshing ? 'Refreshing...' : 'Loading Overview',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we fetch the content.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        backgroundColor: theme.colorScheme.muted.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    if (_isLoading) {
      return const ContentLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return ContentErrorWidget(
        message: _getErrorTitle(),
        details: _errorMessage,
        onRetry: _retryLoadContent,
      );
    }

    if (_contentBlocks.isEmpty) {
      return const ContentErrorWidget(
        message: 'No content available',
        details: 'The page appears to be empty.',
      );
    }

    // Build content with animated navigation cards
    return Stack(
      children: [
        // Main content with scroll tracking
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final currentOffset = notification.metrics.pixels;
              if (currentOffset > _lastScrollOffset && currentOffset > 50) {
                if (!_hasScrolledDown) {
                  setState(() {
                    _showNavigationCards = false;
                    _hasScrolledDown = true;
                  });
                }
              } else if (currentOffset < _lastScrollOffset &&
                  _hasScrolledDown) {
                setState(() {
                  _showNavigationCards = true;
                  _hasScrolledDown = false;
                });
              }
              _lastScrollOffset = currentOffset;
            }
            return false;
          },
          child: MarkdownContentRenderer(
            blocks: _contentBlocks,
            knownSubjectCodes: _getKnownSubjectCodes(),
            onNavigateToSubject: _navigateToSubjectByCode,
          ),
        ),
        // Animated navigation cards (only when semester context is available)
        if (_semester != null && _nextSubject != null)
          _buildAnimatedPrevNextNavigation(theme),
      ],
    );
  }

  /// Build animated sidebar with slide and fade animation (same as subject_detail_screen)
  Widget _buildAnimatedSidebar(ThemeData theme) {
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
                child: _buildHierarchicalSidebar(theme),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build hierarchical sidebar (same structure as subject_detail_screen)
  Widget _buildHierarchicalSidebar(ThemeData theme) {
    if (_semester == null) {
      return const SizedBox.shrink();
    }

    final coreSubjects = _semester!.coreSubjects;
    final specSubjects = _semester!.specializationSubjects;
    final hierarchy = _semester!.subjectHierarchy;

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
                    'Subjects - ${_semester!.name}',
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
          // Subject list with sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Overview Section (currently selected)
                _buildSidebarSectionHeader(theme, 'Overview'),
                _buildOverviewSidebarItem(theme, isSelected: true),
                const SizedBox(height: 16),
                // Core Subjects Section
                if (coreSubjects.isNotEmpty) ...[
                  _buildSidebarSectionHeader(theme, 'Core Subjects'),
                  ..._buildSubjectList(theme, coreSubjects, hierarchy),
                  const SizedBox(height: 16),
                ],
                // Specialization Subjects Section
                if (specSubjects.isNotEmpty) ...[
                  _buildSidebarSectionHeader(theme, 'Specialization'),
                  ..._buildSubjectList(theme, specSubjects, hierarchy),
                ],
              ],
            ),
          ),
        ],
      ),
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

  /// Build overview item (currently selected on this screen)
  Widget _buildOverviewSidebarItem(ThemeData theme, {bool isSelected = false}) {
    return Container(
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
                  _semester?.overviewName ?? 'Semester Overview',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Syllabus & Resources',
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
    );
  }

  List<Widget> _buildSubjectList(
    ThemeData theme,
    List<SubjectInfo> subjects,
    Map<SubjectInfo, List<SubjectInfo>> hierarchy,
  ) {
    final widgets = <Widget>[];

    for (final subject in subjects) {
      // Check if this is a top-level subject in hierarchy
      final isTopLevel = hierarchy.containsKey(subject);
      final children = hierarchy[subject] ?? [];
      final hasChildren = children.isNotEmpty;
      final isExpanded = _expandedAccordionItems.contains(subject.id);

      if (hasChildren && isTopLevel) {
        // Parent subject with accordion
        widgets.add(_buildAccordionItem(theme, subject, children, isExpanded));
      } else if (isTopLevel) {
        // Single subject without children
        widgets.add(_buildSingleSubjectItem(theme, subject));
      }
    }

    return widgets;
  }

  Widget _buildAccordionItem(
    ThemeData theme,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.transparent, width: 3),
              ),
            ),
            child: Row(
              children: [
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
                Expanded(
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
              onTap: () => _navigateToSubject(child),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                margin: const EdgeInsets.only(left: 22),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.transparent, width: 3),
                  ),
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

  Widget _buildSingleSubjectItem(ThemeData theme, SubjectInfo subject) {
    return GestureDetector(
      onTap: () => _navigateToSubject(subject),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Colors.transparent, width: 3)),
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
                      fontSize: 13,
                      color: theme.colorScheme.foreground,
                    ),
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

  /// Build animated previous/next navigation cards - only shows "Next" card on overview
  Widget _buildAnimatedPrevNextNavigation(ThemeData theme) {
    // Only show if there's a next subject
    if (_nextSubject == null) {
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
        child: GestureDetector(
          onTap: () => _navigateToSubject(_nextSubject!),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      _nextSubject!.code.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorTitle() {
    return switch (_errorType) {
      MarkdownErrorType.networkError => 'No Internet Connection',
      MarkdownErrorType.serverError => 'Server Error',
      MarkdownErrorType.notFound => 'Content Not Found',
      MarkdownErrorType.parseError => 'Failed to Parse Content',
      _ => 'Error Loading Content',
    };
  }
}
