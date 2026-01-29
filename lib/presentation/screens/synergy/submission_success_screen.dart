import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/feedback_provider.dart';
import '../../../core/responsive/responsive.dart';
import 'synergy_screen.dart';

/// Type of submission for the success screen
enum SubmissionSuccessType { feedback, collaboration }

/// Dedicated success screen shown after form submission
class SubmissionSuccessScreen extends StatefulWidget {
  final SubmissionSuccessType type;
  final VoidCallback onDone;

  const SubmissionSuccessScreen({
    super.key,
    required this.type,
    required this.onDone,
  });

  @override
  State<SubmissionSuccessScreen> createState() =>
      _SubmissionSuccessScreenState();
}

class _SubmissionSuccessScreenState extends State<SubmissionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int _submissionCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
    _loadSubmissionCount();
  }

  Future<void> _loadSubmissionCount() async {
    final provider = context.read<FeedbackProvider>();
    final count = widget.type == SubmissionSuccessType.feedback
        ? await provider.getTodayFeedbackCount()
        : await provider.getTodayCollaborationCount();

    if (mounted) {
      setState(() {
        _submissionCount = count;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFeedback = widget.type == SubmissionSuccessType.feedback;

    // Using same blue color for both as per requirement
    const accentColor = Color(0xFF0EA5E9);

    return ResponsiveBuilder(
      builder: (context, windowSize) {
        // Responsive sizing
        final padding = FormSpacing.responsive(FormSpacing.xl, windowSize);
        final outerCircleSize = windowSize.isMicro ? 96.0 : 120.0;
        final innerCircleSize = windowSize.isMicro ? 64.0 : 80.0;
        final checkIconSize = windowSize.isMicro ? 36.0 : 44.0;
        
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              widget.onDone();
            }
          },
          child: Scaffold(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                                // Success Icon with animation
                                Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Container(
                                    width: outerCircleSize,
                                    height: outerCircleSize,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: innerCircleSize,
                                        height: innerCircleSize,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              accentColor,
                                              accentColor.withValues(alpha: 0.8),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: accentColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: checkIconSize,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: FormSpacing.responsive(FormSpacing.xxl, windowSize)),

                            // Title
                            Text(
                              isFeedback
                                  ? 'Feedback Submitted!'
                                  : 'Contribution Submitted!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.foreground,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: FormSpacing.md),

                            // Subtitle
                            Text(
                              isFeedback
                                  ? 'Thank you for helping us improve Vaultscapes. We\'ll review your feedback and respond within 48 hours if needed.'
                                  : 'Thank you for contributing to the community! Our team will review your submission and add it to Vaultscapes soon.',
                              style: TextStyle(
                                fontSize: 15,
                                color: theme.colorScheme.mutedForeground,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: FormSpacing.xxl),

                            // Submission Count Badge
                            if (!_isLoading)
                              Container(
                                padding: const EdgeInsets.all(FormSpacing.lg),
                                decoration: BoxDecoration(
                                  color: _submissionCount >= 5
                                      ? const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.1)
                                      : accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    FormDimensions.cardRadius,
                                  ),
                                  border: Border.all(
                                    color: _submissionCount >= 5
                                        ? const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.3)
                                        : accentColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            (_submissionCount >= 5
                                                    ? const Color(0xFFF59E0B)
                                                    : accentColor)
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          FormDimensions.borderRadius,
                                        ),
                                      ),
                                      child: Icon(
                                        _submissionCount >= 5
                                            ? Icons.warning_amber_rounded
                                            : Icons.check_circle_outline,
                                        size: 20,
                                        color: _submissionCount >= 5
                                            ? const Color(0xFFF59E0B)
                                            : accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: FormSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$_submissionCount / 5 submissions today',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  theme.colorScheme.foreground,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _submissionCount >= 5
                                                ? 'Daily limit reached. Try again tomorrow!'
                                                : 'You can submit up to 5 times per day',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme
                                                  .mutedForeground,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(
                              height: _isLoading
                                  ? FormSpacing.xxl
                                  : FormSpacing.lg,
                            ),

                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(FormSpacing.lg),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.muted.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(
                                  FormDimensions.cardRadius,
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.border.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        FormDimensions.borderRadius,
                                      ),
                                    ),
                                    child: Icon(
                                      isFeedback
                                          ? Icons.email_outlined
                                          : Icons.folder_outlined,
                                      size: 22,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: FormSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFeedback
                                              ? 'What happens next?'
                                              : 'Review Process',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.foreground,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isFeedback
                                              ? 'Our team reviews all feedback to make Vaultscapes better for everyone.'
                                              : 'We verify all submissions for quality and accuracy before publishing.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .colorScheme
                                                .mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: FormSpacing.xxl),

                            // Done Button
                            SizedBox(
                              width: double.infinity,
                              height: FormDimensions.buttonHeight,
                              child: PrimaryButton(
                                onPressed: widget.onDone,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Back to SYNERGY',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: FormSpacing.sm),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: FormSpacing.md),

                            // Secondary action
                            TextButton(
                              onPressed: widget.onDone,
                              child: Text(
                                isFeedback
                                    ? 'Submit Another Feedback'
                                    : 'Submit Another Contribution',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
