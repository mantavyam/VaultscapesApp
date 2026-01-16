class AppStrings {
  // App info
  static const String appName = 'VaultScapes';
  static const String appTagline = 'Your Study Companion';
  
  // Onboarding
  static const String getStarted = 'Get Started';
  static const String explore = 'Explore';
  static const String signInToContinue = 'Sign in to continue';
  static const String savePreferencesSubtext = 'Save your preferences and track progress';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithGitHub = 'Continue with GitHub';
  static const String termsDisclaimer = 'By continuing, you agree to our Terms & Privacy Policy';
  
  // Name customization
  static const String customizeYourName = 'Customize your name';
  static const String nameHintText = 'This is how you\'ll appear in the app';
  static const String continueButton = 'Continue';
  static const String skipForNow = 'Skip for now';
  
  // Bottom navigation
  static const String home = 'Home';
  static const String collaborate = 'Collaborate';
  static const String feedback = 'Feedback';
  static const String profile = 'Profile';
  
  // Profile screen
  static const String welcomeGuest = 'Welcome, Guest!';
  static const String signInToSavePrefs = 'Sign in to save your preferences';
  static const String createProfile = 'Create Profile';
  static const String login = 'Login';
  
  // Quick links
  static const String searchDatabase = 'Search Database';
  static const String githubRepository = 'GitHub Repository';
  static const String discordCommunity = 'Discord Community';
  static const String howToUseDatabase = 'How to Use Database';
  static const String howToCollaborate = 'How to Collaborate';
  static const String collaborators = 'Collaborators';
  
  // Settings
  static const String semesterPrefix = 'Semester: ';
  static const String semesterDefault = 'Default';
  static const String semester1 = 'Sem 1';
  static const String semester2 = 'Sem 2';
  static const String semester3 = 'Sem 3';
  static const String semester4 = 'Sem 4';
  static const String semester5 = 'Sem 5';
  static const String semester6 = 'Sem 6';
  static const String semester7 = 'Sem 7';
  static const String semester8 = 'Sem 8';
  
  // Actions
  static const String logout = 'Logout';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';
  static const String ok = 'OK';
  
  // Messages
  static const String logoutConfirmation = 'Are you sure you want to log out?';
  static const String signInFailed = 'Sign-in failed. Please try again.';
  static const String noInternetConnection = 'No internet connection';
  static const String loadingFailed = 'Failed to load content';
  static const String tapToRetry = 'Tap to retry';
  
  // Character limits
  static const int nameMinLength = 2;
  static const int nameMaxLength = 30;
  
  // Semester options
  static List<String> get semesterOptions => [
    semesterDefault,
    semester1,
    semester2,
    semester3,
    semester4,
    semester5,
    semester6,
    semester7,
    semester8,
  ];
}