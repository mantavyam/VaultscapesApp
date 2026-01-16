## 5. Technical Architecture

### 5.1 Technology Stack

**Core Framework**:
- **Flutter SDK**: 3.24.0 or later (stable channel)
- **Dart SDK**: 3.5.0 or later

**Essential Packages**:

| Package | Version | Purpose |
|---------|---------|---------|
| `webview_flutter` | ^4.9.0 | WebView rendering for content pages |
| `shared_preferences` | ^2.3.0 | Local storage for user preferences |
| `go_router` | ^14.6.0 | Declarative routing and navigation |
| `firebase_core` | ^3.10.0 | Firebase initialization (Phase 2) |
| `firebase_auth` | ^5.3.3 | Google/GitHub authentication (Phase 2) |
| `google_sign_in` | ^6.2.2 | Google OAuth (Phase 2) |
| `cloud_firestore` | ^5.5.2 | User profile storage (Phase 2) |
| `provider` | ^6.1.0 | State management (lightweight) |

**Optional Packages** (for enhancements):
- `flutter_launcher_icons`: Custom app icon generation
- `flutter_native_splash`: Native splash screen
- `url_launcher`: Open external URLs in system browser

---

### 5.2 Project Structure

```
lib/
├── main.dart                          # App entry point, MaterialApp config
│
├── core/
│   ├── constants/
│   │   └── urls.dart                 # All static URLs (URLService)
│   ├── theme/
│   │   ├── app_theme.dart            # ThemeData definitions
│   │   └── colors.dart               # Color palette
│   └── router/
│       └── app_router.dart           # GoRouter configuration
│
├── models/
│   ├── user_model.dart               # User data class
│   └── preferences_model.dart        # App preferences data class
│
├── services/
│   ├── storage_service.dart          # SharedPreferences wrapper
│   ├── auth_service.dart             # Authentication logic (Phase 2)
│   └── url_service.dart              # URL construction logic
│
├── providers/
│   ├── user_provider.dart            # User state management
│   └── preferences_provider.dart     # App preferences state
│
├── screens/
│   ├── onboarding/
│   │   ├── welcome_screen.dart       # Initial screen with Get Started/Explore
│   │   └── name_customization_screen.dart  # Optional name edit
│   │
│   ├── main/
│   │   ├── main_navigation.dart      # Bottom nav bar scaffold
│   │   ├── home_screen.dart          # Home WebView
│   │   ├── collaborate_screen.dart   # Collaborate WebView
│   │   ├── feedback_screen.dart      # Feedback WebView
│   │   └── profile_screen.dart       # Profile with settings
│   │
│   └── webview/
│       ├── webview_screen.dart       # Generic WebView wrapper
│       └── search_screen.dart        # Search with keyboard trigger
│
└── widgets/
    ├── auth_bottom_sheet.dart        # Sign-in modal
    ├── webview_wrapper.dart          # Reusable WebView with loading
    ├── profile_avatar.dart           # Avatar with initials generator
    ├── quick_link_tile.dart          # Profile quick link list item
    └── semester_dropdown.dart        # Semester selection modal
```

---

### 5.3 Data Models

#### 5.3.1 UserModel

```dart
class UserModel {
  final String userId;              // Unique identifier (Firebase UID or mock ID)
  final String email;               // From OAuth provider
  final String providerName;        // Original name from Google/GitHub
  final String? customName;         // User-edited name (null if not customized)
  final String authProvider;        // "google" or "github"
  final bool isAuthenticated;       // false in Phase 1 (mock), true in Phase 2
  final String? photoURL;           // Profile picture URL (Phase 2)
  
  // Computed property for display name
  String get displayName => customName ?? providerName;
  
  // Convert to/from JSON for local storage
  Map<String, dynamic> toJson();
  factory UserModel.fromJson(Map<String, dynamic> json);
}
```

#### 5.3.2 PreferencesModel

```dart
class PreferencesModel {
  final int? semesterPreference;    // 1-8 or null (default)
  final bool hasSeenWelcome;        // First-time launch flag
  final DateTime? lastActive;       // Last app open timestamp
  
  Map<String, dynamic> toJson();
  factory PreferencesModel.fromJson(Map<String, dynamic> json);
}
```

