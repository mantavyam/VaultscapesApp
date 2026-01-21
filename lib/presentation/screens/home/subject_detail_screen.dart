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

/// Subject detail screen following "One Webpage = One Screen" principle
/// Fetches markdown content from Gitbook URL and renders dynamically
/// Includes breadcrumb navigation (BTECH/Semester-X/SUBCODE), NavigationRail sidebar,
/// and previous/next subject navigation
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

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final MarkdownContentService _contentService = MarkdownContentService();
  final MarkdownParser _parser = MarkdownParser();

  SubjectInfo? _subject;
  SemesterModel? _semester;
  bool _isLoading = true;
  bool _isFromCache = false;
  bool _isSidebarExpanded = false;
  String? _errorMessage;
  MarkdownErrorType? _errorType;
  List<ContentBlock> _contentBlocks = [];

  // Previous and next subjects for navigation
  SubjectInfo? _previousSubject;
  SubjectInfo? _nextSubject;

  // For tracking swipe gesture
  double _horizontalDragStart = 0;
  double _verticalDragStart = 0;
  bool _isHorizontalSwipe = false;

  @override
  void initState() {
    super.initState();
    _loadSubjectAndContent();
  }

  @override
  void didUpdateWidget(SubjectDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectId != widget.subjectId || 
        oldWidget.semesterId != widget.semesterId) {
      _loadSubjectAndContent();
    }
  }

  Future<void> _loadSubjectAndContent() async {
    // First, find the subject from navigation data
    final navProvider = context.read<NavigationProvider>();
    final semId = int.tryParse(widget.semesterId);
    
    if (semId != null) {
      _semester = navProvider.getSemesterById(semId);
      if (_semester != null) {
        final subjects = _semester!.allSubjects;
        final currentIndex = subjects.indexWhere((s) => s.code == widget.subjectId);
        
        if (currentIndex != -1) {
          _subject = subjects[currentIndex];
          
          // Set previous and next subjects
          _previousSubject = currentIndex > 0 ? subjects[currentIndex - 1] : null;
          _nextSubject = currentIndex < subjects.length - 1 ? subjects[currentIndex + 1] : null;
        }
      }
    }

    if (_subject == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Subject not found';
        _errorType = MarkdownErrorType.notFound;
      });
      return;
    }

    // If we have a gitbook URL, fetch the content
    if (_subject!.gitbookUrl != null) {
      await _loadContent(_subject!.gitbookUrl!);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No content URL configured for this subject';
        _errorType = MarkdownErrorType.notFound;
      });
    }
  }

  Future<void> _loadContent(String gitbookUrl) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
    });

    try {
      await _contentService.init();
      final result = await _contentService.fetchContent(gitbookUrl);

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
    if (_subject?.gitbookUrl == null) return;
    await _contentService.clearCacheFor(_subject!.gitbookUrl!);
    await _loadContent(_subject!.gitbookUrl!);
  }

  void _navigateToSubject(SubjectInfo subject) {
    setState(() {
      _isSidebarExpanded = false;
    });
    context.go(RouteConstants.subjectPath(widget.semesterId, subject.code));
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
      // Only trigger if the user explicitly drags more horizontally than vertically
      onHorizontalDragStart: (details) {
        _horizontalDragStart = details.globalPosition.dx;
        _verticalDragStart = details.globalPosition.dy;
        _isHorizontalSwipe = false;
      },
      onHorizontalDragUpdate: (details) {
        final horizontalDelta = (details.globalPosition.dx - _horizontalDragStart).abs();
        final verticalDelta = (details.globalPosition.dy - _verticalDragStart).abs();
        // Only consider it a horizontal swipe if horizontal movement is 2x vertical
        if (horizontalDelta > 50 && horizontalDelta > verticalDelta * 2) {
          _isHorizontalSwipe = true;
        }
      },
      onHorizontalDragEnd: (details) {
        if (!_isHorizontalSwipe) return;
        if (details.primaryVelocity == null) return;
        
        final horizontalDelta = details.primaryVelocity!;
        // Swipe right to left - go to next subject (requires strong velocity)
        if (horizontalDelta < -500 && _nextSubject != null) {
          _navigateToSubject(_nextSubject!);
        }
        // Swipe left to right - go to previous subject
        else if (horizontalDelta > 500 && _previousSubject != null) {
          _navigateToSubject(_previousSubject!);
        }
        _isHorizontalSwipe = false;
      },
      child: Scaffold(
        headers: [
          AppBar(
            leading: [
              IconButton.ghost(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ],
            // Breadcrumb format title: BTECH / Semester-X / SUBCODE
            title: _subject != null && _semester != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BTECH',
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ' / ',
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Semester-${widget.semesterId}',
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ' / ',
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _subject!.code.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.foreground,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : const Text('Loading...'),
            trailing: [
              // Sidebar toggle button
              IconButton.ghost(
                icon: Icon(
                  _isSidebarExpanded ? RadixIcons.cross1 : RadixIcons.hamburgerMenu,
                ),
                onPressed: () {
                  setState(() {
                    _isSidebarExpanded = !_isSidebarExpanded;
                  });
                },
              ),
              if (!_isLoading)
                IconButton.ghost(
                  icon: const Icon(RadixIcons.reload),
                  onPressed: _refreshContent,
                ),
            ],
          ),
        ],
        child: Column(
          children: [
            // Main content area with expandable sidebar
            Expanded(
              child: Row(
                children: [
                  // Expandable sidebar (shows only when expanded)
                  _buildNavigationRail(theme),
                  // Content area
                  Expanded(
                    child: Column(
                      children: [
                        // Header with subject info and cache indicator
                        if (_subject != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted.withValues(alpha: 0.3),
                              border: Border(
                                bottom: BorderSide(color: theme.colorScheme.border),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _subject!.code,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_semester != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          _semester!.name,
                                          style: theme.typography.xSmall.copyWith(
                                            color: theme.colorScheme.mutedForeground,
                                          ),
                                        ),
                                      ],
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
                                          style: theme.typography.xSmall.copyWith(
                                            color: theme.colorScheme.secondaryForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        // Content area
                        Expanded(
                          child: _buildContent(theme),
                        ),
                      ],
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

  /// Build NavigationRail sidebar with subject codes
  Widget _buildNavigationRail(ThemeData theme) {
    if (_semester == null) {
      // Return empty container when collapsed or no semester
      return const SizedBox.shrink();
    }
    
    // Don't show sidebar if not expanded
    if (!_isSidebarExpanded) {
      return const SizedBox.shrink();
    }
    
    final subjects = _semester!.allSubjects;

    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(
          right: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  RadixIcons.file,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Subjects',
                    style: theme.typography.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Subject list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final isSelected = subject.code == widget.subjectId;
                
                return GestureDetector(
                  onTap: () => _navigateToSubject(subject),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    child: Text(
                      subject.code.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.foreground,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
        onRetry: _subject?.gitbookUrl != null ? () => _loadContent(_subject!.gitbookUrl!) : null,
      );
    }

    if (_contentBlocks.isEmpty) {
      return const ContentErrorWidget(
        message: 'No content available',
        details: 'The page appears to be empty.',
      );
    }

    // Build content with previous/next navigation at the bottom
    return Column(
      children: [
        Expanded(
          child: MarkdownContentRenderer(
            blocks: _contentBlocks,
          ),
        ),
        // Previous/Next Subject Navigation Cards
        if (_previousSubject != null || _nextSubject != null)
          _buildPrevNextNavigation(theme),
      ],
    );
  }

  /// Build previous/next subject navigation cards
  Widget _buildPrevNextNavigation(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      child: Row(
        children: [
          // Previous subject card
          if (_previousSubject != null)
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToSubject(_previousSubject!),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: theme.colorScheme.primary,
                              ),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
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
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.mutedForeground,
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
