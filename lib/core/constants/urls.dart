class AppUrls {
  static const String baseGitBook = 'https://mantavyam.gitbook.io/vaultscapes';
  static const String collaborateForm =
      'https://mantavyam.notion.site/18152f7cde8880d699a5f2e65f87374e?pvs=105';
  static const String feedbackForm =
      'https://mantavyam.notion.site/17e52f7cde8880e0987fd06d33ef6019?pvs=105';

  // Quick link URLs
  static const String searchUrl = 'https://mantavyam.gitbook.io/vaultscapes?q=';
  static const String githubRepo = 'https://github.com/mantavyam/vaultscapesDB';
  static const String discordCommunity = 'https://discord.com/invite/AQ7PNzdCnC';
  static const String howToUseDatabase =
      'https://mantavyam.gitbook.io/vaultscapes/how-to-use-database';
  static const String howToCollaborate =
      'https://mantavyam.gitbook.io/vaultscapes/how-to-collaborate';
  static const String collaborators =
      'https://mantavyam.gitbook.io/vaultscapes/collaborators';

  /// Constructs semester-specific URL
  /// [semester] should be between 1-8
  static String getSemesterUrl(int semester) {
    if (semester < 1 || semester > 8) {
      return baseGitBook;
    }
    return '$baseGitBook/sem-$semester';
  }

  /// Returns default home URL or semester-specific URL
  static String getHomeUrl({int? semesterPreference}) {
    return semesterPreference != null
        ? getSemesterUrl(semesterPreference)
        : baseGitBook;
  }
}