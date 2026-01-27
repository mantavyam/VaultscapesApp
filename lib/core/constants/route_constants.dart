/// Route path constants for navigation
class RouteConstants {
  RouteConstants._();

  // Root routes
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String main = '/main';
  static const String profileSetup = '/profile-setup';

  // Home routes
  static const String home = '/main/home';
  static const String semester = '/main/home/semester/:semesterId';
  static const String subject =
      '/main/home/semester/:semesterId/subject/:subjectId';

  // Tab routes
  static const String alphaSignal = '/main/alphasignal';
  static const String feedbackCollaborate = '/main/feedback';
  static const String profile = '/main/profile';

  // Route names
  static const String splashName = 'splash';
  static const String welcomeName = 'welcome';
  static const String mainName = 'main';
  static const String profileSetupName = 'profileSetup';
  static const String homeName = 'home';
  static const String semesterName = 'semester';
  static const String subjectName = 'subject';
  static const String alphaSignalName = 'alphasignal';
  static const String feedbackCollaborateName = 'feedbackCollaborate';
  static const String profileName = 'profile';

  // Helper methods
  static String semesterPath(String semesterId) =>
      '/main/home/semester/$semesterId';

  static String subjectPath(String semesterId, String subjectId) =>
      '/main/home/semester/$semesterId/subject/$subjectId';
}
