import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'feedback_form_tab.dart';
import 'collaborate_form_tab.dart';

/// Feedback and Collaboration screen with two stacked cards
class FeedbackCollaborateScreen extends StatefulWidget {
  const FeedbackCollaborateScreen({super.key});

  @override
  State<FeedbackCollaborateScreen> createState() =>
      _FeedbackCollaborateScreenState();
}

class _FeedbackCollaborateScreenState extends State<FeedbackCollaborateScreen> {
  String? _selectedSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      headers: _selectedSection != null
          ? [
              AppBar(
                leading: [
                  IconButton.ghost(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _selectedSection = null),
                  ),
                ],
                title: Text(_selectedSection == 'feedback'
                    ? 'Provide Feedback'
                    : 'Collaborate Now'),
              ),
            ]
          : [],
      child: _selectedSection == null
          ? _buildSelectionScreen(theme)
          : _selectedSection == 'feedback'
              ? const FeedbackFormTab()
              : const CollaborateFormTab(),
    );
  }

  Widget _buildSelectionScreen(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Feedback Card
          _buildSelectionCard(
            context: context,
            theme: theme,
            icon: Icons.bolt,
            title: 'Provide\nFeedback',
            subtitle: 'Report/Suggest/Improve',
            badgeText: 'help us serve you better',
            onTap: () => setState(() => _selectedSection = 'feedback'),
            color: theme.colorScheme.primary,
          ),

          const SizedBox(height: 16),

          // Collaborate Card
          _buildSelectionCard(
            context: context,
            theme: theme,
            icon: Icons.handshake_outlined,
            title: 'Collaborate\nNow',
            subtitle: 'Submit/Share/Contribute',
            badgeText: 'join the community',
            onTap: () => setState(() => _selectedSection = 'collaborate'),
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: theme.colorScheme.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top-left icon
            Icon(
              icon,
              size: 24,
              color: theme.colorScheme.foreground,
            ),
            const SizedBox(height: 40),

            // Title section
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.foreground,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),

            // Bottom row with badge and circle button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Bottom-left badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                ),

                // Bottom-right circle button with arrow
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_outward,
                    size: 24,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
