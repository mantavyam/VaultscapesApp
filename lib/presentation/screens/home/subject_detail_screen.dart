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
import '../feedback_collaborate/feedback_collaborate_screen.dart';

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
          _log('Previous subject: ${_previousSubject?.code ?? "none"}');
          _log('Next subject: ${_nextSubject?.code ?? "none"}');
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
        // Swipe left to right - go to previous subject
        else if (horizontalDelta > 500 && _previousSubject != null) {
          _navigateToSubject(_previousSubject!);
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
                title: _buildBreadcrumb(theme),
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
                if (_subject != null) _buildSubjectHeader(theme),
                // Content area with scroll controller
                Expanded(child: _buildContent(theme)),
              ],
            ),
          ),
          // Animated sidebar overlay
          if (_isSidebarOpen ||
              _sidebarAnimationController.status == AnimationStatus.reverse)
            _buildAnimatedSidebar(theme),
          // Loading overlay (on top of everything including skeleton)
          if (_isLoading || _isRefreshing) _buildLoadingOverlay(theme),
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
                padding: const EdgeInsets.all(FormSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.article_outlined,
                          size: 40,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: FormSpacing.xl),
                    Text(
                      _isRefreshing
                          ? 'Refreshing content...'
                          : 'Loading content...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: FormSpacing.sm),
                    Text(
                      'Please wait while we fetch the content.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: FormSpacing.xl),
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

  /// Build breadcrumb with horizontal scroll: UG / BTECH / CSE-IT / SEM-X / SUBCODE
  Widget _buildBreadcrumb(ThemeData theme) {
    if (_subject == null || _semester == null) {
      return const Text('Loading...');
    }

    final items = [
      'BTECH',
      'CSE-IT',
      'SEM${widget.semesterId}',
      _subject!.code.toUpperCase(),
    ];

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

  Widget _buildSubjectHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subject!.code.toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
                    style: TextStyle(
                      fontSize: 11,
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

  /// Build hierarchical sidebar with accordion for parent/child subjects
  /// Includes bifurcation between core and specialization subjects
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
          // Swipe navigation hint at bottom
          _buildNavigationHint(theme),
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
      final isSelected = subject.code == widget.subjectId;
      final hasChildren = children.isNotEmpty;
      final isExpanded = _expandedAccordionItems.contains(subject.id);

      if (hasChildren && isTopLevel) {
        // Parent subject with accordion
        widgets.add(
          _buildAccordionItem(theme, subject, children, isSelected, isExpanded),
        );
      } else if (isTopLevel) {
        // Single subject without children
        widgets.add(_buildSingleSubjectItem(theme, subject, isSelected));
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
  ) {
    // Check if any child is selected
    final isChildSelected = children.any((c) => c.code == widget.subjectId);

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
            decoration: BoxDecoration(
              color: isParentSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isParentSelected || isChildSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                // Expand/collapse icon
                Icon(
                  isExpanded ? RadixIcons.chevronDown : RadixIcons.chevronRight,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 8),
                // Subject code
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _navigateToSubject(parent);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parent.code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isParentSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isParentSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.foreground,
                          ),
                        ),
                        Text(
                          parent.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                    borderRadius: BorderRadius.circular(10),
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
            final isChildItemSelected = child.code == widget.subjectId;
            return GestureDetector(
              onTap: () => _navigateToSubject(child),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                margin: const EdgeInsets.only(left: 24),
                decoration: BoxDecoration(
                  color: isChildItemSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isChildItemSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.border,
                      width: isChildItemSelected ? 3 : 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.code.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isChildItemSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isChildItemSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.foreground,
                      ),
                    ),
                    Text(
                      child.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
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
  ) {
    return GestureDetector(
      onTap: () => _navigateToSubject(subject),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 22), // Indent to align with accordion items
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.code.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.foreground,
                    ),
                  ),
                  Text(
                    subject.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationHint(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                RadixIcons.arrowLeft,
                size: 14,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 4),
              Icon(
                RadixIcons.arrowRight,
                size: 14,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                'Swipe to switch subjects',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
          if (_previousSubject != null || _nextSubject != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (_previousSubject != null)
                  Expanded(
                    child: Text(
                      '← ${_previousSubject!.code}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (_nextSubject != null)
                  Expanded(
                    child: Text(
                      '${_nextSubject!.code} →',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
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
          child: MarkdownContentRenderer(blocks: _contentBlocks),
        ),
        // Animated Previous/Next Subject Navigation Cards
        if (_previousSubject != null || _nextSubject != null)
          _buildAnimatedPrevNextNavigation(theme),
      ],
    );
  }

  /// Build animated previous/next subject navigation cards
  /// Hides when scrolling down, shows when scrolling up
  Widget _buildAnimatedPrevNextNavigation(ThemeData theme) {
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
            // Previous subject card
            if (_previousSubject != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToSubject(_previousSubject!),
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
                                _previousSubject!.code.toUpperCase(),
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
            // Next subject card
            if (_nextSubject != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToSubject(_nextSubject!),
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
