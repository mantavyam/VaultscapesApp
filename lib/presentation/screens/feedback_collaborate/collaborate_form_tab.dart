import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/feedback_provider.dart';
import '../../../data/models/collaboration_model.dart';

/// Collaboration form tab - Based on PRD requirements
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

  Set<SubmissionType> _selectedSubmissionTypes = {};
  SourceType? _selectedSource;
  int? _selectedSemester;
  bool? _wantsCredit;
  List<PlatformFile> _files = [];

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
              // Form Header
              const Text(
                'Collaborate on Vaultscapes',
              ).h3(),
              const SizedBox(height: 8),
              const Text(
                'Share your notes, assignments, or valuable resources with fellow students.',
              ).muted(),
              const SizedBox(height: 24),

              // Submission Type (Checkbox Group)
              _buildFormSection(
                theme: theme,
                label: 'What are you submitting?',
                description: '(Respondents can select as many as they like)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: SubmissionType.values.map((type) {
                    final isSelected = _selectedSubmissionTypes.contains(type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Checkbox(
                            state: isSelected
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            onChanged: (state) {
                              setState(() {
                                if (state == CheckboxState.checked) {
                                  _selectedSubmissionTypes.add(type);
                                } else {
                                  _selectedSubmissionTypes.remove(type);
                                }
                              });
                            },
                            trailing: Text(_getSubmissionTypeLabel(type)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Source Selection (Radio Group)
              _buildFormSection(
                theme: theme,
                label: 'What is the source of your submission?',
                description: null,
                child: RadioGroup<SourceType>(
                  value: _selectedSource,
                  onChanged: (value) => setState(() => _selectedSource = value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: SourceType.values.map((source) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RadioItem<SourceType>(
                          value: source,
                          trailing: Text(_getSourceLabel(source)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Semester Selection (Select dropdown)
              _buildFormSection(
                theme: theme,
                label: 'For which semester are you submitting this resource?',
                description: '(Respondents can select up to 1)',
                child: Select<int>(
                  value: _selectedSemester,
                  placeholder: const Text('Select semester'),
                  onChanged: (value) =>
                      setState(() => _selectedSemester = value),
                  itemBuilder: (context, value) =>
                      Text('Semester $value / BTECH'),
                  popup: SelectPopup(
                    items: SelectItemList(
                      children: List.generate(8, (index) {
                        final semester = index + 1;
                        return SelectItemButton<int>(
                          value: semester,
                          child: Text('Semester $semester / BTECH'),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // Subject Name and Code
              _buildFormSection(
                theme: theme,
                label: 'What is the subject name and code?',
                description: '(E.g., Computer Science - CS101)',
                child: TextField(
                  controller: _subjectController,
                  placeholder: const Text('Subject Name - Subject Code'),
                ),
              ),

              // File Upload
              _buildFormSection(
                theme: theme,
                label: 'Attach (Field 1): Please attach your files here',
                description:
                    'You can upload 10 files at a time with a size Limit of 5 mb',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (_files.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _files.map((file) {
                          return _buildFileChip(theme, file, () {
                            setState(() {
                              _files.remove(file);
                            });
                          });
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // URL Submission
              _buildFormSection(
                theme: theme,
                label: 'Attach (Field 2): Optional for URL Submission',
                description: null,
                child: TextField(
                  controller: _urlController,
                  placeholder: const Text('https://...'),
                  keyboardType: TextInputType.url,
                ),
              ),

              // Description
              _buildFormSection(
                theme: theme,
                label: 'Describe your submission.',
                description:
                    "A Short explanation of what this resource contains or why it's useful.",
                child: TextArea(
                  controller: _descriptionController,
                  placeholder: const Text(
                      'E.g., Complete notes for Module 3 covering Data Structures...'),
                  initialHeight: 100,
                ),
              ),

              // Credit Preference (Yes/No buttons)
              _buildFormSection(
                theme: theme,
                label:
                    'Would you like to be credited for this submission on Vaultscapes?',
                description: null,
                child: Row(
                  children: [
                    _wantsCredit == true
                        ? PrimaryButton(
                            onPressed: () => setState(() => _wantsCredit = true),
                            child: const Text('YES'),
                          )
                        : OutlineButton(
                            onPressed: () => setState(() => _wantsCredit = true),
                            child: const Text('YES'),
                          ),
                    const SizedBox(width: 12),
                    _wantsCredit == false
                        ? PrimaryButton(
                            onPressed: () => setState(() => _wantsCredit = false),
                            child: const Text('NO'),
                          )
                        : OutlineButton(
                            onPressed: () => setState(() => _wantsCredit = false),
                            child: const Text('NO'),
                          ),
                  ],
                ),
              ),

              // Credit Name (conditional)
              if (_wantsCredit == true)
                _buildFormSection(
                  theme: theme,
                  label:
                      "If yes, please provide the name or details you'd like to be credited with.",
                  description:
                      '(E.g., Full Name, Email, Social Media Handle, or "Anonymous")',
                  child: TextField(
                    controller: _creditNameController,
                    placeholder: const Text('How should we credit you?'),
                  ),
                ),

              // Admin Notes
              _buildFormSection(
                theme: theme,
                label: 'Optional Notes for Admins',
                description:
                    "Any additional notes or information you'd like to share with us?",
                child: TextArea(
                  controller: _adminNotesController,
                  placeholder: const Text(
                      'E.g., Please update the existing file in Module 2...'),
                  initialHeight: 80,
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: feedbackProvider.isCollaborationSubmitting
                      ? null
                      : _submitCollaboration,
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

  Widget _buildFileChip(ThemeData theme, PlatformFile file, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            file.name.length > 20
                ? '${file.name.substring(0, 17)}...'
                : file.name,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Clickable(
            onPressed: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required ThemeData theme,
    required String label,
    String? description,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
          ).semiBold(),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12),
            ).muted(),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        // Check file count limit
        if (_files.length + result.files.length > 10) {
          _showValidationError('You can only upload up to 10 files');
          return;
        }

        // Check file size (5MB limit)
        for (var file in result.files) {
          if ((file.size) > 5 * 1024 * 1024) {
            _showValidationError(
                'File "${file.name}" exceeds the 5MB size limit');
            return;
          }
        }

        setState(() {
          _files.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        _showValidationError('Could not access files');
      }
    }
  }

  void _submitCollaboration() async {
    // Validation
    if (_selectedSubmissionTypes.isEmpty) {
      _showValidationError('Please select what you are submitting');
      return;
    }

    if (_selectedSource == null) {
      _showValidationError('Please select the source of your submission');
      return;
    }

    if (_selectedSemester == null) {
      _showValidationError('Please select the semester');
      return;
    }

    if (_subjectController.text.isEmpty) {
      _showValidationError('Please enter the subject name and code');
      return;
    }

    if (_files.isEmpty && _urlController.text.isEmpty) {
      _showValidationError('Please attach files or provide a URL');
      return;
    }

    if (_descriptionController.text.isEmpty) {
      _showValidationError('Please describe your submission');
      return;
    }

    if (_wantsCredit == null) {
      _showValidationError('Please indicate if you want to be credited');
      return;
    }

    if (_wantsCredit == true && _creditNameController.text.isEmpty) {
      _showValidationError('Please provide your name for credit');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Contribution?'),
        content: const Text(
            'Are you sure you want to submit this contribution? Our team will review it before adding to Vaultscapes.'),
        actions: [
          OutlineButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final collaboration = CollaborationModel(
      submissionTypes: _selectedSubmissionTypes.toList(),
      source: _selectedSource!,
      semesterSelection: _selectedSemester!,
      subjectDetails: _subjectController.text,
      filePaths: _files.map((f) => f.path ?? f.name).toList(),
      urlSubmission: _urlController.text.isNotEmpty ? _urlController.text : null,
      description: _descriptionController.text,
      wantsCredit: _wantsCredit ?? false,
      creditName: _wantsCredit == true ? _creditNameController.text : null,
      adminNotes: _adminNotesController.text.isNotEmpty
          ? _adminNotesController.text
          : null,
    );

    final provider = context.read<FeedbackProvider>();
    await provider.submitCollaboration(collaboration);

    if (mounted) {
      showToast(
        context: context,
        builder: (context, overlay) {
          return SurfaceCard(
            child: Basic(
              title: const Text('Thank you for your contribution!'),
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

  void _showValidationError(String message) {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            title: Text(message),
            leading:
                Icon(Icons.warning, color: Theme.of(context).colorScheme.destructive),
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

  void _resetForm() {
    _subjectController.clear();
    _urlController.clear();
    _descriptionController.clear();
    _creditNameController.clear();
    _adminNotesController.clear();
    setState(() {
      _selectedSubmissionTypes = {};
      _selectedSource = null;
      _selectedSemester = null;
      _wantsCredit = null;
      _files = [];
    });
  }

  String _getSubmissionTypeLabel(SubmissionType type) {
    switch (type) {
      case SubmissionType.notes:
        return 'Notes';
      case SubmissionType.assignment:
        return 'Assignment';
      case SubmissionType.labManual:
        return 'Lab Manual (Expt)';
      case SubmissionType.questionBank:
        return 'Question Bank';
      case SubmissionType.examPapers:
        return 'Exam Papers (PYQ)';
      case SubmissionType.codeExamples:
        return 'Code Examples';
      case SubmissionType.externalLinks:
        return 'External Link / Sources';
    }
  }

  String _getSourceLabel(SourceType source) {
    switch (source) {
      case SourceType.selfWritten:
        return 'Self Written';
      case SourceType.internetResource:
        return 'Internet Document/Resource';
      case SourceType.facultyProvided:
        return 'Faculty Provided Material';
      case SourceType.aiAssisted:
        return 'AI-Assisted Human-guided Content';
    }
  }
}
