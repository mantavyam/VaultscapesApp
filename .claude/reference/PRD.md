# Product Requirements Document (PRD)
## VaultScapes Mobile Application

---

## 1. Executive Summary

### 1.1 Product Vision
VaultScapes Mobile is a lightweight Flutter application that transforms scattered educational resources (GitBook documentation, Notion forms, GitHub repositories) into a unified, mobile-optimized experience for students. The app prioritizes speed and simplicity, offering optional authentication for personalized semester-based navigation.

## 8. Development Phases

### 8.1 Phase 1: Core MVP (Mock Authentication)

**Objective**: Deliver fully functional app with mocked auth to validate user flows and WebView integration

#### Segment 1: Foundation & Navigation (Parts 1-5)

**Part 1-2: Project Setup**
- [ ] Initialize Flutter project with analysis_options, linting
- [ ] Install core packages: webview_flutter, go_router, provider, shared_preferences
- [ ] Create folder structure as per Section 5.2
- [ ] Define constants (URLs, colors, text strings)
- [ ] Set up GoRouter with all route definitions
- [ ] Configure Android/iOS platform-specific settings (permissions, minSdk)

**Part 3-4: Data Layer**
- [ ] Implement UserModel with JSON serialization
- [ ] Implement PreferencesModel with JSON serialization
- [ ] Create StorageService wrapper for SharedPreferences
- [ ] Create URLService with all URL construction methods
- [ ] Implement UserProvider with mock auth logic
- [ ] Implement PreferencesProvider with persistence

**Part 5: Onboarding Flow**
- [ ] Build WelcomeScreen with two CTAs
- [ ] Build AuthBottomSheet with mock sign-in logic
- [ ] Build NameCustomizationScreen with TextField validation
- [ ] Implement navigation flow: Welcome → Auth → Name → Home
- [ ] Test first-time launch flag persistence

#### Segment 2: Main Features & Polish (Parts 6-10)

**Part 6-7: WebView Screens**
- [ ] Create reusable WebViewWrapper widget with loading/error states
- [ ] Build MainNavigation scaffold with BottomNavigationBar
- [ ] Implement HomeScreen with dynamic URL loading
- [ ] Implement CollaborateScreen (static URL)
- [ ] Implement FeedbackScreen (static URL)
- [ ] Test WebView back button handling, pull-to-refresh

**Part 8: Profile Screen**
- [ ] Build Profile layout (authenticated + guest variants)
- [ ] Implement inline name editing functionality
- [ ] Create QuickLinkTile widget with navigation to WebView
- [ ] Build SemesterDropdown modal
- [ ] Implement semester preference logic (save → reload Home)
- [ ] Build logout confirmation dialog

**Part 9: Search & Quick Links**
- [ ] Build generic WebViewScreen for quick links
- [ ] Implement SearchScreen with keyboard auto-focus
- [ ] Test JavaScript injection for GitBook search focus
- [ ] Verify all 6 quick links navigate correctly

**Part 10: Testing & Bug Fixes**
- [ ] End-to-end testing: Welcome → Auth → Home → Profile → Logout
- [ ] Test guest mode flow: Explore → Profile → Create Profile
- [ ] Verify semester preference persists across app restarts
- [ ] Test WebView error states (offline mode)
- [ ] Fix critical bugs
- [ ] Code review and documentation

**Phase 1 Deliverables**:
✅ Fully navigable app with all 4 main screens  
✅ Mock authentication with name customization  
✅ Semester preference system working  
✅ All WebViews loading correctly  
✅ Guest mode functional  
✅ App ready for user testing (without real auth)  

---

### 8.2 Phase 2: Real Authentication (1 Week)

**Objective**: Replace mocked auth with Firebase OAuth, add cloud persistence

#### Part 1-2: Firebase Setup
- [ ] Create Firebase project in console
- [ ] Configure Android app (google-services.json)
- [ ] Configure iOS app (GoogleService-Info.plist)
- [ ] Enable Google Sign-In in Authentication settings
- [ ] Enable GitHub OAuth in Authentication settings
- [ ] Set up Firestore database with users collection
- [ ] Configure Firestore security rules
- [ ] Install Firebase packages: firebase_core, firebase_auth, google_sign_in, cloud_firestore

#### Part 3-4: Authentication Implementation
- [ ] Create AuthService with Google Sign-In methods
- [ ] Create AuthService with GitHub OAuth methods
- [ ] Update UserProvider to use AuthService instead of mocks
- [ ] Implement token persistence and refresh logic
- [ ] Add Firestore user document creation on first sign-in
- [ ] Update NameCustomizationScreen to save to Firestore
- [ ] Implement silent sign-in on app restart

#### Part 5: Cloud Sync & Testing
- [ ] Update PreferencesProvider to sync semester preference to Firestore
- [ ] Implement logout with Firebase sign-out
- [ ] Test Google Sign-In flow on Android and iOS
- [ ] Test GitHub OAuth flow on Android and iOS
- [ ] Verify Firestore data persistence
- [ ] Test token refresh after expiration
- [ ] Handle edge cases: auth cancellation, network errors
- [ ] Final testing and release preparation

