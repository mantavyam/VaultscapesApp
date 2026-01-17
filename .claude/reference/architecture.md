## 3. Technical Architecture

### 3.1 Technology Stack

#### 3.1.1 Core Framework
- **Flutter SDK**: Latest stable version (3.x+)
- **Dart**: 3.0+

#### 3.1.2 UI Framework
- **shadcn_flutter**: `^0.0.47`
  - Replaces Material/Cupertino entirely
  - Installation: `https://sunarya-thito.github.io/shadcn_flutter/#/installation`

#### 3.1.3 Required Packages

**Authentication (Phase 2):**
- `google_sign_in`: Latest version
- `firebase_auth`: Latest version (if using Firebase)
- OR `supabase_flutter`: Latest version (alternative backend)

**State Management:**
- `provider`: ^6.0.0 OR
- `riverpod`: ^2.0.0 (recommended for scalability)

**Navigation:**
- `go_router`: ^14.0.0 (declarative routing with deep linking support)

**WebView:**
- `webview_flutter`: ^4.0.0
- `flutter_inappwebview`: ^6.0.0 (alternative with more features)

**HTTP & API:**
- `http`: ^1.1.0 (fetching markdown from GitBook URLs)
- `dio`: ^5.0.0 (optional, for advanced features like retry logic)

**Markdown Rendering:**
- `flutter_markdown`: ^0.6.18 (primary markdown rendering engine)
- `markdown`: ^7.1.1 (markdown parsing for custom block builders)

**Local Storage & Caching:**
- `shared_preferences`: ^2.0.0 (user preferences)
- `hive`: ^2.2.3 (markdown content caching with timestamp tracking)
- `hive_flutter`: ^1.1.0 (Flutter integration for Hive)
- `path_provider`: ^2.0.0 (local file paths)

**File Handling:**
- `file_picker`: ^6.0.0 (for feedback/collaboration forms)
- `open_filex`: ^4.0.0 (open downloaded PDFs)

**PDF Viewing (Optional for Phase 2):**
- `flutter_pdfview`: ^1.3.0 OR
- `syncfusion_flutter_pdfviewer`: ^24.0.0

**URL Launching:**
- `url_launcher`: ^6.0.0 (open PDF links, external resources)

**Utilities:**
- `intl`: ^0.18.0 (date/time formatting)
- `connectivity_plus`: ^5.0.0 (network status monitoring)
- `cached_network_image`: ^3.0.0 (image caching for markdown images)

