import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'feedback_collaborate_screen.dart';

/// Full-screen loading overlay shown during form submission
class SubmissionLoadingOverlay extends StatefulWidget {
  final bool isVisible;
  final String title;
  final String subtitle;

  const SubmissionLoadingOverlay({
    super.key,
    required this.isVisible,
    required this.title,
    required this.subtitle,
  });

  @override
  State<SubmissionLoadingOverlay> createState() =>
      _SubmissionLoadingOverlayState();
}

class _SubmissionLoadingOverlayState extends State<SubmissionLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SubmissionLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _fadeAnimation.value == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    const accentColor = Color(0xFF0EA5E9);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: theme.colorScheme.background.withValues(alpha: 0.95),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Padding(
                    padding: const EdgeInsets.all(FormSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with pulse animation
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: FormSpacing.xl),

                        // Title
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.foreground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: FormSpacing.sm),

                        // Subtitle
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: FormSpacing.xl),

                        // Linear progress indicator
                        SizedBox(
                          width: 200,
                          child: LinearProgressIndicator(
                            backgroundColor:
                                theme.colorScheme.muted.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: FormSpacing.md),

                        // Please wait text
                        Text(
                          'Please don\'t close the app',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
