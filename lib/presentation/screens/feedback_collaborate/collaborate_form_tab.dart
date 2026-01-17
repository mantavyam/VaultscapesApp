import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/feedback_provider.dart';
import '../../../data/models/collaboration_model.dart';

/// Collaboration form tab
class CollaborateFormTab extends StatefulWidget {
  const CollaborateFormTab({super.key});

  @override
  State<CollaborateFormTab> createState() => _CollaborateFormTabState();
}

class _CollaborateFormTabState extends State<CollaborateFormTab> {
  final _subjectController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creditNameController = TextEditingController();
  final _adminNotesController = TextEditingController();

  List<SubmissionType> _selectedSubmissionTypes = [];
  SourceType _selectedSource = SourceType.selfCreated;
  int _selectedSemester = 1;
  bool _wantsCredit = false;
  List<String> _filePaths = [];

  @override
  void dispose() {
    _subjectController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _creditNameController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<FeedbackProvider>(
      builder: (context, feedbackProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Contribute to Vaultscapes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your notes, assignments, or valuable resources.',
                style: TextStyle(color: theme.colorScheme.mutedForeground),
              ),
              const SizedBox(height: 24),

              // Submission Type
              const Text('What are you submitting?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SubmissionType.values.map((type) {
                  final isSelected = _selectedSubmissionTypes.contains(type);
                  return Chip(
                    style: isSelected ? ButtonVariance.primary : ButtonVariance.outline,
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSubmissionTypes.remove(type);
                        } else {
                          _selectedSubmissionTypes.add(type);
                        }
                      });
                    },
                    child: Text(_getSubmissionTypeLabel(type)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Source Selection
              const Text('Source of the resource'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SourceType.values.map((source) {
                  final isSelected = _selectedSource == source;
                  return Chip(
                    style: isSelected ? ButtonVariance.primary : ButtonVariance.outline,
                    onPressed: () => setState(() => _selectedSource = source),
                    child: Text(_getSourceLabel(source)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Semester Selection
              const Text('Semester'),
              const SizedBox(height: 8),
              _buildSemesterSelector(),
              const SizedBox(height: 16),

              // Subject Details
              const Text('Subject Details'),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectController,
              ),
              const SizedBox(height: 16),

              // File Upload
              const Text('Upload Files'),
              const SizedBox(height: 8),
              OutlineButton(
                onPressed: _pickFiles,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text('Choose Files'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // URL Submission
              const Text('URL Submission (Optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description'),
              const SizedBox(height: 8),
              TextArea(
                controller: _descriptionController,
                initialHeight: 100,
              ),
              const SizedBox(height: 16),

              // Credit Preference
              const Text('Would you like to be credited?'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    style: _wantsCredit ? ButtonVariance.primary : ButtonVariance.outline,
                    onPressed: () => setState(() => _wantsCredit = true),
                    child: const Text('Yes'),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    style: !_wantsCredit ? ButtonVariance.primary : ButtonVariance.outline,
                    onPressed: () => setState(() => _wantsCredit = false),
                    child: const Text('No'),
                  ),
                ],
              ),
              if (_wantsCredit) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _creditNameController,
                ),
              ],
              const SizedBox(height: 16),

              // Admin Notes
              const Text('Notes for Admins (Optional)'),
              const SizedBox(height: 8),
              TextArea(
                controller: _adminNotesController,
                initialHeight: 80,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: feedbackProvider.isCollaborationSubmitting ? null : _submitCollaboration,
                  child: feedbackProvider.isCollaborationSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting...'),
                          ],
                        )
                      : const Text('Submit Contribution'),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSemesterSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(8, (index) {
        final semester = index + 1;
        final isSelected = _selectedSemester == semester;
        return Chip(
          style: isSelected ? ButtonVariance.primary : ButtonVariance.outline,
          onPressed: () => setState(() => _selectedSemester = semester),
          child: Text('Sem $semester'),
        );
      }),
    );
  }

  void _pickFiles() {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            title: const Text('File picker coming soon'),
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

  void _submitCollaboration() async {
    if (_selectedSubmissionTypes.isEmpty) {
      showToast(
        context: context,
        builder: (context, overlay) {
          return SurfaceCard(
            child: Basic(
              title: const Text('Please select submission type'),
              leading: Icon(Icons.warning, color: Theme.of(context).colorScheme.destructive),
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

    final collaboration = CollaborationModel(
      submissionTypes: _selectedSubmissionTypes,
      source: _selectedSource,
      semesterSelection: _selectedSemester,
      subjectDetails: _subjectController.text,
      filePaths: _filePaths,
      urlSubmission: _urlController.text.isNotEmpty ? _urlController.text : null,
      description: _descriptionController.text,
      wantsCredit: _wantsCredit,
      creditName: _wantsCredit ? _creditNameController.text : null,
      adminNotes: _adminNotesController.text.isNotEmpty ? _adminNotesController.text : null,
    );

    final provider = context.read<FeedbackProvider>();
    await provider.submitCollaboration(collaboration);

    if (mounted) {
      showToast(
        context: context,
        builder: (context, overlay) {
          return SurfaceCard(
            child: Basic(
              title: const Text('Contribution submitted!'),
              leading: const Icon(Icons.check_circle, color: Colors.green),
              trailing: IconButton.ghost(
                icon: const Icon(Icons.close),
                onPressed: () => overlay.close(),
              ),
            ),
          );
        },
        location: ToastLocation.bottomCenter,
      );
      _resetForm();
    }
  }

  void _resetForm() {
    _subjectController.clear();
    _urlController.clear();
    _descriptionController.clear();
    _creditNameController.clear();
    _adminNotesController.clear();
    setState(() {
      _selectedSubmissionTypes = [];
      _selectedSource = SourceType.selfCreated;
      _wantsCredit = false;
      _filePaths = [];
    });
  }

  String _getSubmissionTypeLabel(SubmissionType type) {
    switch (type) {
      case SubmissionType.notes: return 'Notes';
      case SubmissionType.assignment: return 'Assignment';
      case SubmissionType.pyq: return 'PYQ';
      case SubmissionType.questionBank: return 'Question Bank';
      case SubmissionType.referenceBook: return 'Reference Book';
      case SubmissionType.tutorial: return 'Tutorial';
      case SubmissionType.other: return 'Other';
    }
  }

  String _getSourceLabel(SourceType source) {
    switch (source) {
      case SourceType.selfCreated: return 'Self Created';
      case SourceType.teacherProvided: return 'Teacher Provided';
      case SourceType.internetSource: return 'Internet Source';
      case SourceType.otherStudent: return 'Other Student';
      case SourceType.other: return 'Other';
    }
  }
}
