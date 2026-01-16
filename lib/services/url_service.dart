import '../core/constants/urls.dart';

enum QuickLinkType {
  searchDatabase,
  githubRepository,
  discordCommunity,
  howToUseDatabase,
  howToCollaborate,
  collaborators,
}

class UrlService {
  // Get home URL based on semester preference
  static String getHomeUrl({int? semesterPreference}) {
    return AppUrls.getHomeUrl(semesterPreference: semesterPreference);
  }

  // Get collaborate form URL
  static String getCollaborateUrl() {
    return AppUrls.collaborateForm;
  }

  // Get feedback form URL
  static String getFeedbackUrl() {
    return AppUrls.feedbackForm;
  }

  // Get search URL
  static String getSearchUrl() {
    return AppUrls.searchUrl;
  }

  // Get URL for quick links
  static String getQuickLinkUrl(QuickLinkType type) {
    switch (type) {
      case QuickLinkType.searchDatabase:
        return AppUrls.searchUrl;
      case QuickLinkType.githubRepository:
        return AppUrls.githubRepo;
      case QuickLinkType.discordCommunity:
        return AppUrls.discordCommunity;
      case QuickLinkType.howToUseDatabase:
        return AppUrls.howToUseDatabase;
      case QuickLinkType.howToCollaborate:
        return AppUrls.howToCollaborate;
      case QuickLinkType.collaborators:
        return AppUrls.collaborators;
    }
  }

  // Get quick link type from string
  static QuickLinkType? getQuickLinkTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'search-database':
      case 'searchdatabase':
        return QuickLinkType.searchDatabase;
      case 'github-repository':
      case 'githubrepository':
        return QuickLinkType.githubRepository;
      case 'discord-community':
      case 'discordcommunity':
        return QuickLinkType.discordCommunity;
      case 'how-to-use-database':
      case 'howtousedatabase':
        return QuickLinkType.howToUseDatabase;
      case 'how-to-collaborate':
      case 'howtocollaborate':
        return QuickLinkType.howToCollaborate;
      case 'collaborators':
        return QuickLinkType.collaborators;
      default:
        return null;
    }
  }

  // Get display name for quick link type
  static String getQuickLinkDisplayName(QuickLinkType type) {
    switch (type) {
      case QuickLinkType.searchDatabase:
        return 'Search Database';
      case QuickLinkType.githubRepository:
        return 'GitHub Repository';
      case QuickLinkType.discordCommunity:
        return 'Discord Community';
      case QuickLinkType.howToUseDatabase:
        return 'How to Use Database';
      case QuickLinkType.howToCollaborate:
        return 'How to Collaborate';
      case QuickLinkType.collaborators:
        return 'Collaborators';
    }
  }

  // Get URL string for webview navigation
  static String getWebViewUrl(String linkType) {
    final quickLinkType = getQuickLinkTypeFromString(linkType);
    if (quickLinkType != null) {
      return getQuickLinkUrl(quickLinkType);
    }
    
    // Fallback to base GitBook URL
    return AppUrls.baseGitBook;
  }

  // Get title for webview screen
  static String getWebViewTitle(String linkType) {
    final quickLinkType = getQuickLinkTypeFromString(linkType);
    if (quickLinkType != null) {
      return getQuickLinkDisplayName(quickLinkType);
    }
    
    // Fallback title
    return 'VaultScapes';
  }

  // Validate semester number
  static bool isValidSemester(int semester) {
    return semester >= 1 && semester <= 8;
  }

  // Get semester URL for specific semester
  static String getSemesterUrl(int semester) {
    return AppUrls.getSemesterUrl(semester);
  }

  // Get all available semester options
  static List<int> get availableSemesters => [1, 2, 3, 4, 5, 6, 7, 8];

  // Check if URL is external (should open in system browser)
  static bool isExternalUrl(String url) {
    // Define internal domains that should stay in WebView
    const internalDomains = [
      'mantavyam.gitbook.io',
      'mantavyam.notion.site',
    ];

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Check if the domain is in our internal list
    for (final domain in internalDomains) {
      if (uri.host.contains(domain)) {
        return false;
      }
    }

    // Special cases: GitHub and Discord should open in system browser
    if (uri.host.contains('github.com') || uri.host.contains('discord.com')) {
      return true;
    }

    return false;
  }

  // Pre-fill form URLs with user data (if supported by the service)
  static String getCollaborateUrlWithUserData({String? email}) {
    var url = getCollaborateUrl();
    if (email != null && email.isNotEmpty) {
      // Try to append email as URL parameter for Notion forms
      // Note: This may not work with all Notion forms
      url += url.contains('?') ? '&email=$email' : '?email=$email';
    }
    return url;
  }

  static String getFeedbackUrlWithUserData({String? email}) {
    var url = getFeedbackUrl();
    if (email != null && email.isNotEmpty) {
      // Try to append email as URL parameter for Notion forms
      url += url.contains('?') ? '&email=$email' : '?email=$email';
    }
    return url;
  }
}