import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/navigation/custom_bottom_nav_bar.dart';
import 'home/root_homepage_screen.dart';
import 'alphasignal/alphasignal_webview_screen.dart';
import 'feedback_collaborate/feedback_collaborate_screen.dart';
import 'profile/profile_screen.dart';

/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Use IndexedStack to preserve state of each tab
  final List<Widget> _screens = const [
    RootHomepageScreen(),
    AlphaSignalWebViewScreen(),
    FeedbackCollaborateScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load semesters when main screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().loadSemesters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      footers: [
        CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ],
      child: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}