---

### 5.4 State Management Strategy

**Approach**: Provider pattern (lightweight, built-in to Flutter ecosystem)

**Key Providers**:

1. **UserProvider**
   - Manages: Current user state (authenticated vs. guest)
   - Exposes: `UserModel? currentUser`, `bool isGuest`, `logout()`, `updateName()`
   - Listens to: Auth state changes (Phase 2)

2. **PreferencesProvider**
   - Manages: App-wide preferences
   - Exposes: `PreferencesModel preferences`, `setSemester()`, `markWelcomeSeen()`
   - Persists: All changes to SharedPreferences

**Provider Tree** (in `main.dart`):
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => PreferencesProvider()),
  ],
  child: MaterialApp(...),
)
```

---

### 5.5 Navigation Architecture

**Routing Strategy**: GoRouter (declarative, type-safe)

**Route Definitions**:

```dart
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        // Check if user has seen welcome
        final prefs = context.read<PreferencesProvider>();
        if (!prefs.preferences.hasSeenWelcome) {
          return '/welcome';
        }
        return '/home';
      },
    ),
    
    GoRoute(
      path: '/welcome',
      builder: (context, state) => WelcomeScreen(),
    ),
    
    GoRoute(
      path: '/name-customization',
      builder: (context, state) => NameCustomizationScreen(),
    ),
    
    ShellRoute(
      builder: (context, state, child) => MainNavigation(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
        GoRoute(path: '/collaborate', builder: (_, __) => CollaborateScreen()),
        GoRoute(path: '/feedback', builder: (_, __) => FeedbackScreen()),
        GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
      ],
    ),
    
    GoRoute(
      path: '/webview/:type',
      builder: (context, state) {
        final type = state.pathParameters['type']!;
        return WebViewScreen(linkType: type);
      },
    ),
    
    GoRoute(
      path: '/search',
      builder: (context, state) => SearchScreen(),
    ),
  ],
);
```

**Navigation Flow**:
```
App Launch
  ↓
Check hasSeenWelcome
  ↓
  ├─ false → /welcome
  └─ true → /home
  
Welcome Screen
  ↓
  ├─ "Get Started" → Auth Bottom Sheet → /name-customization (optional) → /home
  └─ "Explore" → /home (guest mode)
```

---

### 5.6 Local Storage Schema

**SharedPreferences Keys**:

| Key | Type | Purpose | Example Value |
|-----|------|---------|---------------|
| `user_data` | JSON String | Serialized UserModel | `'{"userId":"mock_123",...}'` |
| `preferences` | JSON String | Serialized PreferencesModel | `'{"semesterPreference":3,...}'` |
| `auth_token` | String | Firebase ID token (Phase 2) | `'eyJhbGciOiJSUzI1...'` |
| `has_seen_welcome` | Boolean | First-time launch flag | `true` |

---

### 5.7 Firebase Configuration (Phase 2)

#### 5.7.1 Firestore Schema

**Collection**: `users`

**Document Structure**:
```json
{
  "users/{userId}": {
    "email": "student@example.com",
    "providerName": "John Doe",
    "customName": "Johnny",               // null if not set
    "authProvider": "google",             // "google" or "github"
    "photoURL": "https://...",            // null if not available
    "semesterPreference": 3,              // 1-8 or null
    "createdAt": "2026-01-16T10:30:00Z",
    "lastActive": "2026-01-16T15:45:00Z"
  }
}
```

**Firestore Rules** (Phase 2):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can only read/write their own document
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### 5.7.2 Authentication Providers Setup

**Google Sign-In**:
1. Enable in Firebase Console → Authentication → Sign-in method
2. Add SHA-1/SHA-256 fingerprints (Android)
3. Configure OAuth consent screen in Google Cloud Console
4. Add authorized domains: `vaultscapes.app` (if custom domain)

**GitHub Sign-In**:
1. Enable in Firebase Console
2. Create OAuth App in GitHub Settings → Developer settings
3. Set Authorization callback URL: `https://{project-id}.firebaseapp.com/__/auth/handler`
4. Copy Client ID and Secret to Firebase Console

---