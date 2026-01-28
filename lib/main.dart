import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/navigation_repository.dart';
import 'data/repositories/feedback_repository.dart';
import 'data/services/local_storage_service.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI to show status bar (not full screen)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  // NOTE: Status bar style is now set dynamically in app.dart based on theme
  // to ensure correct icon brightness for both light and dark modes

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize services
  final storageService = LocalStorageService.instance;
  await storageService.init();

  // Initialize connectivity service
  final connectivityService = ConnectivityService();
  // Start monitoring connectivity changes
  connectivityService.connectivityStream.listen((isConnected) {
    debugPrint('Connectivity changed: $isConnected');
  });

  // Initialize repositories
  final authRepository = AuthRepository();
  final navigationRepository = NavigationRepository();
  final feedbackRepository = FeedbackRepository();

  // Run the app
  runApp(
    VaultscapesApp(
      storageService: storageService,
      authRepository: authRepository,
      navigationRepository: navigationRepository,
      feedbackRepository: feedbackRepository,
    ),
  );
}
