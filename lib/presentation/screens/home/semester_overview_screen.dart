import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/cards/subject_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../../data/models/semester_model.dart';

/// Semester overview screen following "One Webpage = One Screen" principle
/// Shows list of subjects, tapping navigates to dynamic content screen
class SemesterOverviewScreen extends StatefulWidget {
  final String semesterId;

  const SemesterOverviewScreen({
    super.key,
    required this.semesterId,
  });

  @override
  State<SemesterOverviewScreen> createState() => _SemesterOverviewScreenState();
}

class _SemesterOverviewScreenState extends State<SemesterOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semId = int.tryParse(widget.semesterId);
      if (semId != null) {
        context.read<NavigationProvider>().selectSemester(semId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        final semester = navProvider.selectedSemester;

        if (navProvider.isLoading && semester == null) {
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

        if (semester == null) {
          return Scaffold(
            headers: [
              AppBar(
                leading: [
                  IconButton.ghost(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                ],
                title: const Text('Semester Not Found'),
              ),
            ],
            child: AppErrorWidget.generic(
              message: 'Semester not found',
              onRetry: () => context.pop(),
            ),
          );
        }

        return _buildContent(context, semester);
      },
    );
  }

  Widget _buildContent(BuildContext context, SemesterModel semester) {
    final theme = Theme.of(context);

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ],
          title: Text(semester.name),
          trailing: [
            IconButton.ghost(
              icon: const Icon(Icons.share),
              onPressed: () => _shareSemester(context, semester),
            ),
          ],
        ),
      ],
      child: SingleChildScrollView(
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
              ...semester.coreSubjects.map((subject) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SubjectCard(
                  subject: subject,
                  onTap: () => _navigateToSubjectContent(context, semester, subject),
                ),
              )),
              const SizedBox(height: 16),
            ],

            // Specialization Subjects Section
            if (semester.specializationSubjects.isNotEmpty) ...[
              _buildSectionHeader(context, 'Specialization Subjects', theme),
              const SizedBox(height: 12),
              ...semester.specializationSubjects.map((subject) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SubjectCard(
                  subject: subject,
                  onTap: () => _navigateToSubjectContent(context, semester, subject),
                ),
              )),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SemesterModel semester, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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

  Widget _buildOverviewButton(BuildContext context, SemesterModel semester, ThemeData theme) {
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

  Widget _buildSectionHeader(BuildContext context, String title, ThemeData theme) {
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

  void _navigateToOverviewContent(BuildContext context, SemesterModel semester) {
    if (semester.overviewGitbookUrl == null) return;
    
    final encodedUrl = Uri.encodeComponent(semester.overviewGitbookUrl!);
    final title = Uri.encodeComponent(semester.overviewName ?? '${semester.name} Overview');
    final subtitle = Uri.encodeComponent('Semester ${semester.id}');
    
    context.push('/main/home/content?title=$title&url=$encodedUrl&subtitle=$subtitle');
  }

  void _navigateToSubjectContent(BuildContext context, SemesterModel semester, SubjectInfo subject) {
    if (subject.gitbookUrl == null) {
      // Fallback: show toast if no gitbook URL
      showToast(
        context: context,
        builder: (context, overlay) {
          return SurfaceCard(
            child: Basic(
              title: const Text('Content not available'),
              subtitle: const Text('No content URL configured for this subject'),
              leading: const Icon(Icons.info_outline),
              trailing: IconButton.ghost(
                icon: const Icon(Icons.close),
                onPressed: () => overlay.close(),
              ),
            ),
          );
        },
        location: ToastLocation.bottomCenter,
      );
      return;
    }
    
    final encodedUrl = Uri.encodeComponent(subject.gitbookUrl!);
    final title = Uri.encodeComponent(subject.name);
    final subtitle = Uri.encodeComponent(subject.code);
    
    context.push('/main/home/content?title=$title&url=$encodedUrl&subtitle=$subtitle');
  }

  void _shareSemester(BuildContext context, SemesterModel semester) {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            title: const Text('Share feature coming soon'),
            leading: const Icon(Icons.share),
            trailing: IconButton.ghost(
              icon: const Icon(Icons.close),
              onPressed: () => overlay.close(),
            ),
          ),
        );
      },
      location: ToastLocation.bottomCenter,
    );
  }
}
