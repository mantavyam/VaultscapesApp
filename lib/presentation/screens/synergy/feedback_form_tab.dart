import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../../data/models/feedback_model.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/responsive/responsive.dart';
import 'synergy_screen.dart';
import 'submission_loading_overlay.dart';

/// Feedback form tab - Revamped UI following design guidelines
class FeedbackFormTab extends StatefulWidget {
  final VoidCallback? onSubmissionSuccess;

  const FeedbackFormTab({super.key, this.onSubmissionSuccess});

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

  // Validation state
  final Map<String, String?> _errors = {};

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

    return ResponsiveBuilder(
      builder: (context, windowSize) {
        // Responsive form constraints
        final maxFormWidth = FormDimensions.getMaxFormWidth(windowSize);
        final formPadding = FormSpacing.responsive(FormSpacing.lg, windowSize);
        
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
                        constraints: BoxConstraints(
                          maxWidth: maxFormWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(formPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ═══════════════════════════════════════════
                              // FORM HEADER
                              // ═══════════════════════════════════════════
                              _buildFormHeader(theme),
                              const SizedBox(height: FormSpacing.xxxl),

                              // ═══════════════════════════════════════════
                              // SECTION 1: IDENTITY
                              // ═══════════════════════════════════════════
                              _buildSectionHeader(
                                theme: theme,
                            icon: Icons.person_outline_rounded,
                            title: 'Your Identity',
                            subtitle: 'Tell us who you are',
                          ),
                          const SizedBox(height: FormSpacing.lg),

                          // Name Input
                          _buildTextField(
                            theme: theme,
                            controller: _nameController,
                            label: "Hi, I'm",
                            placeholder: 'Enter your name',
                            helperText: null,
                            isRequired: true,
                            errorText: _errors['name'],
                            onChanged: (_) => _clearError('name'),
                          ),
                          const SizedBox(height: FormSpacing.md),

                          // Email Input
                          _buildTextField(
                            theme: theme,
                            controller: _emailController,
                            label: 'Email Address',
                            placeholder: 'your.email@example.com',
                            helperText:
                                'We\'ll only use this to respond to your feedback',
                            isRequired: true,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _errors['email'],
                            onChanged: (_) => _clearError('email'),
                          ),
                          const SizedBox(height: FormSpacing.md),

                          // Role Selection
                          _buildRadioGroupSection(
                            theme: theme,
                            label: 'Select Your Role',
                            isRequired: true,
                            errorText: _errors['role'],
                            child: _buildRoleRadioGroup(theme),
                          ),
                          const SizedBox(height: FormSpacing.xl),

                          // ═══════════════════════════════════════════
                          // SECTION 2: CONTEXT
                          // ═══════════════════════════════════════════
                          _buildSectionHeader(
                            theme: theme,
                            icon: Icons.insights_rounded,
                            title: 'Usage Context',
                            subtitle: 'Help us understand your usage',
                          ),
                          const SizedBox(height: FormSpacing.lg),

                          // Usage Frequency
                          _buildCheckboxGroupSection(
                            theme: theme,
                            label: 'How often do you use Vaultscapes?',
                            helperText: 'Select all that apply',
                            child: _buildFrequencyCheckboxGroup(theme),
                          ),
                          const SizedBox(height: FormSpacing.md),

                          // Semester Selection
                          _buildSelectSection(
                            theme: theme,
                            label:
                                'Which semester are you providing feedback about?',
                            isRequired: true,
                            errorText: _errors['semester'],
                            child: _buildSemesterSelect(theme),
                          ),
                          const SizedBox(height: FormSpacing.xl),

                          // ═══════════════════════════════════════════
                          // SECTION 3: FEEDBACK DETAILS
                          // ═══════════════════════════════════════════
                          _buildSectionHeader(
                            theme: theme,
                            icon: Icons.feedback_outlined,
                            title: 'Feedback Details',
                            subtitle: 'Share your thoughts with us',
                          ),
                          const SizedBox(height: FormSpacing.lg),

                          // Feedback Type
                          _buildRadioGroupSection(
                            theme: theme,
                            label: 'What type of feedback are you providing?',
                            isRequired: true,
                            errorText: _errors['feedbackType'],
                            child: _buildFeedbackTypeRadioGroup(theme),
                          ),
                          const SizedBox(height: FormSpacing.md),

                          // Description
                          _buildTextAreaSection(
                            theme: theme,
                            controller: _descriptionController,
                            label: 'Describe your feedback in detail',
                            placeholder:
                                'Provide as much detail as possible about the issue, suggestion, or comment...',
                            helperText: 'Max 1000 characters',
                            maxLength: 1000,
                            isRequired: true,
                            errorText: _errors['description'],
                            onChanged: (_) => _clearError('description'),
                          ),
                          const SizedBox(height: FormSpacing.md),

                          // Page URL
                          _buildTextField(
                            theme: theme,
                            controller: _urlController,
                            label: 'Page URL',
                            placeholder:
                                'https://mantavyam.gitbook.io/vaultscapes/...',
                            helperText:
                                'Paste the URL of the page you\'re referring to (optional)',
                            isRequired: false,
                            keyboardType: TextInputType.url,
                            prefixIcon: Icons.link_rounded,
                          ),
                          const SizedBox(height: FormSpacing.md),

                          // File Attachments
                          _buildFilePickerSection(
                            theme: theme,
                            label: 'Attach Files & Media',
                            helperText:
                                'Screenshots or recordings will help us identify issues faster',
                            isRequired: false,
                          ),
                          const SizedBox(height: FormSpacing.xl),

                          // ═══════════════════════════════════════════
                          // SECTION 4: RATING (OPTIONAL)
                          // ═══════════════════════════════════════════
                          _buildSectionHeader(
                            theme: theme,
                            icon: Icons.star_outline_rounded,
                            title: 'Rate Your Experience',
                            subtitle: 'Optional but appreciated',
                          ),
                          const SizedBox(height: FormSpacing.lg),

                          _buildStarRatingSection(theme),
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
                isVisible: feedbackProvider.isFeedbackSubmitting,
                title: 'Submitting your feedback...',
                subtitle:
                    'Please don\'t close the app while we process your submission.',
              ),
            ],
          ),
        );
          },
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
                  Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF0EA5E9)),
                  SizedBox(width: FormSpacing.xs),
                  Text(
                    'FEEDBACK',
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
          'Help Us Improve Vaultscapes',
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
          'Your feedback helps us build a better academic resource database for everyone.',
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
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(FormDimensions.borderRadius),
            ),
            child: Icon(icon, size: 22, color: theme.colorScheme.primary),
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
        // Label
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

        // Input Field
        SizedBox(
          height: FormDimensions.inputHeight,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            placeholder: Text(placeholder),
            onChanged: onChanged,
          ),
        ),

        // Helper or Error Text
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.foreground,
          ),
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
    int maxLength = 1000,
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
          initialHeight: 120,
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
                    Text(
                      hasError ? errorText : (helperText ?? ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasError
                            ? theme.colorScheme.destructive
                            : theme.colorScheme.mutedForeground,
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

  Widget _buildRoleRadioGroup(ThemeData theme) {
    return Wrap(
      spacing: FormSpacing.sm,
      runSpacing: FormSpacing.sm,
      children: UserRole.values.map((role) {
        final isSelected = _selectedRole == role;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRole = role;
              _clearError('role');
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FormSpacing.md,
              vertical: FormSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(FormDimensions.borderRadius),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
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
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.mutedForeground,
                      width: 2,
                    ),
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: FormSpacing.sm),
                Text(
                  _getRoleLabel(role),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
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

  Widget _buildFrequencyCheckboxGroup(ThemeData theme) {
    return Wrap(
      spacing: FormSpacing.sm,
      runSpacing: FormSpacing.sm,
      children: UsageFrequency.values.map((freq) {
        final isSelected = _selectedFrequencies.contains(freq);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedFrequencies.remove(freq);
              } else {
                _selectedFrequencies.add(freq);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FormSpacing.md,
              vertical: FormSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(FormDimensions.borderRadius),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
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
                          ? theme.colorScheme.primary
                          : theme.colorScheme.mutedForeground,
                      width: 2,
                    ),
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: FormSpacing.sm),
                Text(
                  _getFrequencyLabel(freq),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
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

  Widget _buildFeedbackTypeRadioGroup(ThemeData theme) {
    return Column(
      children: FeedbackType.values.map((type) {
        final isSelected = _selectedFeedbackType == type;
        return Padding(
          padding: const EdgeInsets.only(bottom: FormSpacing.sm),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedFeedbackType = type;
                _clearError('feedbackType');
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(FormSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(
                  FormDimensions.borderRadius,
                ),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
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
                            ? theme.colorScheme.primary
                            : theme.colorScheme.mutedForeground,
                        width: 2,
                      ),
                      color: isSelected
                          ? theme.colorScheme.primary
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
                          _getFeedbackTypeTitle(type),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getFeedbackTypeDescription(type),
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

        // File Picker Area
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      FormDimensions.borderRadius,
                    ),
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 24,
                    color: theme.colorScheme.primary,
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
                  'Max 25MB per file',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Attached Files
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: FormSpacing.md),
          Wrap(
            spacing: FormSpacing.sm,
            runSpacing: FormSpacing.sm,
            children: _attachments.map((file) {
              return _buildFileChip(theme, file, () {
                setState(() => _attachments.remove(file));
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

  Widget _buildStarRatingSection(ThemeData theme) {
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
          Text(
            'How would you rate the overall usability of Vaultscapes?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.foreground,
            ),
          ),
          const SizedBox(height: FormSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isSelected = starValue <= _usabilityRating;
              return GestureDetector(
                onTap: () => setState(() => _usabilityRating = starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FormSpacing.xs,
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 40,
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : theme.colorScheme.mutedForeground.withValues(
                            alpha: 0.5,
                          ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: FormSpacing.sm),
          Center(
            child: Text(
              _getRatingLabel(_usabilityRating),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _usabilityRating > 0
                    ? const Color(0xFFF59E0B)
                    : theme.colorScheme.mutedForeground,
              ),
            ),
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
                    'Submit Feedback',
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
        // Check file size (25MB limit)
        for (var file in result.files) {
          if ((file.size) > 25 * 1024 * 1024) {
            _showValidationError(
              'File "${file.name}" exceeds the 25MB size limit',
            );
            return;
          }
        }
        setState(() => _attachments.addAll(result.files));
      }
    } catch (e) {
      if (mounted) {
        _showValidationError('Could not access files');
      }
    }
  }

  void _submitFeedback() async {
    // === STRONGER UNFOCUS RIGHT AT THE START ===
    FocusManager.instance.primaryFocus?.unfocus();

    // Check internet connectivity first
    final connectivityService = ConnectivityService();
    final isConnected = await connectivityService.checkConnectivity();

    if (!isConnected) {
      _showValidationError(
        'No internet connection. Please connect to the internet and try again.',
      );
      return;
    }

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

    // Rate limit check
    if (!mounted) return;
    final provider = context.read<FeedbackProvider>();
    final canSubmit = await provider.canSubmitFeedback();
    if (!canSubmit) {
      final count = await provider.getTodayFeedbackCount();
      _showValidationError(
        "Daily limit reached: You can submit up to 5 feedbacks per day. You've submitted $count today.",
      );
      return;
    }

    // === STRONGER UNFOCUS + LONGER DELAY BEFORE DIALOG ===
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(
      const Duration(milliseconds: 400),
    ); // Increased from 50ms
    
    if (!mounted) return;

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
    if (!mounted) return;

    // === FINAL UNFOCUS + LONGER DELAY BEFORE SUBMISSION ===
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(
      const Duration(milliseconds: 400),
    ); // Increased from 100ms

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
      _errors.clear();
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
        return 'Monthly';
      case UsageFrequency.examTimeOnly:
        return 'Exam Time';
      case UsageFrequency.amateurNewUser:
        return 'New User';
    }
  }

  String _getFeedbackTypeTitle(FeedbackType type) {
    switch (type) {
      case FeedbackType.grievance:
        return 'Grievance';
      case FeedbackType.improvementSuggestion:
        return 'Improvement Suggestion';
      case FeedbackType.generalFeedback:
        return 'General Feedback';
      case FeedbackType.technicalIssues:
        return 'Technical Issues';
    }
  }

  String _getFeedbackTypeDescription(FeedbackType type) {
    switch (type) {
      case FeedbackType.grievance:
        return 'Broken/incorrect links or missing resources';
      case FeedbackType.improvementSuggestion:
        return 'Additional resources or new feature ideas';
      case FeedbackType.generalFeedback:
        return 'User feedback or overall satisfaction';
      case FeedbackType.technicalIssues:
        return 'Navigation issues or unresponsiveness';
    }
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Hard to Use';
      case 2:
        return 'Somewhat Difficult';
      case 3:
        return 'Neutral';
      case 4:
        return 'Easy to Use';
      case 5:
        return 'Very Easy to Use';
      default:
        return 'Tap to rate';
    }
  }
}
