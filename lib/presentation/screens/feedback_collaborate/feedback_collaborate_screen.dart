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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Feedback Card
              Expanded(
                child: _buildSelectionCard(
                  context: context,
                  theme: theme,
                  icon: Icons.bolt,
                  title: 'Provide\nFeedback',
                  subtitle: 'Report/Suggest/Improve',
                  badgeText: 'Help Us Serve you Better',
                  onTap: () => setState(() => _selectedSection = 'feedback'),
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              // Collaborate Card
              Expanded(
                child: _buildSelectionCard(
                  context: context,
                  theme: theme,
                  icon: Icons.handshake_outlined,
                  title: 'Collaborate\nNow',
                  subtitle: 'Submit/Share/Contribute',
                  badgeText: 'Join the Community',
                  onTap: () => setState(() => _selectedSection = 'collaborate'),
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        );
      },
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate proportional sizes based on card dimensions
        final cardHeight = constraints.maxHeight;
        final cardWidth = constraints.maxWidth;
        final minDimension = cardHeight < cardWidth ? cardHeight : cardWidth;
        
        // Proportional sizing (relative to card height)
        final iconSize = (minDimension * 0.10).clamp(20.0, 32.0);
        final titleFontSize = (minDimension * 0.14).clamp(20.0, 36.0);
        final subtitleFontSize = (minDimension * 0.065).clamp(12.0, 18.0);
        final badgeFontSize = (minDimension * 0.055).clamp(10.0, 16.0);
        final buttonSize = (minDimension * 0.22).clamp(40.0, 64.0);
        final padding = (minDimension * 0.10).clamp(16.0, 32.0);
        final buttonIconSize = buttonSize * 0.42;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(padding),
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
                  size: iconSize,
                  color: theme.colorScheme.foreground,
                ),
                
                // Flexible spacer to push content down
                const Spacer(flex: 2),

                // Title section
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.foreground,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: minDimension * 0.025),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                
                // Flexible spacer before bottom row
                const Spacer(flex: 1),

                // Bottom row with badge and circle button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Bottom-left badge
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.5,
                          vertical: padding * 0.3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    
                    SizedBox(width: padding * 0.5),

                    // Bottom-right circle button with arrow
                    Container(
                      width: buttonSize,
                      height: buttonSize,
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
                        size: buttonIconSize,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
