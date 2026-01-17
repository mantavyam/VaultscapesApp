import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../../data/models/semester_model.dart';

/// Subject detail screen with tabs
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
  SubjectInfo? _subject;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSubject();
  }

  void _loadSubject() {
    final navProvider = context.read<NavigationProvider>();
    final semId = int.tryParse(widget.semesterId);
    if (semId != null) {
      final semester = navProvider.getSemesterById(semId);
      if (semester != null) {
        _subject = semester.allSubjects
            .where((s) => s.code == widget.subjectId)
            .firstOrNull;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_subject == null) {
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

    return _buildContent(context, _subject!);
  }

  Widget _buildContent(BuildContext context, SubjectInfo subject) {
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
          title: Text(subject.code),
        ),
      ],
      child: Column(
        children: [
          // Subject Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject.code,
                  style: TextStyle(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Tabs(
            index: _currentTabIndex,
            onChanged: (index) => setState(() => _currentTabIndex = index),
            children: const [
              TabItem(child: Text('Syllabus')),
              TabItem(child: Text('Resources')),
              TabItem(child: Text('Notes')),
              TabItem(child: Text('Questions')),
              TabItem(child: Text('External')),
            ],
          ),
          const SizedBox(height: 8),
          // Tab content
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildSyllabusTab(context, subject),
                _buildResourcesTab(context, subject),
                _buildNotesTab(context, subject),
                _buildQuestionsTab(context, subject),
                _buildExternalTab(context, subject),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllabusTab(BuildContext context, SubjectInfo subject) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Syllabus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download the complete syllabus for ${subject.name}.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    onPressed: () => _downloadFile(context, 'Syllabus'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('Download Syllabus'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reference Books',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildReferenceItem(context, 'Introduction to Algorithms - CLRS'),
                  _buildReferenceItem(context, 'Data Structures - Seymour Lipschutz'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Basic(
        leading: const Icon(Icons.book_outlined),
        title: Text(title),
        trailing: IconButton.ghost(
          icon: const Icon(Icons.open_in_new),
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildResourcesTab(BuildContext context, SubjectInfo subject) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Accordion(
        items: List.generate(5, (index) {
          final moduleNum = index + 1;
          return AccordionItem(
            trigger: AccordionTrigger(
              child: Text('Module $moduleNum'),
            ),
            content: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildResourceItem(
                    context,
                    'Lecture Notes',
                    Icons.description_outlined,
                  ),
                  _buildResourceItem(
                    context,
                    'Video Lectures',
                    Icons.play_circle_outline,
                  ),
                  _buildResourceItem(
                    context,
                    'Practice Problems',
                    Icons.assignment_outlined,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResourceItem(BuildContext context, String title, IconData icon) {
    return Card(
      child: Clickable(
        onPressed: () => _downloadFile(context, title),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Basic(
            leading: Icon(icon),
            title: Text(title),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context, SubjectInfo subject) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildNoteCategory(context, 'Short Notes', Icons.notes),
          _buildNoteCategory(context, 'Mid-Sem Notes', Icons.summarize),
          _buildNoteCategory(context, 'End-Sem Notes', Icons.assignment),
          _buildNoteCategory(context, 'One-Shot Notes', Icons.flash_on),
        ],
      ),
    );
  }

  Widget _buildNoteCategory(BuildContext context, String title, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Basic(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          trailing: PrimaryButton(
            size: ButtonSize.small,
            onPressed: () => _downloadFile(context, title),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 16),
                SizedBox(width: 4),
                Text('Download'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsTab(BuildContext context, SubjectInfo subject) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuestionCategory(context, 'Question Bank'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Previous Year Questions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Mid-Sem', style: TextStyle(fontWeight: FontWeight.w500)),
                  _buildPYQList(context, 'Mid-Sem'),
                  const SizedBox(height: 12),
                  const Text('End-Sem', style: TextStyle(fontWeight: FontWeight.w500)),
                  _buildPYQList(context, 'End-Sem'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCategory(BuildContext context, String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Basic(
          leading: Icon(Icons.quiz_outlined,
              color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          trailing: PrimaryButton(
            size: ButtonSize.small,
            onPressed: () => _downloadFile(context, title),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 16),
                SizedBox(width: 4),
                Text('Download'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPYQList(BuildContext context, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(3, (index) {
          final year = 2024 - index;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Basic(
              title: Text('$type $year'),
              trailing: IconButton.ghost(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadFile(context, '$type $year'),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildExternalTab(BuildContext context, SubjectInfo subject) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'External Resources',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildExternalLink(
                    context,
                    'GeeksforGeeks',
                    'https://geeksforgeeks.org',
                  ),
                  _buildExternalLink(
                    context,
                    'Tutorialspoint',
                    'https://tutorialspoint.com',
                  ),
                  _buildExternalLink(
                    context,
                    'YouTube Tutorials',
                    'https://youtube.com',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalLink(BuildContext context, String title, String url) {
    return Clickable(
      onPressed: () {
        // Open URL
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Basic(
          leading: const Icon(Icons.link),
          title: Text(title),
          subtitle: Text(
            url,
            style: TextStyle(
              color: Theme.of(context).colorScheme.mutedForeground,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(Icons.open_in_new),
        ),
      ),
    );
  }

  void _downloadFile(BuildContext context, String fileName) {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            title: const Text('Download started'),
            subtitle: Text('Downloading $fileName...'),
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
