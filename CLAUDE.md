# Vaultscapes

VaultScapes Mobile is a lightweight Flutter application that transforms scattered educational resources (GitBook documentation, Notion forms, GitHub repositories) into a unified, mobile-optimized experience for students. The app prioritizes speed and simplicity, offering optional authentication for personalized semester-based navigation.

## Tech Stack

- **Application**: Flutter, Dart
- **Authentication** - Google, Github (Skip Auth Available too)

## Target Project Structure

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

## Reference Documentation

Read these documents when working on specific areas:

| Document | When to Read |
|----------|--------------|
| `.claude/PRD.md` | Understanding requirements |
| `.claude/reference/overview.md` | Executive Summary, Product Scope, User Personas |
| `.claude/reference/requirements.md` | Functional Requirements including Onboarding & Auth, Home Screen & Bottom Navigation, Profile Screen and URL Management System |
| `.claude/reference/architecture.md` | App Architecture including Tech Stack, Project Structure, Data Models, State Management Strategy, Navigation Architecture, Local Storage Schema, Firebase Configuration|
| `.claude/reference/userflow.md` | 4 Detailed Userflows including 'First time user (Get Started)', 'First time user (Get Started)', 'Returning Authenticated User', 'Search Interaction', 'Quick Link Navigation', 'Logout'|
| `.claude/reference/ui-ux.md` | UI/UX Specs including Design System (Color Palette, Typography, Spacing System, Component Specs), Responsive Design Guidelines, Accessibility Requirements|
| `.claude/reference/idea.md` | Basic Idea of App Documented by Developer (Prefer documents above for extensive details)|