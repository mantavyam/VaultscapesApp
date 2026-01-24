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
class SemesterOverviewScreen extends StatefulWidget {
  final String semesterId;

  const SemesterOverviewScreen({super.key, required this.semesterId});

  @override
  State<SemesterOverviewScreen> createState() => _SemesterOverviewScreenState();
}

class _SemesterOverviewScreenState extends State<SemesterOverviewScreen> {
  late PageController _pageController;
  late ScrollController _scrollController;
  int _currentPageIndex = 0;
  bool _isPageAnimating = false;

  // For bottom navigation cards animation on scroll
  bool _showNavigationCards = true;
  double _lastScrollOffset = 0;
  bool _hasScrolledDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semId = int.tryParse(widget.semesterId);
      if (semId != null) {
        context.read<NavigationProvider>().selectSemester(semId);
        // Initialize PageController to correct page after semesters are loaded
        final navProvider = context.read<NavigationProvider>();
        final semesters = navProvider.semesters;
        final index = semesters.indexWhere((s) => s.id == semId);
        if (index != -1) {
          setState(() {
            _currentPageIndex = index;
          });
          _pageController = PageController(initialPage: index);
        }
      }
    });

    // Initialize with default page controller (will be updated in postFrameCallback)
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

        return Scaffold(
          headers: [
            AppBar(
              leading: [
                IconButton.ghost(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ],
              title: Text(currentSemester.name),
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
                Theme.of(context),
              ),
            ],
          ),
        );
      },
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

    context.push(
      '/main/home/content?title=$title&url=$encodedUrl&subtitle=$subtitle',
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
