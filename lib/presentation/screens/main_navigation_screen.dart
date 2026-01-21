import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/navigation/custom_bottom_nav_bar.dart';
import 'home/root_homepage_screen.dart';
import 'alphasignal/alphasignal_webview_screen.dart';
import 'feedback_collaborate/feedback_collaborate_screen.dart';
import 'profile/profile_screen.dart';

/// Custom scroll physics with high drag threshold for PageView
/// Prevents accidental page swipes when user is trying to scroll vertically
class HighThresholdPageScrollPhysics extends PageScrollPhysics {
  final double dragStartThreshold;
  
  const HighThresholdPageScrollPhysics({
    super.parent,
    this.dragStartThreshold = 80.0, // Require significant horizontal drag
  });
  
  @override
  HighThresholdPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HighThresholdPageScrollPhysics(
      parent: buildParent(ancestor),
      dragStartThreshold: dragStartThreshold,
    );
  }
  
  @override
  double get dragStartDistanceMotionThreshold => dragStartThreshold;
}

/// Main navigation screen with bottom navigation bar and swipe gesture support
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<int> _navigationHistory = [0]; // Track tab navigation history
  late PageController _pageController;

  // Use PageView to enable swipe gestures between tabs
  final List<Widget> _screens = const [
    RootHomepageScreen(),
    AlphaSignalWebViewScreen(),
    FeedbackCollaborateScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    // Load semesters when main screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().loadSemesters();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        // Add to history if not already the last item
        if (_navigationHistory.isEmpty || _navigationHistory.last != index) {
          _navigationHistory.add(index);
        }
      });
      // Animate the PageView to the selected index
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        // Add to history if not already the last item
        if (_navigationHistory.isEmpty || _navigationHistory.last != index) {
          _navigationHistory.add(index);
        }
      });
    }
  }

  Future<bool> _onWillPop() async {
    // If we have navigation history, go back
    if (_navigationHistory.length > 1) {
      setState(() {
        _navigationHistory.removeLast();
        _currentIndex = _navigationHistory.last;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false; // Don't pop the route
    }
    // If on home tab with no history, allow exit
    if (_currentIndex == 0) {
      return true; // Allow app to exit
    }
    // Otherwise, go to home tab
    setState(() {
      _currentIndex = 0;
      _navigationHistory.clear();
      _navigationHistory.add(0);
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navigationHistory.length <= 1 && _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        footers: [
          CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabChanged,
          ),
        ],
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          // Use custom scroll physics with high threshold to prevent 
          // accidental swipes when scrolling vertically in webview content
          physics: const HighThresholdPageScrollPhysics(
            parent: ClampingScrollPhysics(),
            dragStartThreshold: 100.0, // Require 100px horizontal drag to start page switch
          ),
          children: _screens,
        ),
      ),
    );
  }
}