### 3.2 Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── route_constants.dart
│   │   └── url_constants.dart (GitBook base URLs)
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── color_scheme.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── helpers.dart
│   │   ├── extensions.dart
│   │   └── markdown_helpers.dart (markdown parsing utilities)
│   └── error/
│       ├── exceptions.dart
│       └── failures.dart
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── navigation_model.dart (navigation manifest)
│   │   ├── semester_model.dart
│   │   ├── subject_model.dart
│   │   ├── cached_markdown_model.dart (markdown + timestamp)
│   │   ├── feedback_model.dart
│   │   └── collaboration_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── markdown_repository.dart (fetch & cache markdown)
│   │   ├── navigation_repository.dart (load navigation manifest)
│   │   ├── user_preferences_repository.dart
│   │   ├── feedback_repository.dart
│   │   └── collaboration_repository.dart
│   ├── services/
│   │   ├── markdown_fetcher_service.dart (HTTP fetching)
│   │   ├── markdown_cache_service.dart (Hive caching)
│   │   ├── local_storage_service.dart
│   │   └── analytics_service.dart
│   └── parsers/
│       ├── gitbook_markdown_parser.dart (custom GitBook block parser)
│       ├── hint_block_parser.dart
│       ├── tabs_block_parser.dart
│       ├── expandable_block_parser.dart
│       └── card_block_parser.dart
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   ├── semester.dart
│   │   ├── subject.dart
│   │   ├── markdown_content.dart
│   │   └── navigation_item.dart
│   └── usecases/
│       ├── authenticate_user.dart
│       ├── get_markdown_content.dart
│       ├── refresh_markdown_cache.dart
│       ├── load_navigation_structure.dart
│       ├── submit_feedback.dart
│       └── submit_collaboration.dart
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── markdown_provider.dart (manages markdown state)
│   │   ├── navigation_provider.dart
│   │   └── cache_provider.dart
│   ├── screens/
│   │   ├── onboarding/
│   │   │   ├── welcome_screen.dart
│   │   │   └── profile_setup_screen.dart
│   │   ├── home/
│   │   │   ├── root_homepage_screen.dart
│   │   │   ├── semester_overview_screen.dart (renders markdown)
│   │   │   └── subject_detail_screen.dart (renders markdown)
│   │   ├── alphasignal/
│   │   │   └── alphasignal_webview_screen.dart
│   │   ├── feedback_collaborate/
│   │   │   ├── feedback_collaborate_screen.dart
│   │   │   ├── feedback_form_tab.dart
│   │   │   └── collaborate_form_tab.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── edit_profile_dialog.dart
│   │   └── main_navigation_screen.dart
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_widget.dart
│   │   │   └── empty_state_widget.dart
│   │   ├── cards/
│   │   │   ├── semester_card.dart
│   │   │   ├── subject_card.dart
│   │   │   └── resource_card.dart
│   │   ├── markdown/
│   │   │   ├── markdown_renderer.dart (custom renderer)
│   │   │   ├── hint_block_widget.dart (renders hints as Alerts)
│   │   │   ├── tabs_block_widget.dart (renders tabs as TabList)
│   │   │   ├── expandable_block_widget.dart (renders as Accordion)
│   │   │   ├── card_block_widget.dart (renders GitBook cards)
│   │   │   └── pdf_link_widget.dart (download button for PDFs)
│   │   ├── forms/
│   │   │   ├── custom_text_input.dart
│   │   │   ├── custom_dropdown.dart
│   │   │   └── file_picker_widget.dart
│   │   └── navigation/
│   │       └── custom_bottom_nav_bar.dart
│   └── routes/
│       └── app_router.dart
└── config/
    └── environment_config.dart
```

**New Asset Structure:**
```
assets/
├── data/
│   └── navigation.json (lightweight navigation manifest)
├── images/
│   ├── logo.png
│   ├── semester_thumbnails/
│   │   ├── sem_1.png
│   │   └── ...
│   └── placeholders/
└── fonts/ (if using custom fonts)
```

### 3.3 Data Architecture

#### 3.3.1 Content Management System (Modified Hybrid Approach)

**Navigation Manifest (Local Asset)**

The navigation manifest is a lightweight JSON file bundled with the app that contains:
- Semester structure and metadata
- Subject lists with codes and names
- **Markdown URLs** pointing to GitBook `.md` files
- Resource categorization hints

**Structure: `assets/data/navigation.json`**
```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-01-17T00:00:00Z",
  "baseUrl": "https://mantavyam.gitbook.io/vaultscapes",
  "semesters": [
    {
      "id": "sem-1",
      "title": "Semester 1",
      "description": "Foundational Courses",
      "thumbnailUrl": "assets/images/semester_thumbnails/sem_1.png",
      "overviewMarkdownUrl": "https://mantavyam.gitbook.io/vaultscapes/semester-1.md",
      "syllabusUrl": "https://example.com/sem1-syllabus.pdf",
      "coreSubjects": [
        {
          "id": "cs101",
          "code": "CS101",
          "name": "Introduction to Programming",
          "markdownUrl": "https://mantavyam.gitbook.io/vaultscapes/sem-1/cs101.md"
        },
        {
          "id": "math101",
          "code": "MATH101",
          "name": "Calculus I",
          "markdownUrl": "https://mantavyam.gitbook.io/vaultscapes/sem-1/math101.md"
        }
      ],
      "specializationSubjects": [
        {
          "id": "ai101",
          "code": "AI101",
          "name": "AI Fundamentals",
          "markdownUrl": "https://mantavyam.gitbook.io/vaultscapes/sem-1/specialization/ai101.md"
        }
      ]
    },
    {
      "id": "sem-2",
      "title": "Semester 2",
      "description": "Core Engineering Concepts",
      "thumbnailUrl": "assets/images/semester_thumbnails/sem_2.png",
      "overviewMarkdownUrl": "https://mantavyam.gitbook.io/vaultscapes/semester-2.md",
      "coreSubjects": [],
      "specializationSubjects": []
    }
    // ... semesters 3-8
  ]
}
```

**Benefits of This Structure:**
- Small file size (~10-50 KB for 8 semesters)
- Easy to update via app release or dynamic download
- Provides instant navigation structure
- Markdown content fetched on-demand

---

#### 3.3.2 Markdown Fetching & Caching Strategy

**Workflow:**
1. **App Launch**: Load `navigation.json` from assets
2. **User Navigates to Page**: Check cache for markdown
3. **Cache Hit (< 24 hours old)**: Serve from cache immediately
4. **Cache Miss/Stale**: 
   - Show loading indicator
   - Fetch markdown from GitBook URL
   - Parse and render
   - Cache with timestamp
5. **Pull-to-Refresh**: Force re-fetch and update cache

**Cache Data Model:**
```dart
class CachedMarkdown {
  final String url;
  final String content;
  final DateTime timestamp;
  final String etag; // Optional: for HTTP caching headers
  