**Phase 2 Deliverables**:
✅ Real Google authentication working  
✅ Real GitHub authentication working  
✅ User profiles stored in Firestore  
✅ Semester preferences synced to cloud  
✅ Seamless experience across devices  
✅ Production-ready app  

---

## 9. Testing Strategy

### 9.1 Phase 1 Testing (Mock Auth)

**Unit Tests**:
- UserModel JSON serialization/deserialization
- PreferencesModel JSON serialization/deserialization
- URLService URL construction logic (semester variations)
- StorageService read/write operations

**Widget Tests**:
- WelcomeScreen button interactions
- AuthBottomSheet opens and dismisses correctly
- BottomNavigationBar tab switching
- SemesterDropdown selection updates preference

**Integration Tests**:
- Full flow: Welcome → Mock Auth → Name → Home → Profile → Logout
- Guest flow: Welcome → Explore → Profile → Create Profile
- Semester change triggers Home WebView reload

**Manual Testing Checklist for Developer**:
```
Welcome Screen:
[ ] "Get Started" button opens auth bottom sheet
[ ] "Explore" button navigates to home as guest
[ ] Back button exits app

Auth Bottom Sheet:
[ ] Both buttons show loading animation (2 seconds)
[ ] Mock user created after loading
[ ] Navigate to name customization
[ ] Dismissing sheet returns to welcome

Name Customization:
[ ] Provider name displayed in TextField
[ ] Can edit name (2-30 characters)
[ ] "Continue" saves custom name
[ ] "Skip" uses provider name

Home/Collaborate/Feedback Screens:
[ ] WebViews load URLs correctly
[ ] Pull-to-refresh works
[ ] Loading indicator appears during load
[ ] Back button navigates WebView history first
[ ] External links prompt system browser

Profile Screen (Authenticated):
[ ] Name displayed correctly
[ ] Email displayed
[ ] All 6 quick links navigate to correct URLs
[ ] Semester dropdown shows all 8 semesters
[ ] Semester selection reloads Home WebView
[ ] Logout shows confirmation dialog

Profile Screen (Guest):
[ ] "Create Profile" button opens auth flow
[ ] Quick links still accessible
[ ] Settings section not visible

Search:
[ ] Keyboard opens automatically
[ ] GitBook search field focused
[ ] Search results display correctly
```

---

### 9.2 Phase 2 Testing (Real Auth)

**Firebase Auth Tests**:
- Google Sign-In success flow
- Google Sign-In cancellation
- GitHub OAuth success flow
- GitHub OAuth failure (wrong credentials)
- Token persistence across app restarts
- Token refresh on expiration
- Multiple account switching

**Firestore Tests**:
- User document created on first sign-in
- User document updated on name change
- Semester preference synced to cloud
- Data loads correctly on different device

**Manual Testing Checklist**:
```
Google Authentication:
[ ] Sign-in dialog appears
[ ] Can select Google account
[ ] Profile data fetched (name, email, photo)
[ ] User document created in Firestore
[ ] Restarting app auto-signs in

GitHub Authentication:
[ ] OAuth web flow opens
[ ] Can authorize GitHub app
[ ] Profile data fetched
[ ] User document created in Firestore

Cloud Sync:
[ ] Semester preference saves to Firestore
[ ] Name change saves to Firestore
[ ] Sign in on second device loads preferences
[ ] Logout clears local and cloud sessions

Error Handling:
[ ] Network error shows appropriate message
[ ] Auth cancellation returns to welcome
[ ] Token expiration triggers re-auth
```

---

## 10. Document Metadata

**Document Version**: 1.0  
**Last Updated**: January 16, 2026  
**Author**: Claude (Anthropic)  
**Reviewed By**: [SHIVAM SINGH]  
**Next Review**: [After Phase 1 completion]  

**Change Log**:
- v1.0 (2026-01-16): Initial PRD creation based on idea.md requirements

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **Mock Auth** | Simulated authentication in Phase 1 that creates local user objects without real OAuth |
| **Semester Preference** | User's selected semester (1-8) that determines default Home screen URL |
| **Guest Mode** | Unauthenticated usage path via "Explore" button |
| **Quick Links** | 6 additional URLs accessible from Profile screen |
| **WebView** | Embedded browser component for displaying web content in-app |
| **Bottom Sheet** | Modal dialog that slides up from bottom of screen |

---

## Appendix B: URL Reference

**Main Navigation URLs**:
```
Home (default): https://mantavyam.gitbook.io/vaultscapes
Home (semester): https://mantavyam.gitbook.io/vaultscapes/sem-{1-8}
Collaborate: https://mantavyam.notion.site/18152f7cde8880d699a5f2e65f87374e?pvs=105
Feedback: https://mantavyam.notion.site/17e52f7cde8880e0987fd06d33ef6019?pvs=105
```

**Quick Link URLs**:
```
Search: https://mantavyam.gitbook.io/vaultscapes?q=
GitHub: https://github.com/mantavyam/vaultscapesDB
Discord: https://discord.com/invite/AQ7PNzdCnC
How to Use: https://mantavyam.gitbook.io/vaultscapes/how-to-use-database
How to Collaborate: https://mantavyam.gitbook.io/vaultscapes/how-to-collaborate
Collaborators: https://mantavyam.gitbook.io/vaultscapes/collaborators
```

---

**END OF PRD**