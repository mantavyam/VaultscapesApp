import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/navigation_provider.dart';
import 'presentation/providers/feedback_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/router/app_router.dart';
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
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),

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
          create: (_) => NavigationProvider(
            navigationRepository: navigationRepository,
          ),
        ),

        // Feedback Provider
        ChangeNotifierProvider<FeedbackProvider>(
          create: (_) => FeedbackProvider(
            feedbackRepository: feedbackRepository,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ShadcnApp.router(
            title: 'Vaultscapes',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
