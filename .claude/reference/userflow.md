## 6. Detailed User Flows

### 6.1 Flow 1: First-Time User (Get Started)

```
[1] User installs app and opens
    ↓
[2] Welcome Screen displays
    ↓
[3] User taps "Get Started"
    ↓
[4] Auth Bottom Sheet slides up from bottom
    ↓
[5] User taps "Continue with Google"
    ↓
[6] PHASE 1: 2-second loading animation, mock user created
    PHASE 2: Google Sign-In dialog appears
    ↓
[7] PHASE 1: Mock user saved to local storage
    PHASE 2: User selects Google account, grants permissions
    ↓
[8] PHASE 2: Firebase returns user object, saved to Firestore + local storage
    ↓
[9] Navigate to Name Customization Screen
    ↓
[10] User sees provider name "John Doe" in TextField
     ↓
[11] Option A: User edits to "Johnny" → Tap "Continue"
     Option B: User taps "Skip for now"
     ↓
[12] PHASE 1: customName saved to local storage
     PHASE 2: customName saved to Firestore + local storage
     ↓
[13] Navigate to Home Screen (bottom nav bar visible)
     ↓
[14] Home WebView loads default GitBook URL
     ↓
[15] User can now navigate between 4 tabs
```

**Decision Points**:
- Step 5: User could also choose GitHub (identical flow)
- Step 11: User could close app (state persists, resumes at Home on reopen)

---

### 6.2 Flow 2: First-Time User (Explore)

```
[1] User installs app and opens
    ↓
[2] Welcome Screen displays
    ↓
[3] User taps "Explore"
    ↓
[4] System sets isGuest = true, hasSeenWelcome = true (local storage)
    ↓
[5] Navigate directly to Home Screen (skip auth)
    ↓
[6] Home WebView loads default GitBook URL
    ↓
[7] User browses content across all 4 tabs
    ↓
[8] User taps Profile tab
    ↓
[9] Profile shows "Welcome, Guest!" with "Create Profile" button
    ↓
[10] User continues browsing (no semester preference available)
```

**Conversion Path** (Guest → Authenticated):
```
[11] User taps "Create Profile" button
     ↓
[12] Navigate back to Welcome Screen
     ↓
[13] Auth Bottom Sheet opens automatically
     ↓
[14] Continue with Flow 1 from Step 5
```

---

### 6.3 Flow 3: Returning Authenticated User

```
[1] User opens app (not first time)
    ↓
[2] App reads hasSeenWelcome = true from local storage
    ↓
[3] PHASE 1: Skip to Home Screen (mock user loaded)
    PHASE 2: Check auth token validity
    ↓
[4] PHASE 2 (if token valid): Fetch latest user data from Firestore
    PHASE 2 (if token expired): Attempt silent refresh, fallback to re-auth
    ↓
[5] Navigate to Home Screen
    ↓
[6] Home WebView loads URL based on semester preference
    Example: User has semesterPreference = 3
    URL: 'https://mantavyam.gitbook.io/vaultscapes/sem-3'
    ↓
[7] User browses personalized content
```

**Preference Update Flow**:
```
[8] User taps Profile tab
    ↓
[9] Taps "Semester: Sem 3" setting
    ↓
[10] Dropdown modal appears with options (Default, Sem 1-8)
     ↓
[11] User selects "Sem 5"
     ↓
[12] PHASE 1: Save to local storage only
     PHASE 2: Save to Firestore + local storage
     ↓
[13] Profile screen updates to show "Semester: Sem 5"
     ↓
[14] User taps Home tab
     ↓
[15] Home WebView reloads with new URL:
     'https://mantavyam.gitbook.io/vaultscapes/sem-5'
```

---

### 6.4 Flow 4: Search Interaction

```
[1] User is on Profile tab
    ↓
[2] Taps "Search Database" quick link
    ↓
[3] Navigate to Search Screen
    ↓
[4] Screen loads with WebView displaying:
    'https://mantavyam.gitbook.io/vaultscapes?q='
    ↓
[5] JavaScript injection focuses search input field
    ↓
[6] Keyboard automatically opens
    ↓
[7] User types query: "data structures"
    ↓
[8] GitBook's search updates results in real-time (native functionality)
    ↓
[9] User taps a search result
    ↓
[10] WebView navigates to selected page
     ↓
[11] User presses back button → Returns to Profile tab
```

---

### 6.5

Flow 5: Quick Link Navigation

```
[1] User is on Profile tab
    ↓
[2] Taps "GitHub Repository" quick link
    ↓
[3] Navigate to Generic WebView Screen
    ↓
[4] AppBar displays: "GitHub Repository" with back button
    ↓
[5] WebView loads: 'https://github.com/mantavyam/vaultscapesDB'
    ↓
[6] User can interact with GitHub page (scroll, click links)
    ↓
[7] User presses back button in AppBar
    ↓
[8] Navigate back to Profile tab
```

**Note**: All 6 quick links follow this identical pattern

---

### 6.6 Flow 6: Logout

```
[1] Authenticated user on Profile tab
    ↓
[2] Scrolls to bottom, taps "Logout" button
    ↓
[3] Confirmation dialog appears:
    "Are you sure you want to log out?"
    [Cancel] [Logout]
    ↓
[4] User taps "Logout"
    ↓
[5] PHASE 1: Clear local storage
    PHASE 2: Sign out from Firebase Auth, clear local storage
    ↓
[6] Navigate to Welcome Screen
    ↓
[7] User sees "Get Started" and "Explore" options again
```

---