import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../../data/models/feedback_model.dart';

/// Feedback form tab
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

  UserRole _selectedRole = UserRole.student;
  List<UsageFrequency> _selectedFrequencies = [];
  int _selectedSemester = 1;
  FeedbackType _selectedFeedbackType = FeedbackType.suggestion;
  int _usabilityRating = 4;
  List<String> _attachments = [];

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
              // Header
              const Text(
                'We value your feedback!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us improve Vaultscapes by sharing your thoughts.',
                style: TextStyle(color: theme.colorScheme.mutedForeground),
              ),
              const SizedBox(height: 24),

              // Name Input
              const Text('Hi, I\'m'),
              const SizedBox(height: 8),
              TextField(controller: _nameController),
              const SizedBox(height: 16),

              // Email Input
              const Text('Email Address'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Role Selection
              const Text('I am a'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UserRole.values.map((role) {
                  final isSelected = _selectedRole == role;
                  return Chip(
                    style: isSelected ? ButtonVariance.primary : ButtonVariance.outline,
                    onPressed: () => setState(() => _selectedRole = role),
                    child: Text(_getRoleLabel(role)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Usage Frequency
              const Text('How often do you use Vaultscapes?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UsageFrequency.values.map((freq) {
                  final isSelected = _selectedFrequencies.contains(freq);
                  return Chip(
                    style: isSelected ? ButtonVariance.primary : ButtonVariance.outline,
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFrequencies.remove(freq);
                        } else {
                          _selectedFrequencies.add(freq);
                        }
                      });
                    },
                    child: Text(_getFrequencyLabel(freq)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Semester Selection
              const Text('Which semester are you in?'),
              const SizedBox(height: 8),
              _buildSemesterSelector(),
              const SizedBox(height: 16),

              // Feedback Type
              const Text('Type of Feedback'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FeedbackType.values.map((type) {
                  final isSelected = _selectedFeedbackType == type;
                  return Chip(
                    style: isSelected ? ButtonVariance.primary : ButtonVariance.outline,
                    onPressed: () => setState(() => _selectedFeedbackType = type),
                    child: Text(_getFeedbackTypeLabel(type)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Detailed Description'),
              const SizedBox(height: 8),
              TextArea(
                controller: _descriptionController,
                initialHeight: 120,
              ),
              const SizedBox(height: 16),

              // Page URL
              const Text('Page URL (Optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // File Attachments
              const Text('Attachments (Optional)'),
              const SizedBox(height: 8),
              OutlineButton(
                onPressed: _pickFiles,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file),
                    SizedBox(width: 8),
                    Text('Add Screenshots'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Usability Rating
              const Text('How would you rate Vaultscapes?'),
              const SizedBox(height: 8),
              StarRating(
                value: _usabilityRating.toDouble(),
                onChanged: (value) => setState(() => _usabilityRating = value.round()),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: feedbackProvider.isFeedbackSubmitting ? null : _submitFeedback,
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

  void _submitFeedback() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      showToast(
        context: context,
        builder: (context, overlay) {
          return SurfaceCard(
            child: Basic(
              title: const Text('Please fill in required fields'),
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

    final feedback = FeedbackModel(
      name: _nameController.text,
      email: _emailController.text,
      role: _selectedRole,
      usageFrequency: _selectedFrequencies,
      semesterSelection: _selectedSemester,
      feedbackType: _selectedFeedbackType,
      description: _descriptionController.text,
      pageUrl: _urlController.text.isNotEmpty ? _urlController.text : null,
      attachmentPaths: _attachments,
      usabilityRating: _usabilityRating,
    );

    final provider = context.read<FeedbackProvider>();
    await provider.submitFeedback(feedback);

    if (mounted) {
      showToast(
        context: context,
        builder: (context, overlay) {
          return SurfaceCard(
            child: Basic(
              title: const Text('Feedback submitted!'),
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
    _descriptionController.clear();
    _urlController.clear();
    setState(() {
      _selectedFrequencies = [];
      _selectedFeedbackType = FeedbackType.suggestion;
      _usabilityRating = 4;
      _attachments = [];
    });
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.student: return 'Student';
      case UserRole.faculty: return 'Faculty';
      case UserRole.alumni: return 'Alumni';
      case UserRole.staff: return 'Staff';
      case UserRole.other: return 'Other';
    }
  }

  String _getFrequencyLabel(UsageFrequency freq) {
    switch (freq) {
      case UsageFrequency.daily: return 'Daily';
      case UsageFrequency.weekly: return 'Weekly';
      case UsageFrequency.monthly: return 'Monthly';
      case UsageFrequency.examTimeOnly: return 'Exam Time Only';
      case UsageFrequency.rarely: return 'Rarely';
    }
  }

  String _getFeedbackTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.suggestion: return 'Suggestion';
      case FeedbackType.grievance: return 'Grievance';
      case FeedbackType.appreciation: return 'Appreciation';
      case FeedbackType.bugReport: return 'Bug Report';
      case FeedbackType.other: return 'Other';
    }
  }
}