  bool get isStale {
    final age = DateTime.now().difference(timestamp);
    return age.inHours > 24; // 24-hour TTL
  }
}
```

**Hive Cache Implementation:**
```dart
class MarkdownCacheService {
  static const String boxName = 'markdown_cache';
  late Box<CachedMarkdown> _box;
  
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CachedMarkdownAdapter());
    _box = await Hive.openBox<CachedMarkdown>(boxName);
  }
  
  Future<CachedMarkdown?> get(String url) async {
    return _box.get(url);
  }
  
  Future<void> set(String url, String content) async {
    final cached = CachedMarkdown(
      url: url,
      content: content,
      timestamp: DateTime.now(),
    );
    await _box.put(url, cached);
  }
  
  Future<void> clear() async {
    await _box.clear();
  }
  
  Future<void> delete(String url) async {
    await _box.delete(url);
  }
}
```

---

#### 3.3.3 Markdown Repository Pattern

**MarkdownRepository:**
```dart
class MarkdownRepository {
  final MarkdownFetcherService _fetcher;
  final MarkdownCacheService _cache;
  final ConnectivityService _connectivity;
  
  MarkdownRepository(this._fetcher, this._cache, this._connectivity);
  
  /// Get markdown content with smart caching
  Future<String> getMarkdown(String url, {bool forceRefresh = false}) async {
    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = await _cache.get(url);
      if (cached != null && !cached.isStale) {
        return cached.content;
      }
    }
    
    // Check network connectivity
    if (!await _connectivity.isConnected) {
      // Return stale cache if available, else throw error
      final cached = await _cache.get(url);
      if (cached != null) {
        return cached.content; // Stale but better than nothing
      }
      throw NetworkException('No internet connection');
    }
    
    // Fetch from network
    try {
      final content = await _fetcher.fetch(url);
      
      // Update cache
      await _cache.set(url, content);
      
      return content;
    } catch (e) {
      // Network error - try to return cached version
      final cached = await _cache.get(url);
      if (cached != null) {
        return cached.content;
      }
      rethrow;
    }
  }
  
  /// Clear all cached markdown
  Future<void> clearCache() async {
    await _cache.clear();
  }
  
  /// Refresh specific page
  Future<String> refreshMarkdown(String url) async {
    return getMarkdown(url, forceRefresh: true);
  }
}
```

**MarkdownFetcherService:**
```dart
class MarkdownFetcherService {
  final http.Client _client;
  
  MarkdownFetcherService(this._client);
  
