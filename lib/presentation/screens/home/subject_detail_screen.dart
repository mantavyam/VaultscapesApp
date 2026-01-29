import 'dart:developer' as developer;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../../data/models/semester_model.dart';
import '../../../data/services/markdown_content_service.dart';
import '../../../data/services/markdown_parser.dart';
import '../../widgets/content/markdown_content_renderer.dart';
import '../../widgets/content/content_loading_skeleton.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/responsive/responsive.dart';

/// Subject detail screen with:
/// - Breadcrumb navigation with horizontal scroll: UG/BTECH/CSE-IT/SEM-X/SUBCODE
/// - Animated hierarchical sidebar with accordion for parent/child subjects
/// - Horizontal swipe navigation between subjects in current semester
/// - Animated bottom navigation cards (hide on scroll down, show on scroll up)
/// - Loading overlay with linear progress indicator on top of skeleton
class SubjectDetailScreen extends StatefulWidget {
  final String semesterId;
  final String subjectId;

  const SubjectDetailScreen({
    super.key,
    required this.semesterId,
    required this.subjectId,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  static const String _logName = 'SubjectDetailScreen';

  final MarkdownContentService _contentService = MarkdownContentService();
  final MarkdownParser _parser = MarkdownParser();

  SubjectInfo? _subject;
  SemesterModel? _semester;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isFromCache = false;
  bool _isSidebarOpen = false;
  String? _errorMessage;
  MarkdownErrorType? _errorType;
  List<ContentBlock> _contentBlocks = [];

  // Previous and next subjects for navigation (in current semester)
  SubjectInfo? _previousSubject;
  SubjectInfo? _nextSubject;

  // Flag for navigation to overview page (when on first subject)
  bool _canNavigateToOverview = false;

  // For tracking swipe gesture
  double _horizontalDragStart = 0;
  double _verticalDragStart = 0;
  bool _isHorizontalSwipe = false;

  // Track expanded accordion items
  final Set<String> _expandedAccordionItems = {};

  // Sidebar animation controller
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarSlideAnimation;
  late Animation<double> _sidebarFadeAnimation;

  // Scroll tracking for hiding/showing navigation cards
  bool _showNavigationCards = true;
  double _lastScrollOffset = 0;
  bool _hasScrolledDown = false;

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _logName,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

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

    _loadSubjectAndContent();
  }

  @override
  void didUpdateWidget(SubjectDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectId != widget.subjectId ||
        oldWidget.semesterId != widget.semesterId) {
      // Reset scroll state when navigating to new subject
      _showNavigationCards = true;
      _hasScrolledDown = false;
      _lastScrollOffset = 0;
      _loadSubjectAndContent();
    }
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjectAndContent() async {
    _log('=== LOAD SUBJECT AND CONTENT START ===');
    _log('Semester ID: ${widget.semesterId}, Subject ID: ${widget.subjectId}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
    });

    // Find the subject from navigation data
    final navProvider = context.read<NavigationProvider>();
    final semId = int.tryParse(widget.semesterId);
    _log('Parsed semester ID: $semId');

    if (semId != null) {
      _semester = navProvider.getSemesterById(semId);
      _log('Found semester: ${_semester?.name ?? "null"}');

      if (_semester != null) {
        final subjects = _semester!.allSubjects;
        _log('Total subjects in semester: ${subjects.length}');

        final currentIndex = subjects.indexWhere(
          (s) => s.code == widget.subjectId,
        );
        _log('Current subject index: $currentIndex');

        if (currentIndex != -1) {
          _subject = subjects[currentIndex];
          _log('Found subject: ${_subject!.name} (${_subject!.code})');
          _log('Subject gitbookUrl: ${_subject!.gitbookUrl}');

          // Set previous and next subjects for swipe navigation
          _previousSubject = currentIndex > 0
              ? subjects[currentIndex - 1]
              : null;
          _nextSubject = currentIndex < subjects.length - 1
              ? subjects[currentIndex + 1]
              : null;

          // If on first subject and semester has overview, allow swipe to overview
          _canNavigateToOverview =
              currentIndex == 0 && _semester!.overviewGitbookUrl != null;

          _log('Previous subject: ${_previousSubject?.code ?? "none"}');
          _log('Next subject: ${_nextSubject?.code ?? "none"}');
          _log('Can navigate to overview: $_canNavigateToOverview');
        }
      }
    }

    if (_subject == null) {
      _log('ERROR: Subject not found');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Subject not found';
        _errorType = MarkdownErrorType.notFound;
      });
      return;
    }

    // If we have a gitbook URL, fetch the content
    if (_subject!.gitbookUrl != null) {
      _log('Loading content from gitbookUrl...');
      await _loadContent(_subject!.gitbookUrl!);
    } else {
      _log('ERROR: No content URL configured');
      setState(() {
        _isLoading = false;
        _errorMessage = 'No content URL configured for this subject';
        _errorType = MarkdownErrorType.notFound;
      });
    }
  }

  Future<void> _loadContent(String gitbookUrl) async {
    _log('=== LOAD CONTENT START ===');
    _log('GitBook URL: $gitbookUrl');

    try {
      _log('Initializing content service...');
      await _contentService.init();

      _log('Fetching content...');
      final result = await _contentService.fetchContent(gitbookUrl);
      _log(
        'Fetch result - Success: ${result.isSuccess}, FromCache: ${result.fromCache}',
      );

      if (result.isSuccess && result.content != null) {
        _log('Content received, length: ${result.content!.length} chars');
        _log('Parsing content...');

        final stopwatch = Stopwatch()..start();
        final blocks = _parser.parse(result.content!);
        stopwatch.stop();

        _log('Parsing complete in ${stopwatch.elapsedMilliseconds}ms');
        _log('Parsed ${blocks.length} content blocks');
        _log(
          'Block types: ${blocks.map((b) => b.runtimeType.toString()).toSet().join(", ")}',
        );

        setState(() {
          _contentBlocks = blocks;
          _isFromCache = result.fromCache;
          _isLoading = false;
        });
        _log('=== LOAD CONTENT SUCCESS ===');
      } else {
        _log('ERROR: Fetch failed - ${result.errorMessage}');
        _log('Error type: ${result.errorType}');
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to load content';
          _errorType = result.errorType;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _log(
        'ERROR: Unexpected exception during content loading',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _errorType = MarkdownErrorType.unknown;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshContent() async {
    if (_subject?.gitbookUrl == null) return;
    _log('Refreshing content for: ${_subject!.gitbookUrl}');
    setState(() => _isRefreshing = true);
    await _contentService.clearCacheFor(_subject!.gitbookUrl!);
    await _loadContent(_subject!.gitbookUrl!);
    setState(() => _isRefreshing = false);
    _log('Refresh complete');
  }

  /// Retry loading content after an error
  Future<void> _retryLoadContent() async {
    if (_subject?.gitbookUrl == null) return;
    _log('Retrying content load for: ${_subject!.gitbookUrl}');

    // Reset error state and reload
    setState(() {
      _errorMessage = null;
      _errorType = null;
      _isLoading = true;
    });

    // Clear cache and reload fresh
    await _contentService.clearCacheFor(_subject!.gitbookUrl!);
    await _loadContent(_subject!.gitbookUrl!);
  }

  void _navigateToSubject(SubjectInfo subject) {
    _closeSidebar();
    context.go(RouteConstants.subjectPath(widget.semesterId, subject.code));
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

  void _navigateToOverview() {
    if (_semester == null || _semester!.overviewGitbookUrl == null) return;
    _closeSidebar();

    final encodedUrl = Uri.encodeComponent(_semester!.overviewGitbookUrl!);
    final title = Uri.encodeComponent(
      _semester!.overviewName ?? '${_semester!.name} Overview',
    );
    final subtitle = Uri.encodeComponent('Semester ${_semester!.id}');
    final semesterId = _semester!.id.toString();

    context.push(
      '/main/home/content?title=$title&url=$encodedUrl&subtitle=$subtitle&semesterId=$semesterId',
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show error if subject not found
    if (_subject == null && !_isLoading) {
      return Scaffold(
        headers: [
          AppBar(
            leading: [
              IconButton.ghost(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ],
            title: const Text('Subject Not Found'),
          ),
        ],
        child: AppErrorWidget.generic(
          message: 'Subject not found',
          onRetry: () => context.pop(),
        ),
      );
    }

    return ResponsiveBuilder(
      builder: (context, windowSize) {
        return GestureDetector(
          // Track horizontal swipe for subject navigation
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
            // Swipe right to left - go to next subject
            if (horizontalDelta < -500 && _nextSubject != null) {
              _navigateToSubject(_nextSubject!);
            }
            // Swipe left to right - go to previous subject or overview
            else if (horizontalDelta > 500) {
              if (_previousSubject != null) {
                _navigateToSubject(_previousSubject!);
              } else if (_canNavigateToOverview && _semester != null) {
                _navigateToOverview();
              }
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
                    // Breadcrumb title with horizontal scroll
                    title: _buildBreadcrumb(theme, windowSize),
                    trailing: [
                      // Refresh button in appbar
                      if (!_isLoading)
                        IconButton.ghost(
                          icon: Icon(
                            _isRefreshing ? RadixIcons.reload : RadixIcons.reload,
                          ),
                          onPressed: _isRefreshing
                              ? null
                              : () {
                                  if (_errorMessage != null) {
                                    // If there's an error, retry loading
                                    _retryLoadContent();
                                  } else {
                                    // Otherwise, refresh content
                                    _refreshContent();
                                  }
                                },
                        ),
                      // Hierarchical sidebar toggle button
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
                    // Subject header with code and cache indicator
                    if (_subject != null) _buildSubjectHeader(theme, windowSize),
                    // Content area with scroll controller
                    Expanded(child: _buildContent(theme, windowSize)),
                  ],
                ),
              ),
              // Animated sidebar overlay
              if (_isSidebarOpen ||
                  _sidebarAnimationController.status == AnimationStatus.reverse)
                _buildAnimatedSidebar(theme, windowSize),
              // Loading overlay (on top of everything including skeleton)
              if (_isLoading || _isRefreshing) _buildLoadingOverlay(theme, windowSize),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme, WindowSize windowSize) {
    const accentColor = Color(0xFF0EA5E9);
    
    // Responsive sizing
    final maxWidth = windowSize.isMicro ? 280.0 : 340.0;
    final iconContainerSize = windowSize.isMicro ? 64.0 : 80.0;
    final iconSize = windowSize.isMicro ? 32.0 : 40.0;
    final titleFontSize = windowSize.isMicro ? 16.0 : 20.0;
    final subtitleFontSize = windowSize.isMicro ? 12.0 : 14.0;
    final progressWidth = windowSize.isMicro ? 160.0 : 200.0;
    final spacing = windowSize.isMicro ? 16.0 : 24.0;

    return AnimatedOpacity(
      opacity: _isLoading || _isRefreshing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: theme.colorScheme.background.withValues(alpha: 0.85),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: iconContainerSize,
                      height: iconContainerSize,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.article_outlined,
                          size: iconSize,
                          color: accentColor,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),
                    Text(
                      _isRefreshing
                          ? 'Refreshing content...'
                          : 'Loading content...',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: windowSize.isMicro ? 6 : 8),
                    Text(
                      windowSize.isMicro 
                          ? 'Please wait...'
                          : 'Please wait while we fetch the content.',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing),
                    SizedBox(
                      width: progressWidth,
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

  /// Build breadcrumb with horizontal scroll: UG / BTECH / CSE-IT / SEM-X / SUBCODE
  Widget _buildBreadcrumb(ThemeData theme, WindowSize windowSize) {
    if (_subject == null || _semester == null) {
      return const Text('Loading...');
    }

    // Responsive breadcrumb - show less items in micro mode
    final items = windowSize.isMicro 
        ? ['SEM${widget.semesterId}', _subject!.code.toUpperCase()]
        : ['BTECH', 'CSE-IT', 'SEM${widget.semesterId}', _subject!.code.toUpperCase()];
    
    final fontSize = windowSize.isMicro ? 11.0 : 12.0;
    final separatorPadding = windowSize.isMicro ? 3.0 : 4.0;

    // Horizontally scrollable breadcrumb - swipe to reveal hidden text
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: separatorPadding),
                child: Text(
                  '/',
                  style: TextStyle(
                    color: theme.colorScheme.mutedForeground,
                    fontSize: fontSize,
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
                fontSize: fontSize,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectHeader(ThemeData theme, WindowSize windowSize) {
    // Responsive sizing
    final horizontalPadding = windowSize.isMicro ? 12.0 : 16.0;
    final verticalPadding = windowSize.isMicro ? 8.0 : 12.0;
    final titleFontSize = windowSize.isMicro ? 14.0 : 16.0;
    final codeFontSize = windowSize.isMicro ? 10.0 : 12.0;
    final cacheBadgePaddingH = windowSize.isMicro ? 6.0 : 8.0;
    final cacheBadgePaddingV = windowSize.isMicro ? 3.0 : 4.0;
    final cacheIconSize = windowSize.isMicro ? 10.0 : 12.0;
    final cacheFontSize = windowSize.isMicro ? 9.0 : 11.0;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _subject!.name,
                  style: TextStyle(
                    color: theme.colorScheme.foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: titleFontSize,
                  ),
                  maxLines: windowSize.isMicro ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: windowSize.isMicro ? 1 : 2),
                Text(
                  _subject!.code.toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: codeFontSize,
                  ),
                ),
              ],
            ),
          ),
          if (_isFromCache)
            Container(
              padding: EdgeInsets.symmetric(horizontal: cacheBadgePaddingH, vertical: cacheBadgePaddingV),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    RadixIcons.clock,
                    size: cacheIconSize,
                    color: theme.colorScheme.secondaryForeground,
                  ),
                  SizedBox(width: windowSize.isMicro ? 3 : 4),
                  Text(
                    'Cached',
                    style: TextStyle(
                      fontSize: cacheFontSize,
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

  /// Build animated sidebar with slide and fade animation
  Widget _buildAnimatedSidebar(ThemeData theme, WindowSize windowSize) {
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
                child: _buildHierarchicalSidebar(theme, windowSize, sidebarWidth),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build hierarchical sidebar with accordion for parent/child subjects
  /// Includes bifurcation between core and specialization subjects
  Widget _buildHierarchicalSidebar(ThemeData theme, WindowSize windowSize, double sidebarWidth) {
    if (_semester == null) {
      return const SizedBox.shrink();
    }

    final coreSubjects = _semester!.coreSubjects;
    final specSubjects = _semester!.specializationSubjects;
    final hierarchy = _semester!.subjectHierarchy;
    
    // Responsive sizing
    final headerPadding = windowSize.isMicro ? 12.0 : 16.0;
    final headerIconSize = windowSize.isMicro ? 16.0 : 18.0;
    final headerFontSize = windowSize.isMicro ? 12.0 : 14.0;
    final listVerticalPadding = windowSize.isMicro ? 6.0 : 8.0;
    final sectionSpacing = windowSize.isMicro ? 12.0 : 16.0;

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
                    windowSize.isMicro ? _semester!.name : 'Subjects - ${_semester!.name}',
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
          // Subject list with sections
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: listVerticalPadding),
              children: [
                // Overview Section (at the top)
                if (_semester!.overviewGitbookUrl != null) ...[
                  _buildSidebarSectionHeader(theme, 'Overview', windowSize),
                  _buildOverviewSidebarItem(theme, windowSize),
                  SizedBox(height: sectionSpacing),
                ],
                // Core Subjects Section
                if (coreSubjects.isNotEmpty) ...[
                  _buildSidebarSectionHeader(theme, 'Core Subjects', windowSize),
                  ..._buildSubjectList(theme, coreSubjects, hierarchy, windowSize),
                  SizedBox(height: sectionSpacing),
                ],
                // Specialization Subjects Section
                if (specSubjects.isNotEmpty) ...[
                  _buildSidebarSectionHeader(theme, windowSize.isMicro ? 'Spec' : 'Specialization', windowSize),
                  ..._buildSubjectList(theme, specSubjects, hierarchy, windowSize),
                ],
              ],
            ),
          ),
        ],
      ),
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

  /// Build overview item for sidebar navigation
  Widget _buildOverviewSidebarItem(ThemeData theme, WindowSize windowSize) {
    final horizontalMargin = windowSize.isMicro ? 8.0 : 12.0;
    final horizontalPadding = windowSize.isMicro ? 8.0 : 12.0;
    final verticalPadding = windowSize.isMicro ? 8.0 : 10.0;
    final iconSize = windowSize.isMicro ? 16.0 : 18.0;
    final titleFontSize = windowSize.isMicro ? 11.0 : 13.0;
    final subtitleFontSize = windowSize.isMicro ? 9.0 : 11.0;
    final chevronSize = windowSize.isMicro ? 14.0 : 16.0;
    
    return GestureDetector(
      onTap: () => _navigateToOverview(),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: iconSize,
              color: theme.colorScheme.mutedForeground,
            ),
            SizedBox(width: windowSize.isMicro ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _semester!.overviewName ?? 'Semester Overview',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: titleFontSize,
                      color: theme.colorScheme.foreground,
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
            Icon(
              Icons.chevron_right,
              size: chevronSize,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubjectList(
    ThemeData theme,
    List<SubjectInfo> subjects,
    Map<SubjectInfo, List<SubjectInfo>> hierarchy,
    WindowSize windowSize,
  ) {
    final widgets = <Widget>[];

    for (final subject in subjects) {
      // Check if this is a top-level subject in hierarchy
      final isTopLevel = hierarchy.containsKey(subject);
      final children = hierarchy[subject] ?? [];
      final isSelected = subject.code == widget.subjectId;
      final hasChildren = children.isNotEmpty;
      final isExpanded = _expandedAccordionItems.contains(subject.id);

      if (hasChildren && isTopLevel) {
        // Parent subject with accordion
        widgets.add(
          _buildAccordionItem(theme, subject, children, isSelected, isExpanded, windowSize),
        );
      } else if (isTopLevel) {
        // Single subject without children
        widgets.add(_buildSingleSubjectItem(theme, subject, isSelected, windowSize));
      }
      // Skip children as they're handled by their parent's accordion
    }

    return widgets;
  }

  Widget _buildAccordionItem(
    ThemeData theme,
    SubjectInfo parent,
    List<SubjectInfo> children,
    bool isParentSelected,
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
    final childLeftMargin = windowSize.isMicro ? 18.0 : 24.0;
    final childVerticalPadding = windowSize.isMicro ? 6.0 : 8.0;
    final childIconSize = windowSize.isMicro ? 10.0 : 12.0;
    final childNameFontSize = windowSize.isMicro ? 10.0 : 12.0;
    final childCodeFontSize = windowSize.isMicro ? 8.0 : 9.0;
    
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
              color: isParentSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
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
                      _navigateToSubject(parent);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parent.name,
                          style: TextStyle(
                            fontSize: nameFontSize,
                            fontWeight: isParentSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isParentSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.foreground,
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
            final isChildItemSelected = child.code == widget.subjectId;
            return GestureDetector(
              onTap: () => _navigateToSubject(child),
              child: Container(
                margin: EdgeInsets.only(
                  left: childLeftMargin,
                  right: horizontalMargin,
                  top: 2,
                  bottom: 2,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: childVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: isChildItemSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      RadixIcons.file,
                      size: childIconSize,
                      color: isChildItemSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.mutedForeground,
                    ),
                    SizedBox(width: windowSize.isMicro ? 6 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: TextStyle(
                              fontSize: childNameFontSize,
                              fontWeight: isChildItemSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isChildItemSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.foreground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            child.code.toUpperCase(),
                            style: TextStyle(
                              fontSize: childCodeFontSize,
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

  Widget _buildSingleSubjectItem(
    ThemeData theme,
    SubjectInfo subject,
    bool isSelected,
    WindowSize windowSize,
  ) {
    final horizontalMargin = windowSize.isMicro ? 8.0 : 12.0;
    final horizontalPadding = windowSize.isMicro ? 8.0 : 12.0;
    final verticalPadding = windowSize.isMicro ? 8.0 : 10.0;
    final indentWidth = windowSize.isMicro ? 16.0 : 22.0;
    final nameFontSize = windowSize.isMicro ? 11.0 : 13.0;
    final codeFontSize = windowSize.isMicro ? 9.0 : 10.0;
    
    return GestureDetector(
      onTap: () => _navigateToSubject(subject),
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
            SizedBox(width: indentWidth), // Indent to align with accordion items
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: TextStyle(
                      fontSize: nameFontSize,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.foreground,
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

  Widget _buildContent(ThemeData theme, WindowSize windowSize) {
    if (_isLoading) {
      return const ContentLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return ContentErrorWidget(
        message: _getErrorTitle(),
        details: _errorMessage,
        onRetry: () => _retryLoadContent(),
      );
    }

    if (_contentBlocks.isEmpty) {
      return const ContentErrorWidget(
        message: 'No content available',
        details: 'The page appears to be empty.',
      );
    }

    // Build content with animated navigation cards
    // Note: MarkdownContentRenderer returns ListView which handles its own scrolling
    return Stack(
      children: [
        // Main content - MarkdownContentRenderer is a ListView that scrolls internally
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Track scroll for hiding/showing navigation cards
            if (notification is ScrollUpdateNotification) {
              final currentOffset = notification.metrics.pixels;
              if (currentOffset > _lastScrollOffset && currentOffset > 50) {
                _hasScrolledDown = true;
                if (_showNavigationCards) {
                  setState(() => _showNavigationCards = false);
                }
              } else if (currentOffset < _lastScrollOffset &&
                  _hasScrolledDown) {
                if (!_showNavigationCards) {
                  setState(() => _showNavigationCards = true);
                }
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
        // Animated Previous/Next Subject Navigation Cards
        if (_previousSubject != null ||
            _nextSubject != null ||
            _canNavigateToOverview)
          _buildAnimatedPrevNextNavigation(theme, windowSize),
      ],
    );
  }

  /// Build animated previous/next subject navigation cards
  /// Hides when scrolling down, shows when scrolling up
  Widget _buildAnimatedPrevNextNavigation(ThemeData theme, WindowSize windowSize) {
    // Responsive sizing
    final horizontalMargin = windowSize.isMicro ? 12.0 : 16.0;
    final bottomOffset = windowSize.isMicro ? 12.0 : 16.0;
    final hiddenOffset = windowSize.isMicro ? -80.0 : -100.0;
    final containerPadding = windowSize.isMicro ? 8.0 : 12.0;
    final cardPadding = windowSize.isMicro ? 8.0 : 10.0;
    final borderRadius = windowSize.isMicro ? 10.0 : 12.0;
    final iconSize = windowSize.isMicro ? 18.0 : 20.0;
    final labelFontSize = windowSize.isMicro ? 9.0 : 10.0;
    final codeFontSize = windowSize.isMicro ? 11.0 : 13.0;
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
            // Previous subject card OR Overview card (when on first subject)
            if (_previousSubject != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToSubject(_previousSubject!),
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
                                _previousSubject!.code.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: codeFontSize,
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
            else if (_canNavigateToOverview)
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToOverview(),
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
                                'Back to',
                                style: TextStyle(
                                  fontSize: labelFontSize,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                              Text(
                                'Overview',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: codeFontSize,
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
            // Next subject card
            if (_nextSubject != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToSubject(_nextSubject!),
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
                                _nextSubject!.code.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: codeFontSize,
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
