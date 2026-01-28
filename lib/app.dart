import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/navigation_provider.dart';
import 'presentation/providers/feedback_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/widgets/common/connectivity_banner.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/navigation_repository.dart';
import 'data/repositories/feedback_repository.dart';
import 'data/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';

/// Main application widget
class VaultscapesApp extends StatelessWidget {
  final LocalStorageService storageService;
  final AuthRepository authRepository;
  final NavigationRepository navigationRepository;
  final FeedbackRepository feedbackRepository;

  const VaultscapesApp({
    super.key,
    required this.storageService,
    required this.authRepository,
    required this.navigationRepository,
    required this.feedbackRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme Provider
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),

        // Onboarding Provider
        ChangeNotifierProvider<OnboardingProvider>(
          create: (_) => OnboardingProvider(),
        ),

        // Auth Provider
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),

        // Navigation Provider
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) =>
              NavigationProvider(navigationRepository: navigationRepository),
        ),

        // Feedback Provider
        ChangeNotifierProvider<FeedbackProvider>(
          create: (_) =>
              FeedbackProvider(feedbackRepository: feedbackRepository),
        ),

        // Connectivity Provider (for global connectivity banner)
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Determine if dark mode is active
          final isDarkMode =
              themeProvider.themeMode == ThemeMode.dark ||
              (themeProvider.themeMode == ThemeMode.system &&
                  WidgetsBinding
                          .instance
                          .platformDispatcher
                          .platformBrightness ==
                      Brightness.dark);

          return ShadcnApp.router(
            title: 'Vaultscapes',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              // Get the top padding for status bar
              final topPadding = MediaQuery.of(context).padding.top;
              final bottomPadding = MediaQuery.of(context).padding.bottom;

              // Get theme background color to fill behind transparent status bar
              final theme = Theme.of(context);
              final backgroundColor = theme.colorScheme.background;

              // Use _StatusBarManager to handle status bar styling
              return _StatusBarManager(
                isDarkMode: isDarkMode,
                child: Container(
                  color: backgroundColor,
                  child: Column(
                    children: [
                      // Status bar safe area - colored to match app background
                      // This prevents Android's dark scrim from showing through
                      Container(
                        width: double.infinity,
                        height: topPadding,
                        color: backgroundColor,
                      ),
                      // Global connectivity banner - below status bar
                      const ConnectivityBanner(),
                      // Main app content
                      Expanded(child: child ?? const SizedBox.shrink()),
                      // Bottom navigation bar safe area (edge-to-edge)
                      if (bottomPadding > 0)
                        Container(
                          width: double.infinity,
                          height: bottomPadding,
                          color: backgroundColor,
                        ),
                    ],
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

/// Stateful widget to manage status bar styling reliably
class _StatusBarManager extends StatefulWidget {
  final bool isDarkMode;
  final Widget child;

  const _StatusBarManager({required this.isDarkMode, required this.child});

  @override
  State<_StatusBarManager> createState() => _StatusBarManagerState();
}

class _StatusBarManagerState extends State<_StatusBarManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set status bar style after first frame to ensure it applies correctly
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateStatusBar();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Platform brightness changed (system theme switch)
    _updateStatusBar();
  }

  @override
  void didUpdateWidget(_StatusBarManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      // Theme mode changed, update status bar
      _updateStatusBar();
    }
  }

  void _updateStatusBar() {
    // Dark mode = light icons (white) on dark background
    // Light mode = dark icons (black) on light background
    final style = SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000), // Transparent
      statusBarIconBrightness: widget.isDarkMode
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: widget.isDarkMode
          ? Brightness.dark
          : Brightness.light, // iOS
      systemNavigationBarColor: const Color(0x00000000), // Transparent
      systemNavigationBarIconBrightness: widget.isDarkMode
          ? Brightness.light
          : Brightness.dark,
    );

    SystemChrome.setSystemUIOverlayStyle(style);
  }

  @override
  Widget build(BuildContext context) {
    // Also use AnnotatedRegion as a backup/complement to SystemChrome
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000), // Transparent
        statusBarIconBrightness: widget.isDarkMode
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: widget.isDarkMode
            ? Brightness.dark
            : Brightness.light, // iOS
        systemNavigationBarColor: const Color(0x00000000), // Transparent
        systemNavigationBarIconBrightness: widget.isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
      child: widget.child,
    );
  }
}