  Future<String> fetch(String url) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {'Accept': 'text/markdown'},
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw FetchException(
          'Failed to fetch markdown: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw FetchException('Request timed out');
    } on http.ClientException {
      throw NetworkException('Network error');
    }
  }
}
```

---

#### 3.3.4 GitBook Markdown Parsing Strategy

**Custom Markdown Builders for GitBook Blocks:**

GitBook uses custom markdown extensions. We'll parse these and map them to shadcn_flutter components.

**Supported GitBook Blocks (Phase 1):**
- ✅ **Hints**: Map to `Alert` component (info/warning/success variants)
- ✅ **Expandables**: Map to `Accordion` component
- ✅ **Tabs**: Map to `TabList` component
- ✅ **Files/PDFs**: Parse links, render as download `Button`
- ✅ **Cards**: Custom widget with title/description
- ⚠️ **Tables**: Use `flutter_markdown` default renderer
- ⚠️ **Images**: Use `CachedNetworkImage`
- ❌ **Steppers, Drawings, Math**: Fallback to code block or plain text (Phase 2)

**Example: Hint Block Parser**

GitBook Hint Markdown:
```markdown
{% hint style="info" %}
This is an informational hint
{% endhint %}
```

Custom Parser:
```dart
class HintBlockParser extends BlockParser {
  static final _hintPattern = RegExp(
    r'{% hint style="(info|warning|success|danger)" %}(.*?){% endhint %}',
    dotAll: true,
  );
  
  @override
  List<String> get pattern => [r'{% hint'];
  
  @override
  bool parse(BlockParser parser) {
    final match = _hintPattern.firstMatch(parser.current);
    if (match == null) return false;
    
    final style = match.group(1)!;
    final content = match.group(2)!.trim();
    
    parser.addElement(HintElement(style, content));
    parser.advance();
    return true;
  }
}

class HintElement extends Element {
  final String style;
  final String content;
  
  HintElement(this.style, this.content) : super('hint', [Text(content)]);
}
```

**Rendering Hint as Alert:**
```dart
class HintBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final hintElement = element as HintElement;
    
    AlertVariant variant;
    switch (hintElement.style) {
      case 'info':
        variant = AlertVariant.info;
        break;
      case 'warning':
        variant = AlertVariant.warning;
        break;
      case 'success':
        variant = AlertVariant.success;
        break;
      case 'danger':
        variant = AlertVariant.destructive;
        break;
      default:
        variant = AlertVariant.info;
    }
    
    return Alert(
      variant: variant,
      title: Text(_getTitle(hintElement.style)),
      child: Text(hintElement.content),
    );
  }
  
  String _getTitle(String style) {
    switch (style) {
      case 'info': return 'Info';
      case 'warning': return 'Warning';
      case 'success': return 'Success';
      case 'danger': return 'Important';
      default: return 'Note';
    }
  }
}
```

**Similar Implementation for:**
- **Expandables** → `Collapsible` or `Accordion`
- **Tabs** → `TabList` + `TabPane`
- **Cards** → Custom `Card` widget

---

#### 3.3.5 PDF Link Handling

Markdown links to PDFs are parsed and rendered as download buttons:

**Markdown:**
```markdown
[Download Semester 1 Syllabus](https://example.com/sem1-syllabus.pdf)
```

**Custom Link Parser:**
```dart
class PdfLinkBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag != 'a') return SizedBox.shrink();
    
    final href = element.attributes['href'] ?? '';
    final text = element.textContent;
    
    // Check if link is a PDF
    if (href.endsWith('.pdf')) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Button(
          onPressed: () => _downloadPdf(href),
          leading: Icon(LucideIcons.download),
          child: Text(text),
        ),
      );
    }
    
    // Default link handling
    return InkWell(
      onTap: () => _launchUrl(href),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
  
  void _downloadPdf(String url) async {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }
  
  void _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }
}
```

---

#### 3.3.6 Navigation Structure Loading

**NavigationRepository:**
```dart
class NavigationRepository {
  Future<NavigationManifest> loadManifest() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/navigation.json',
    );
    final jsonData = json.decode(jsonString);
    return NavigationManifest.fromJson(jsonData);
  }
}

