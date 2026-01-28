import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/swipe_disable_notifier.dart';
import '../widgets/navigation/custom_bottom_nav_bar.dart';
import 'home/root_homepage_screen.dart';
import 'breakthrough/breakthrough_webview_screen.dart';
import 'synergy/synergy_screen.dart';
import 'profile/profile_screen.dart';

/// Main navigation screen with bottom navigation bar
/// Swipe navigation is disabled on Breakthrough (index 1) only for authenticated users
/// to prevent interference with vertical scrolling in webview content
/// SYNERGY (index 2) swipe is controlled by form state - disabled when inside forms
class MainNavigationScreen extends StatefulWidget {
  final int initialTab;

  const MainNavigationScreen({super.key, this.initialTab = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late List<int> _navigationHistory;
  late PageController _pageController;

  // Notifier to communicate swipe disable state from child screens
  final ValueNotifier<bool> _synergyFormActiveNotifier = ValueNotifier<bool>(
    false,
  );

  // Use PageView to enable swipe gestures between tabs
  final List<Widget> _screens = const [
    RootHomepageScreen(),
    BreakthroughWebViewScreen(),
    SynergyScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _navigationHistory = [widget.initialTab];
    _pageController = PageController(initialPage: widget.initialTab);
    // Load semesters when main screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().loadSemesters();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _synergyFormActiveNotifier.dispose();
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
      // Jump directly to the selected index (no animation through middle screens)
      _pageController.jumpToPage(index);
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
    // Per user request: On any of the 4 main screens, back should exit the app directly
    // No navigation between tabs on back action
    return true; // Allow app to exit
  }

  @override
  Widget build(BuildContext context) {
    return SwipeDisableNotifier(
      notifier: _synergyFormActiveNotifier,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: _synergyFormActiveNotifier,
            builder: (context, synergyFormActive, child) {
              // Disable swipe on:
              // - Breakthrough (index 1) for authenticated users to prevent iframe scroll issues
              // - SYNERGY (index 2) when a form is active (user is inside feedback/collaborate form)
              final shouldDisableSwipe =
                  (_currentIndex == 1 && authProvider.isAuthenticated) ||
                  (_currentIndex == 2 && synergyFormActive);

              return PopScope(
                // Allow pop (exit app) when on main screens
                canPop: true,
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
                    physics: shouldDisableSwipe
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    children: _screens,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
