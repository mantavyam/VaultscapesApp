## FEEDBACK FORM

Path: lib/presentation/screens/feedback_collaborate/feedback_form_tab.dart

```dart
void _submitFeedback() async {
  // === STRONGER UNFOCUS RIGHT AT THE START ===
  FocusManager.instance.primaryFocus?.unfocus();

  setState(() {
    _errors.clear();
  });

  // Validation
    if (_nameController.text.isEmpty) {
      _errors['name'] = 'Please enter your name';
    }

    if (_emailController.text.isEmpty) {
      _errors['email'] = 'Please enter your email';
    } else if (!_isValidEmail(_emailController.text)) {
      _errors['email'] = 'Please enter a valid email address';
    }

    if (_selectedRole == null) {
      _errors['role'] = 'Please select your role';
    }

    if (_selectedSemester == null) {
      _errors['semester'] = 'Please select a semester';
    }

    if (_selectedFeedbackType == null) {
      _errors['feedbackType'] = 'Please select the type of feedback';
    }

    if (_descriptionController.text.isEmpty) {
      _errors['description'] = 'Please describe your feedback';
    }

    if (_errors.isNotEmpty) {
      setState(() {});
      _showValidationError('Please fill in all required fields');
      return;
    }

  if (_errors.isNotEmpty) {
    setState(() {});
    _showValidationError('Please fill in all required fields');
    return;
  }

  // Rate limit check (unchanged)
  final provider = context.read<FeedbackProvider>();
  final canSubmit = await provider.canSubmitFeedback();
  if (!canSubmit) {
    final count = await provider.getTodayFeedbackCount();
    _showValidationError('Daily limit reached: You can submit up to 5 feedbacks per day. You\'ve submitted $count today.');
    return;
  }

  // === STRONGER UNFOCUS + LONGER DELAY BEFORE DIALOG ===
  FocusManager.instance.primaryFocus?.unfocus();
  await Future.delayed(const Duration(milliseconds: 400)); // Increased from 50ms

  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Submit Feedback?'),
      content: const Text(
        'Are you sure you want to submit this feedback? Our team will review it and respond if needed.',
      ),
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

  // === FINAL UNFOCUS + LONGER DELAY BEFORE SUBMISSION ===
  FocusManager.instance.primaryFocus?.unfocus();
  await Future.delayed(const Duration(milliseconds: 400)); // Increased from 100ms

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

  await provider.submitFeedback(feedback);

  if (mounted) {
    _resetForm();
    widget.onSubmissionSuccess?.call();
  }
}
```

## COLLABORATE FORM

Path: lib/presentation/screens/feedback_collaborate/collaborate_form_tab.dart

```dart
void _submitCollaboration() async {
  // === STRONGER UNFOCUS RIGHT AT THE START ===
  FocusManager.instance.primaryFocus?.unfocus();

  setState(() {
    _errors.clear();
  });

  // Validation
  if (_selectedSubmissionTypes.isEmpty) {
    _errors['submissionType'] = 'Please select what you are submitting';
  }

  if (_selectedSource == null) {
    _errors['source'] = 'Please select the source of your submission';
  }

  if (_selectedSemester == null) {
    _errors['semester'] = 'Please select the semester';
  }

  if (_subjectController.text.isEmpty) {
    _errors['subject'] = 'Please enter the subject name and code';
  }

  if (_files.isEmpty && _urlController.text.isEmpty) {
    _showValidationError('Please attach files or provide a URL');
    setState(() {});
    return;
  }

  if (_descriptionController.text.isEmpty) {
    _errors['description'] = 'Please describe your submission';
  }

  if (_wantsCredit == null) {
    _showValidationError('Please indicate if you want to be credited');
    setState(() {});
    return;
  }

  if (_wantsCredit == true && _creditNameController.text.isEmpty) {
    _errors['creditName'] = 'Please provide your name for credit';
  }

  if (_errors.isNotEmpty) {
    setState(() {});
    _showValidationError('Please fill in all required fields');
    return;
  }

  // Rate limit check
  final provider = context.read<FeedbackProvider>();
  final canSubmit = await provider.canSubmitCollaboration();
  
  if (!canSubmit) {
    final count = await provider.getTodayCollaborationCount();
    _showValidationError('Daily limit reached: You can submit up to 5 collaborations per day. You\'ve submitted $count today.');
    return;
  }

  // === STRONGER UNFOCUS + LONGER DELAY BEFORE DIALOG ===
  FocusManager.instance.primaryFocus?.unfocus();
  await Future.delayed(const Duration(milliseconds: 400)); // Increased delay

  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Submit Contribution?'),
      content: const Text(
        'Are you sure you want to submit this contribution? Our team will review it before adding to Vaultscapes.',
      ),
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

  // === FINAL UNFOCUS + LONGER DELAY BEFORE SUBMISSION ===
  FocusManager.instance.primaryFocus?.unfocus();
  await Future.delayed(const Duration(milliseconds: 400)); // Increased delay

  final collaboration = CollaborationModel(
    submissionTypes: _selectedSubmissionTypes.toList(),
    source: _selectedSource!,
    semesterSelection: _selectedSemester!,
    subjectDetails: _subjectController.text,
    filePaths: _files.map((f) => f.path ?? f.name).toList(),
    urlSubmission: _urlController.text.isNotEmpty
        ? _urlController.text
        : null,
    description: _descriptionController.text,
    wantsCredit: _wantsCredit ?? false,
    creditName: _wantsCredit == true ? _creditNameController.text : null,
    adminNotes: _adminNotesController.text.isNotEmpty
        ? _adminNotesController.text
        : null,
  );

  await provider.submitCollaboration(collaboration);

  if (mounted) {
    _resetForm();
    // Navigate to success screen via callback
    widget.onSubmissionSuccess?.call();
  }
}
```