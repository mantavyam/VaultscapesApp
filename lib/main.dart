import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/navigation_repository.dart';
import 'data/repositories/feedback_repository.dart';
import 'data/services/local_storage_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize services
  final storageService = LocalStorageService.instance;
  await storageService.init();

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
