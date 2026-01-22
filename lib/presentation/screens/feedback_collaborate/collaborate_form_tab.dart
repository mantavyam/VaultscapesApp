import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/feedback_provider.dart';
import '../../../data/models/collaboration_model.dart';
import 'feedback_collaborate_screen.dart';
import 'submission_loading_overlay.dart';

/// Collaboration form tab - Revamped UI following design guidelines
class CollaborateFormTab extends StatefulWidget {
  final VoidCallback? onSubmissionSuccess;

  const CollaborateFormTab({super.key, this.onSubmissionSuccess});

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

  // Validation state
  final Map<String, String?> _errors = {};

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
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              // Main Form Content
              SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: FormDimensions.maxFormWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(FormSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ═══════════════════════════════════════════
                        // FORM HEADER
                        // ═══════════════════════════════════════════
                        _buildFormHeader(theme),
                        const SizedBox(height: FormSpacing.xxxl),

                        // ═══════════════════════════════════════════
                        // SECTION 1: SUBMISSION TYPE
                        // ═══════════════════════════════════════════
                        _buildSectionHeader(
                          theme: theme,
                          icon: Icons.category_outlined,
                          title: 'Submission Details',
                          subtitle: 'What are you sharing with us?',
                        ),
                        const SizedBox(height: FormSpacing.lg),

                        // Submission Type
                        _buildCheckboxGroupSection(
                          theme: theme,
                          label: 'What are you submitting?',
                          helperText: 'Select all that apply',
                          isRequired: true,
                          errorText: _errors['submissionType'],
                          child: _buildSubmissionTypeCheckboxGroup(theme),
                        ),
                        const SizedBox(height: FormSpacing.md),

                        // Source Selection
                        _buildRadioGroupSection(
                          theme: theme,
                          label: 'What is the source of your submission?',
                          isRequired: true,
                          errorText: _errors['source'],
                          child: _buildSourceRadioGroup(theme),
                        ),
                        const SizedBox(height: FormSpacing.xl),

                        // ═══════════════════════════════════════════
                        // SECTION 2: TARGET
                        // ═══════════════════════════════════════════
                        _buildSectionHeader(
                          theme: theme,
                          icon: Icons.school_outlined,
                          title: 'Target Information',
                          subtitle: 'Which semester and subject?',
                        ),
                        const SizedBox(height: FormSpacing.lg),

                        // Semester Selection
                        _buildSelectSection(
                          theme: theme,
                          label:
                              'For which semester are you submitting this resource?',
                          isRequired: true,
                          errorText: _errors['semester'],
                          child: _buildSemesterSelect(theme),
                        ),
                        const SizedBox(height: FormSpacing.md),

                        // Subject Name and Code
                        _buildTextField(
                          theme: theme,
                          controller: _subjectController,
                          label: 'Subject Name and Code',
                          placeholder: 'E.g., Computer Science - CS101',
                          helperText:
                              'Enter the subject name followed by its code',
                          isRequired: true,
                          errorText: _errors['subject'],
                          onChanged: (_) => _clearError('subject'),
                        ),
                        const SizedBox(height: FormSpacing.xl),

                        // ═══════════════════════════════════════════
                        // SECTION 3: CONTENT
                        // ═══════════════════════════════════════════
                        _buildSectionHeader(
                          theme: theme,
                          icon: Icons.upload_file_rounded,
                          title: 'Content Upload',
                          subtitle: 'Attach your files or provide links',
                        ),
                        const SizedBox(height: FormSpacing.lg),

                        // File Upload
                        _buildFilePickerSection(
                          theme: theme,
                          label: 'Attach Your Files',
                          helperText:
                              'You can upload up to 10 files (max 25MB each)',
                          isRequired: _urlController.text.isEmpty,
                        ),
                        const SizedBox(height: FormSpacing.md),

                        // URL Submission
                        _buildTextField(
                          theme: theme,
                          controller: _urlController,
                          label: 'URL Submission',
                          placeholder: 'https://...',
                          helperText:
                              'Alternatively, provide a link to your resource',
                          isRequired: false,
                          keyboardType: TextInputType.url,
                          prefixIcon: Icons.link_rounded,
                        ),
                        const SizedBox(height: FormSpacing.md),

                        // Description
                        _buildTextAreaSection(
                          theme: theme,
                          controller: _descriptionController,
                          label: 'Describe your submission',
                          placeholder:
                              'E.g., Complete notes for Module 3 covering Data Structures including arrays, linked lists, and trees...',
                          helperText:
                              'A short explanation of what this resource contains',
                          maxLength: 500,
                          isRequired: true,
                          errorText: _errors['description'],
                          onChanged: (_) => _clearError('description'),
                        ),
                        const SizedBox(height: FormSpacing.xl),

                        // ═══════════════════════════════════════════
                        // SECTION 4: ATTRIBUTION
                        // ═══════════════════════════════════════════
                        _buildSectionHeader(
                          theme: theme,
                          icon: Icons.badge_outlined,
                          title: 'Attribution',
                          subtitle: 'Would you like to be credited?',
                        ),
                        const SizedBox(height: FormSpacing.lg),

                        // Credit Preference
                        _buildCreditToggleSection(theme),
                        const SizedBox(height: FormSpacing.md),

                        // Credit Name (conditional)
                        if (_wantsCredit == true) ...[
                          _buildTextField(
                            theme: theme,
                            controller: _creditNameController,
                            label: 'How should we credit you?',
                            placeholder: 'Your name, email, or social handle',
                            helperText:
                                'This will appear alongside your contribution',
                            isRequired: true,
                            errorText: _errors['creditName'],
                            onChanged: (_) => _clearError('creditName'),
                          ),
                          const SizedBox(height: FormSpacing.md),
                        ],
                        const SizedBox(height: FormSpacing.xl),

                        // ═══════════════════════════════════════════
                        // SECTION 5: ADMIN NOTES
                        // ═══════════════════════════════════════════
                        _buildSectionHeader(
                          theme: theme,
                          icon: Icons.note_alt_outlined,
                          title: 'Additional Notes',
                          subtitle: 'Any extra information for our team',
                        ),
                        const SizedBox(height: FormSpacing.lg),

                        // Admin Notes
                        _buildTextAreaSection(
                          theme: theme,
                          controller: _adminNotesController,
                          label: 'Notes for Admins',
                          placeholder:
                              'E.g., Please update the existing file in Module 2, or replace the outdated version...',
                          helperText:
                              'Optional - any additional context for our review team',
                          maxLength: 500,
                          isRequired: false,
                        ),
                        const SizedBox(height: FormSpacing.xxl),

                        // ═══════════════════════════════════════════
                        // SUBMIT BUTTON
                        // ═══════════════════════════════════════════
                        _buildSubmitButton(feedbackProvider),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Loading Overlay
            SubmissionLoadingOverlay(
              isVisible: feedbackProvider.isCollaborationSubmitting,
              title: 'Submitting your content...',
              subtitle:
                  'Please don\'t close the app while we process your submission.',
            ),
          ],
        ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFormHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FormSpacing.sm,
                vertical: FormSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  FormDimensions.borderRadius,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.handshake_rounded,
                    size: 16,
                    color: Color(0xFF0EA5E9),
                  ),
                  SizedBox(width: FormSpacing.xs),
                  Text(
                    'COLLABORATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0EA5E9),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: FormSpacing.md),
        Text(
          'Contribute to Vaultscapes',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.foreground,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: FormSpacing.sm),
        Text(
          'Share your notes, assignments, or valuable resources with fellow students and make a difference.',
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.mutedForeground,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(FormSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(FormDimensions.cardRadius),
        border: Border.all(
          color: theme.colorScheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(FormDimensions.borderRadius),
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF0EA5E9)),
          ),
          const SizedBox(width: FormSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM FIELD COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    required String placeholder,
    String? helperText,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: FormSpacing.sm),
        SizedBox(
          height: FormDimensions.inputHeight,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            placeholder: Text(placeholder),
            onChanged: onChanged,
          ),
        ),
        if (helperText != null || hasError) ...[
          const SizedBox(height: FormSpacing.sm),
          Row(
            children: [
              if (hasError) ...[
                Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.destructive,
                ),
                const SizedBox(width: FormSpacing.xs),
              ],
              Expanded(
                child: Text(
                  hasError ? errorText : (helperText ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: hasError
                        ? theme.colorScheme.destructive
                        : theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRadioGroupSection({
    required ThemeData theme,
    required String label,
    required Widget child,
    bool isRequired = false,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: FormSpacing.md),
        child,
        if (hasError) ...[
          const SizedBox(height: FormSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: theme.colorScheme.destructive,
              ),
              const SizedBox(width: FormSpacing.xs),
              Text(
                errorText,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCheckboxGroupSection({
    required ThemeData theme,
    required String label,
    required Widget child,
    String? helperText,
    bool isRequired = false,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ],
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
        const SizedBox(height: FormSpacing.md),
        child,
        if (hasError) ...[
          const SizedBox(height: FormSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: theme.colorScheme.destructive,
              ),
              const SizedBox(width: FormSpacing.xs),
              Text(
                errorText,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSelectSection({
    required ThemeData theme,
    required String label,
    required Widget child,
    bool isRequired = false,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: FormSpacing.sm),
        child,
        if (hasError) ...[
          const SizedBox(height: FormSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: theme.colorScheme.destructive,
              ),
              const SizedBox(width: FormSpacing.xs),
              Text(
                errorText,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTextAreaSection({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    required String placeholder,
    String? helperText,
    int maxLength = 500,
    bool isRequired = false,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: FormSpacing.sm),
        TextArea(
          controller: controller,
          placeholder: Text(placeholder),
          initialHeight: 100,
          onChanged: onChanged,
        ),
        const SizedBox(height: FormSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (helperText != null || hasError)
              Expanded(
                child: Row(
                  children: [
                    if (hasError) ...[
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.destructive,
                      ),
                      const SizedBox(width: FormSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        hasError ? errorText : (helperText ?? ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasError
                              ? theme.colorScheme.destructive
                              : theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final length = value.text.length;
                return Text(
                  '$length/$maxLength',
                  style: TextStyle(
                    fontSize: 12,
                    color: length > maxLength * 0.9
                        ? theme.colorScheme.destructive
                        : theme.colorScheme.mutedForeground,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIFIC FORM COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSubmissionTypeCheckboxGroup(ThemeData theme) {
    return Wrap(
      spacing: FormSpacing.sm,
      runSpacing: FormSpacing.sm,
      children: SubmissionType.values.map((type) {
        final isSelected = _selectedSubmissionTypes.contains(type);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedSubmissionTypes.remove(type);
              } else {
                _selectedSubmissionTypes.add(type);
              }
              _clearError('submissionType');
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FormSpacing.md,
              vertical: FormSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0EA5E9).withValues(alpha: 0.1)
                  : theme.colorScheme.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(FormDimensions.borderRadius),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0EA5E9)
                    : theme.colorScheme.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0EA5E9)
                          : theme.colorScheme.mutedForeground,
                      width: 2,
                    ),
                    color: isSelected
                        ? const Color(0xFF0EA5E9)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: FormSpacing.sm),
                Text(
                  _getSubmissionTypeLabel(type),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0EA5E9)
                        : theme.colorScheme.foreground,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSourceRadioGroup(ThemeData theme) {
    return Column(
      children: SourceType.values.map((source) {
        final isSelected = _selectedSource == source;
        return Padding(
          padding: const EdgeInsets.only(bottom: FormSpacing.sm),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedSource = source;
                _clearError('source');
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(FormSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0EA5E9).withValues(alpha: 0.1)
                    : theme.colorScheme.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(
                  FormDimensions.borderRadius,
                ),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0EA5E9)
                      : theme.colorScheme.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0EA5E9)
                            : theme.colorScheme.mutedForeground,
                        width: 2,
                      ),
                      color: isSelected
                          ? const Color(0xFF0EA5E9)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: FormSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSourceLabel(source),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0EA5E9)
                                : theme.colorScheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getSourceDescription(source),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSemesterSelect(ThemeData theme) {
    return SizedBox(
      height: FormDimensions.inputHeight,
      child: Select<int>(
        value: _selectedSemester,
        placeholder: const Text('Select semester'),
        onChanged: (value) {
          setState(() {
            _selectedSemester = value;
            _clearError('semester');
          });
        },
        itemBuilder: (context, value) => Text('Semester $value / BTECH'),
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
    );
  }

  Widget _buildFilePickerSection({
    required ThemeData theme,
    required String label,
    String? helperText,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ],
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
        const SizedBox(height: FormSpacing.md),
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: FormSpacing.lg,
              vertical: FormSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(FormDimensions.cardRadius),
              border: Border.all(
                color: theme.colorScheme.border,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      FormDimensions.borderRadius,
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    size: 24,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(height: FormSpacing.md),
                Text(
                  'Tap to upload files',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                const SizedBox(height: FormSpacing.xs),
                Text(
                  'Max 10 files, 25MB each',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: FormSpacing.md),
          Wrap(
            spacing: FormSpacing.sm,
            runSpacing: FormSpacing.sm,
            children: _files.map((file) {
              return _buildFileChip(theme, file, () {
                setState(() => _files.remove(file));
              });
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFileChip(
    ThemeData theme,
    PlatformFile file,
    VoidCallback onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FormSpacing.sm + 4,
        vertical: FormSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(FormDimensions.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 16,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: FormSpacing.sm),
          Text(
            file.name.length > 20
                ? '${file.name.substring(0, 17)}...'
                : file.name,
            style: TextStyle(fontSize: 13, color: theme.colorScheme.foreground),
          ),
          const SizedBox(width: FormSpacing.sm),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.mutedForeground.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 12,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditToggleSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(FormSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(FormDimensions.cardRadius),
        border: Border.all(
          color: theme.colorScheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap label in a Wrap widget to handle overflow
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Would you like to be credited?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: FormSpacing.md),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _wantsCredit = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FormSpacing.lg,
                      vertical: FormSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: _wantsCredit == true
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : theme.colorScheme.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(
                        FormDimensions.borderRadius,
                      ),
                      border: Border.all(
                        color: _wantsCredit == true
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.border,
                        width: _wantsCredit == true ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: _wantsCredit == true
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.mutedForeground,
                        ),
                        const SizedBox(width: FormSpacing.xs),
                        Flexible(
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _wantsCredit == true
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _wantsCredit == true
                                  ? const Color(0xFF10B981)
                                  : theme.colorScheme.foreground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: FormSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _wantsCredit = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FormSpacing.lg,
                      vertical: FormSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: _wantsCredit == false
                          ? theme.colorScheme.mutedForeground.withValues(
                              alpha: 0.1,
                            )
                          : theme.colorScheme.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(
                        FormDimensions.borderRadius,
                      ),
                      border: Border.all(
                        color: _wantsCredit == false
                            ? theme.colorScheme.mutedForeground
                            : theme.colorScheme.border,
                        width: _wantsCredit == false ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_off_outlined,
                          size: 18,
                          color: _wantsCredit == false
                              ? theme.colorScheme.mutedForeground
                              : theme.colorScheme.mutedForeground.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                        const SizedBox(width: FormSpacing.xs),
                        Flexible(
                          child: Text(
                            'Anonymous',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _wantsCredit == false
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _wantsCredit == false
                                  ? theme.colorScheme.foreground
                                  : theme.colorScheme.foreground.withValues(
                                      alpha: 0.8,
                                    ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(FeedbackProvider feedbackProvider) {
    return SizedBox(
      width: double.infinity,
      height: FormDimensions.buttonHeight,
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
                  SizedBox(width: FormSpacing.md),
                  Text(
                    'Submitting...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: FormSpacing.sm),
                  Text(
                    'Submit Contribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _clearError(String field) {
    if (_errors.containsKey(field)) {
      setState(() => _errors.remove(field));
    }
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

        // Check file size (25MB limit)
        for (var file in result.files) {
          if ((file.size) > 25 * 1024 * 1024) {
            _showValidationError(
              'File "${file.name}" exceeds the 25MB size limit',
            );
            return;
          }
        }

        setState(() => _files.addAll(result.files));
      }
    } catch (e) {
      if (mounted) {
        _showValidationError('Could not access files');
      }
    }
  }

  void _submitCollaboration() async {
    // Unfocus any text field immediately to dismiss keyboard
    FocusScope.of(context).unfocus();
    
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

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
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

    // Unfocus any text field to dismiss keyboard before showing loading overlay
    FocusScope.of(context).unfocus();
    
    // Add a small delay to ensure keyboard is dismissed before proceeding
    await Future.delayed(const Duration(milliseconds: 100));

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

    final provider = context.read<FeedbackProvider>();
    await provider.submitCollaboration(collaboration);

    if (mounted) {
      _resetForm();
      // Navigate to success screen via callback
      widget.onSubmissionSuccess?.call();
    }
  }

  void _showValidationError(String message) {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            title: Text(message),
            leading: Icon(
              Icons.warning_rounded,
              color: Theme.of(context).colorScheme.destructive,
            ),
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
      _errors.clear();
    });
  }

  String _getSubmissionTypeLabel(SubmissionType type) {
    switch (type) {
      case SubmissionType.notes:
        return 'Notes';
      case SubmissionType.assignment:
        return 'Assignment';
      case SubmissionType.labManual:
        return 'Lab Manual';
      case SubmissionType.questionBank:
        return 'Question Bank';
      case SubmissionType.examPapers:
        return 'Exam Papers';
      case SubmissionType.codeExamples:
        return 'Code Examples';
      case SubmissionType.externalLinks:
        return 'External Links';
    }
  }

  String _getSourceLabel(SourceType source) {
    switch (source) {
      case SourceType.selfWritten:
        return 'Self Written';
      case SourceType.internetResource:
        return 'Internet Resource';
      case SourceType.facultyProvided:
        return 'Faculty Provided';
      case SourceType.aiAssisted:
        return 'AI-Assisted';
    }
  }

  String _getSourceDescription(SourceType source) {
    switch (source) {
      case SourceType.selfWritten:
        return 'Content you created yourself';
      case SourceType.internetResource:
        return 'Document or resource from the internet';
      case SourceType.facultyProvided:
        return 'Material provided by faculty';
      case SourceType.aiAssisted:
        return 'AI-assisted, human-guided content';
    }
  }
}