class NavigationManifest {
  final String version;
  final DateTime lastUpdated;
  final String baseUrl;
  final List<Semester> semesters;
  
  NavigationManifest({
    required this.version,
    required this.lastUpdated,
    required this.baseUrl,
    required this.semesters,
  });
  
  factory NavigationManifest.fromJson(Map<String, dynamic> json) {
    return NavigationManifest(
      version: json['version'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      baseUrl: json['baseUrl'],
      semesters: (json['semesters'] as List)
          .map((s) => Semester.fromJson(s))
          .toList(),
    );
  }
}
```

---

### 3.4 Authentication Architecture

#### 3.4.1 Phase 1: Mock Authentication
```dart
Future<User> mockAuthenticate() async {
  await Future.delayed(Duration(seconds: 2)); // Simulate network delay
  return User(
    uid: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
    email: 'guest@vaultscapes.com',
    displayName: 'Guest User',
    profilePictureUrl: null,
    homepagePreference: 'root',
    isGuest: false,
  );
}
```

#### 3.4.2 Phase 2: Google OAuth Implementation
```dart
// Integration with Firebase Auth
Future<User> authenticateWithGoogle() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  final GoogleSignInAuthentication? googleAuth = 
      await googleUser?.authentication;
  
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth?.accessToken,
    idToken: googleAuth?.idToken,
  );
  
  final userCredential = 
      await FirebaseAuth.instance.signInWithCredential(credential);
  
  // Map to app User model
  return User.fromFirebaseUser(userCredential.user!);
}
```

### 3.5 Modular Content Management

#### 3.5.1 Adding New Semester
1. Add semester entry to `navigation.json`:
```json
{
  "id": "sem-9",
  "title": "Semester 9",
  "description": "Advanced Topics",
  "overviewMarkdownUrl": "https://mantavyam.gitbook.io/vaultscapes/semester-9.md",
  "coreSubjects": [],
  "specializationSubjects": []
}
```
2. Create corresponding markdown file on GitBook
3. App automatically picks up new semester on next `navigation.json` update
4. **No code changes required**

#### 3.5.2 Adding New Subject
1. Add subject to semester's `coreSubjects` or `specializationSubjects` array in `navigation.json`
2. Create subject markdown file on GitBook
3. URL mapped in navigation manifest
4. **No code changes required**

#### 3.5.3 Updating Content
**Option A: GitBook Changes (No App Update)**
- Edit markdown files on GitBook
- Changes reflected on next cache refresh (24 hours or manual pull-to-refresh)

**Option B: Navigation Changes (Requires App Update)**
- Update `navigation.json` (add/remove semesters or subjects)
- Release new app version

**Option C: Future Dynamic Navigation (Phase 3)**
- Host `navigation.json` on server
- Fetch on app launch with version checking
- Update navigation structure without app release

---

### 3.6 Error Handling Strategy

**Markdown Loading States:**
```dart
enum MarkdownLoadState {
  loading,        // Fetching from network
  loaded,         // Successfully loaded
  cached,         // Serving from cache
  error,          // Network/parse error
  offline,        // No network, no cache
}
```

**UI States:**
- **Loading**: Show `CircularProgress` with "Loading content..." message
- **Cached**: Show content with subtle badge "Viewing cached version"
- **Error**: Show error widget with retry button
- **Offline**: Show cached content (if available) with "Offline mode" banner

---

### 3.7 Performance Optimization

**Strategies:**
1. **Lazy Loading**: Only fetch markdown when user navigates to page
2. **Preloading**: Prefetch markdown for likely next pages (e.g., subjects in current semester)
3. **Image Caching**: Use `CachedNetworkImage` for markdown images
4. **Debounced Refresh**: Prevent rapid cache refreshes
5. **Chunked Parsing**: Parse large markdown files in isolates (if needed)

**Monitoring:**
- Track cache hit/miss ratio
- Monitor network request frequency
- Measure markdown parse time
- Log GitBook URL availability