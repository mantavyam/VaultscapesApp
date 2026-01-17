import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/cards/subject_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../../core/constants/route_constants.dart';
import '../../../data/models/semester_model.dart';

/// Semester overview screen with sections
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
            // Semester Header
            _buildHeader(context, semester, theme),
            const SizedBox(height: 24),
            // Accordion Sections
            Accordion(
              items: [
                // Syllabus Section
                AccordionItem(
                  trigger: AccordionTrigger(
                    child: const Text('Syllabus'),
                  ),
                  content: _buildSyllabusSection(context, semester),
                ),
                // Subject Wise Resources
                AccordionItem(
                  trigger: AccordionTrigger(
                    child: const Text('Subject Wise Resources'),
                  ),
                  content: _buildSubjectsSection(context, semester),
                ),
                // Notes Section
                AccordionItem(
                  trigger: AccordionTrigger(
                    child: const Text('Notes'),
                  ),
                  content: _buildNotesSection(context),
                ),
                // Assignments Section
                AccordionItem(
                  trigger: AccordionTrigger(
                    child: const Text('Assignments'),
                  ),
                  content: _buildAssignmentsSection(context),
                ),
                // Previous Year Questions
                AccordionItem(
                  trigger: AccordionTrigger(
                    child: const Text('Previous Year Questions'),
                  ),
                  content: _buildPYQSection(context),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, SemesterModel semester, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildSyllabusSection(BuildContext context, SemesterModel semester) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Download the complete syllabus for this semester.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            onPressed: () => _downloadSyllabus(context, semester),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download),
                SizedBox(width: 8),
                Text('Download Syllabus PDF'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsSection(BuildContext context, SemesterModel semester) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (semester.coreSubjects.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Core Subjects',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.mutedForeground,
                ),
              ),
            ),
            ...semester.coreSubjects.map((subject) => SubjectCard(
                  subject: subject,
                  onTap: () {
                    context.push(
                      RouteConstants.subjectPath(
                        semester.id.toString(),
                        subject.code,
                      ),
                    );
                  },
                )),
          ],
          if (semester.specializationSubjects.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Specialization Subjects',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.mutedForeground,
                ),
              ),
            ),
            ...semester.specializationSubjects.map((subject) => SubjectCard(
                  subject: subject,
                  onTap: () {
                    context.push(
                      RouteConstants.subjectPath(
                        semester.id.toString(),
                        subject.code,
                      ),
                    );
                  },
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                child: const Text('Short Notes'),
              ),
              Chip(
                child: const Text('Mid-Sem Notes'),
              ),
              Chip(
                child: const Text('End-Sem Notes'),
              ),
              Chip(
                child: const Text('One-shot Notes'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Notes are available per subject. Navigate to a subject to access notes.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.mutedForeground,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assignments and their solutions are organized by subject.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.mutedForeground,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Navigate to a specific subject to view assignments.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.mutedForeground,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPYQSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPYQCategory(context, 'Mid-Sem PYQs', Icons.quiz_outlined),
          const SizedBox(height: 12),
          _buildPYQCategory(context, 'End-Sem PYQs', Icons.assignment_outlined),
          const SizedBox(height: 16),
          Text(
            'Subject-wise PYQs available in each subject detail page.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.mutedForeground,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPYQCategory(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      child: Clickable(
        onPressed: () {
          // Navigate to PYQ list - could be implemented in Phase 2
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Basic(
            leading: Icon(icon, color: theme.colorScheme.primary),
            title: Text(title),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
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

  void _downloadSyllabus(BuildContext context, SemesterModel semester) {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            title: const Text('Download started'),
            subtitle: Text('Downloading ${semester.name} syllabus...'),
            leading: const Icon(Icons.download),
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
