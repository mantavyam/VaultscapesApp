import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../../data/models/feedback_model.dart';

/// Feedback form tab - Based on PRD requirements
class FeedbackFormTab extends StatefulWidget {
  const FeedbackFormTab({super.key});

  @override
  State<FeedbackFormTab> createState() => _FeedbackFormTabState();
}

class _FeedbackFormTabState extends State<FeedbackFormTab> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();

  UserRole? _selectedRole;
  Set<UsageFrequency> _selectedFrequencies = {};
  int? _selectedSemester;
  FeedbackType? _selectedFeedbackType;
  int _usabilityRating = 0;
  List<PlatformFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        _nameController.text = authProvider.user?.displayName ?? '';
        _emailController.text = authProvider.user?.email ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
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
                'Feedback Form | Vaultscapes',
              ).h3(),
              const SizedBox(height: 8),
              const Text(
                'Vaultscapes is an Open-Source Academic Resource Database.',
              ).muted(),
              const SizedBox(height: 24),

              // Name Input
              _buildFormSection(
                theme: theme,
                label: "Hi, I'm_____________",
                description: 'Enter Your Name:',
                child: TextField(
                  controller: _nameController,
                  placeholder: const Text('Your name'),
                ),
              ),

              // Email Input
              _buildFormSection(
                theme: theme,
                label: 'Email ID',
                description:
                    'Email will only be used to respond to your feedback! We respect your privacy.',
                child: TextField(
                  controller: _emailController,
                  placeholder: const Text('your.email@example.com'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),

              // Role Selection (Radio Group)
              _buildFormSection(
                theme: theme,
                label: 'Select Your Role',
                description: '(Respondents can select up to 1)',
                child: RadioGroup<UserRole>(
                  value: _selectedRole,
                  onChanged: (value) => setState(() => _selectedRole = value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: UserRole.values.map((role) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RadioItem<UserRole>(
                          value: role,
                          trailing: Text(_getRoleLabel(role)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Usage Frequency (Checkbox Group)
              _buildFormSection(
                theme: theme,
                label: 'How often do you use Vaultscapes?',
                description: '(Respondents can select as many as they like)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: UsageFrequency.values.map((freq) {
                    final isSelected = _selectedFrequencies.contains(freq);
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
                                  _selectedFrequencies.add(freq);
                                } else {
                                  _selectedFrequencies.remove(freq);
                                }
                              });
                            },
                            trailing: Text(_getFrequencyLabel(freq)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Semester Selection (Select dropdown)
              _buildFormSection(
                theme: theme,
                label: 'Which semester are you providing feedback about?',
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

              // Feedback Type (Radio Group)
              _buildFormSection(
                theme: theme,
                label: 'What type of feedback are you providing?',
                description: '(Respondents can select up to 1)',
                child: RadioGroup<FeedbackType>(
                  value: _selectedFeedbackType,
                  onChanged: (value) =>
                      setState(() => _selectedFeedbackType = value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: FeedbackType.values.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RadioItem<FeedbackType>(
                          value: type,
                          trailing: Expanded(
                            child: Text(
                              _getFeedbackTypeLabel(type),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Description
              _buildFormSection(
                theme: theme,
                label: 'Please describe your feedback in detail',
                description:
                    'Provide as much detail as possible about the issue, suggestion, or comment.',
                child: TextArea(
                  controller: _descriptionController,
                  placeholder:
                      const Text('Enter detailed description of your feedback'),
                  initialHeight: 120,
                ),
              ),

              // Page URL
              _buildFormSection(
                theme: theme,
                label: 'Enter the Link to the Page:',
                description:
                    "Copy and Paste the URL of Web-Page you're having issues with.",
                child: TextField(
                  controller: _urlController,
                  placeholder: const Text('https://mantavyam.gitbook.io/vaultscapes/...'),
                  keyboardType: TextInputType.url,
                ),
              ),

              // File Attachments
              _buildFormSection(
                theme: theme,
                label: 'Attach Files & media (Optional)',
                description:
                    'Screen Shots/Recordings will help us identify the issue faster.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlineButton(
                      onPressed: _pickFiles,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file),
                          SizedBox(width: 8),
                          Text('Choose Files'),
                        ],
                      ),
                    ),
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachments.map((file) {
                          return _buildFileChip(theme, file, () {
                            setState(() {
                              _attachments.remove(file);
                            });
                          });
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Usability Rating (Star Rating)
              _buildFormSection(
                theme: theme,
                label: 'How would you Rate the overall usability of Vaultscapes?',
                description:
                    '(Optional) 5 being very easy and 1 being very hard',
                child: StarRating(
                  value: _usabilityRating.toDouble(),
                  onChanged: (value) =>
                      setState(() => _usabilityRating = value.round()),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: feedbackProvider.isFeedbackSubmitting
                      ? null
                      : _submitFeedback,
                  child: feedbackProvider.isFeedbackSubmitting
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
                      : const Text('Submit Feedback'),
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
        setState(() {
          _attachments.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) {
            return SurfaceCard(
              child: Basic(
                title: const Text('Could not access files'),
                leading: Icon(Icons.warning,
                    color: Theme.of(context).colorScheme.destructive),
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
  }

  void _submitFeedback() async {
    // Validation
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showValidationError('Please fill in your name and email');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showValidationError('Please enter a valid email address');
      return;
    }

    if (_selectedRole == null) {
      _showValidationError('Please select your role');
      return;
    }

    if (_selectedFeedbackType == null) {
      _showValidationError('Please select the type of feedback');
      return;
    }

    if (_descriptionController.text.isEmpty) {
      _showValidationError('Please describe your feedback');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Feedback?'),
        content: const Text(
            'Are you sure you want to submit this feedback? Our team will review it and respond if needed.'),
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

    final feedback = FeedbackModel(
      name: _nameController.text,
      email: _emailController.text,
      role: _selectedRole!,
      usageFrequency: _selectedFrequencies.toList(),
      semesterSelection: _selectedSemester ?? 1,
      feedbackType: _selectedFeedbackType!,
      description: _descriptionController.text,
      pageUrl: _urlController.text.isNotEmpty ? _urlController.text : null,
      attachmentPaths: _attachments.map((f) => f.path ?? f.name).toList(),
      usabilityRating: _usabilityRating > 0 ? _usabilityRating : null,
    );

    final provider = context.read<FeedbackProvider>();
    await provider.submitFeedback(feedback);

    if (mounted) {
      showToast(
        context: context,
        builder: (context, overlay) {
          return SurfaceCard(
            child: Basic(
              title: const Text('Thank you for your feedback!'),
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _resetForm() {
    _descriptionController.clear();
    _urlController.clear();
    setState(() {
      _selectedRole = null;
      _selectedFrequencies = {};
      _selectedSemester = null;
      _selectedFeedbackType = null;
      _usabilityRating = 0;
      _attachments = [];
    });
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.faculty:
        return 'Faculty';
      case UserRole.alumni:
        return 'Alumni';
      case UserRole.staff:
        return 'Staff';
      case UserRole.other:
        return 'Others';
    }
  }

  String _getFrequencyLabel(UsageFrequency freq) {
    switch (freq) {
      case UsageFrequency.daily:
        return 'Daily';
      case UsageFrequency.weekly:
        return 'Weekly';
      case UsageFrequency.monthly:
        return 'Once in a Month';
      case UsageFrequency.examTimeOnly:
        return 'Exam Time Only';
      case UsageFrequency.amateurNewUser:
        return 'Amateur New User';
    }
  }

  String _getFeedbackTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.grievance:
        return 'Grievance (eg Broken/Incorrect Links or Missing/Incorrect Resource)';
      case FeedbackType.improvementSuggestion:
        return 'Improvement Suggestion (eg Additional Resources or New Feature Ideas)';
      case FeedbackType.generalFeedback:
        return 'General Feedback (eg User feedback or overall satisfaction)';
      case FeedbackType.technicalIssues:
        return 'Technical Issues (eg Navigation Issues or Unresponsiveness)';
    }
  }
}
