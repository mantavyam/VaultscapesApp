/// URL constants for external resources and GitBook content
class UrlConstants {
  UrlConstants._();

  // GitBook Base URLs
  static const String gitBookBase = 'https://mantavyam.gitbook.io/vaultscapes';

  // Breakthrough (formerly AlphaSignal.ai)
  static const String breakthroughUrl = 'https://alphasignal.ai/last-email';

  // Quick Links
  static const String openSearchUrl = '$gitBookBase/open-search';
  static const String globalSyllabusUrl = '$gitBookBase/global-syllabus';
  static const String courseRoadmapUrl = '$gitBookBase/course-roadmap';
  static const String semesterTimelineUrl = '$gitBookBase/semester-timeline';
  static const String contributorsUrl = '$gitBookBase/contributors';
  static const String creditsUrl = '$gitBookBase/credits';
  static const String resourcesRepositoryUrl = '$gitBookBase/resources';
  static const String branchInfoUrl = '$gitBookBase/branch-info';
  static const String examStrategiesUrl = '$gitBookBase/exam-strategies';

  // Support & Legal
  static const String contactForm = '$gitBookBase/contact';
  static const String privacyPolicy = '$gitBookBase/privacy-policy';
  static const String termsOfService = '$gitBookBase/terms-of-service';

  // Social Links
  static const String githubUrl = 'https://github.com/mantavyam/vaultscapes';
  static const String telegramUrl = 'https://t.me/vaultscapes';

  // Semester URLs
  static String semesterUrl(int semester) => '$gitBookBase/semester-$semester';

  // Subject URLs
  static String subjectUrl(int semester, String subjectCode) =>
      '$gitBookBase/semester-$semester/$subjectCode';

  // Module URLs
  static String moduleUrl(int semester, String subjectCode, int moduleNumber) =>
      '$gitBookBase/semester-$semester/$subjectCode/module-$moduleNumber';
}
