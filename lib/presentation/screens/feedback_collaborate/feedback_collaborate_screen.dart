import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'feedback_form_tab.dart';
import 'collaborate_form_tab.dart';

/// Feedback and Collaboration screen with tabs
class FeedbackCollaborateScreen extends StatefulWidget {
  const FeedbackCollaborateScreen({super.key});

  @override
  State<FeedbackCollaborateScreen> createState() => _FeedbackCollaborateScreenState();
}

class _FeedbackCollaborateScreenState extends State<FeedbackCollaborateScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Feedback & Collaborate'),
        ),
      ],
      child: Column(
        children: [
          Tabs(
            index: _currentTab,
            onChanged: (index) => setState(() => _currentTab = index),
            children: const [
              TabItem(child: Text('Provide Feedback')),
              TabItem(child: Text('Collaborate Now')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: const [
                FeedbackFormTab(),
                CollaborateFormTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
