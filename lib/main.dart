import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/user_provider.dart';
import 'providers/preferences_provider.dart';
import 'services/storage_service.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service
  await StorageService.init();
  
  runApp(const VaultScapesApp());
}

class VaultScapesApp extends StatelessWidget {
  const VaultScapesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => PreferencesProvider()..initialize(),
        ),
      ],
      child: MaterialApp.router(
        title: 'VaultScapes',
        theme: AppTheme.theme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
