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
      headers: [
        AppBar(
          leading: _selectedSection != null
              ? [
                  IconButton.ghost(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _selectedSection = null),
                  ),
                ]
              : [],
          title: Text(_selectedSection == 'feedback'
              ? 'Provide Feedback'
              : _selectedSection == 'collaborate'
                  ? 'Collaborate Now'
                  : 'Feedback & Collaborate'),
        ),
      ],
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
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How can we help you?',
                ).h3(),
                const SizedBox(height: 8),
                const Text(
                  'Choose an option to get started',
                ).muted(),
              ],
            ),
          ),

          // Feedback Card
          _buildSelectionCard(
            theme: theme,
            icon: Icons.message_outlined,
            title: 'Provide Feedback',
            description:
                'Report issues, suggest improvements, or share your experience with Vaultscapes.',
            onTap: () => setState(() => _selectedSection = 'feedback'),
            color: theme.colorScheme.primary,
          ),

          const SizedBox(height: 16),

          // Collaborate Card
          _buildSelectionCard(
            theme: theme,
            icon: Icons.handshake_outlined,
            title: 'Collaborate Now',
            description:
                'Submit notes, assignments, question papers, or other academic resources to help fellow students.',
            onTap: () => setState(() => _selectedSection = 'collaborate'),
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      child: Clickable(
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
              ).h4(),
              const SizedBox(height: 8),
              Text(
                description,
              ).muted(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Get Started',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
