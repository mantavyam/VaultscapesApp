## 4. Functional Requirements

### 4.1 Onboarding & Authentication

#### 4.1.1 Welcome Screen (First Launch Only)
**Trigger Condition**: App opens for the first time (flag: `hasSeenWelcome` not set in local storage)

**UI Components**:
- App logo (centered, 120x120dp)
- App name/tagline ("Your Study Companion" - 18sp)
- **Primary CTA**: "Get Started" button (filled, 48dp height, full width minus 32dp margins)
- **Secondary CTA**: "Explore" button (outlined, 48dp height, same width)
- 16dp vertical spacing between buttons

**Behaviors**:
| User Action | System Response |
|-------------|-----------------|
| Tap "Get Started" | Open authentication bottom sheet (modal) |
| Tap "Explore" | Set `isGuest = true`, navigate to Home Screen, mark `hasSeenWelcome = true` |
| Back button press | Exit app (no navigation history) |

---

#### 4.1.2 Authentication Bottom Sheet

**Trigger**: User taps "Get Started" on Welcome Screen

**UI Components**:
- Dismissible drag handle (top center)
- Heading: "Sign in to continue" (20sp, bold)
- Subheading: "Save your preferences and track progress" (14sp, grey)
- **Google Button**: "Continue with Google" (Google logo + text, 48dp height)
- **GitHub Button**: "Continue with GitHub" (GitHub logo + text, 48dp height)
- 12dp spacing between buttons
- Terms disclaimer: "By continuing, you agree to our Terms & Privacy Policy" (10sp, grey)

**Phase 1 (Mock Auth) Behaviors**:
```
User taps either button
  ↓
Show loading spinner (2 seconds)
  ↓
Create mock user object:
  {
    userId: "mock_123",
    email: "guest@vaultscapes.dev",
    providerName: "Guest User",
    customName: null,
    authProvider: "google" or "github",
    isAuthenticated: false (mock flag)
  }
  ↓
Save to local storage
  ↓
Navigate to Name Customization Screen (optional)
```

**Phase 2 (Real Auth) Behaviors**:
```
User taps "Continue with Google"
  ↓
Trigger Firebase Google Sign-In flow
  ↓
Receive Firebase User object
  ↓
Extract: email, displayName, photoURL, uid
  ↓
Check if user exists in Firestore
  ↓
If new user: Create Firestore document
If existing: Fetch preferences
  ↓
Navigate to Name Customization Screen (if first-time) or Home Screen
```

**Error Handling**:
- Auth cancellation: Dismiss bottom sheet, return to Welcome Screen
- Auth failure: Show Snackbar "Sign-in failed. Please try again.", keep bottom sheet open
- Network error: Show Snackbar "No internet connection", disable buttons

---

#### 4.1.3 Name Customization Screen (Optional)

**Trigger**: First-time authenticated users after successful OAuth

**UI Components**:
- User avatar placeholder (80x80dp circular)
- Current name display: `providerName` (fetched from Google/GitHub)
- "Customize your name" TextField (max 30 characters)
- Hint text: "This is how you'll appear in the app"
- **Primary CTA**: "Continue" button (saves custom name)
- **Skip CTA**: "Skip for now" text button (uses provider name)

**Behaviors**:
| User Action | System Response |
|-------------|-----------------|
| Edit name + tap "Continue" | Save `customName` to local + Firestore, navigate to Home |
| Tap "Skip for now" | Set `customName = providerName`, navigate to Home |
| Back button press | Disabled (force selection) |

**Validation**:
- Min 2 characters, max 30 characters
- No profanity filter (lean approach)
- Real-time character counter

---

### 4.2 Home Screen & Bottom Navigation

#### 4.2.1 Bottom Navigation Bar

**Persistent Component**: Visible on all main screens (Home, Collaborate, Feedback, Profile)

**Navigation Items** (left to right):
1. **Home** 
   - Icon: `Icons.home` (Material Icons)
   - Label: "Home" (only when selected)
   - Default selected on first navigation

2. **Collaborate**
   - Icon: `Icons.group_add` or `Icons.handshake` (Material Icons)
   - Label: "Collaborate" (only when selected)

3. **Feedback**
   - Icon: `Icons.feedback` (Material Icons)
   - Label: "Feedback" (only when selected)

4. **Profile**
   - Icon: `Icons.person` (Material Icons)
   - Label: "Profile" (only when selected)

**Visual States**:
- **Selected**: Icon + label (primary color #1E88E5)
- **Unselected**: Icon only (grey #757575)
- Height: 56dp
- Icon size: 24dp

**Behavior**:
- Tapping any item navigates to corresponding screen
- Current screen's icon remains highlighted
- No animation delays (instant navigation)

---

#### 4.2.2 Home Screen (WebView)

**URL Logic**:
```
Default URL: 'https://mantavyam.gitbook.io/vaultscapes'

If user has semester preference set:
  URL: 'https://mantavyam.gitbook.io/vaultscapes/sem-{1-8}'
  Example: sem-3 → 'https://mantavyam.gitbook.io/vaultscapes/sem-3'
```

**WebView Configuration**:
- JavaScript enabled: `true`
- DOM storage enabled: `true`
- Zoom controls: `false` (GitBook is responsive)
- Pull-to-refresh: `enabled`
- User Agent: Custom (identifies as VaultScapes App)

**UI Components**:
- Full-screen WebView (fills safe area minus bottom nav bar)
- Loading indicator: Linear progress bar (top edge, primary color)
- Error state: 
  - Icon: `Icons.cloud_off` (64dp, grey)
  - Message: "Unable to load content"
  - Retry button: "Tap to retry"

**Behaviors**:
| User Action | System Response |
|-------------|-----------------|
| Screen loads | Show progress bar, load URL, hide bar when complete |
| Pull down | Refresh WebView content |
| Tap link (internal) | Navigate within WebView |
| Tap link (external) | Open in system browser (ask user first) |
| Back button | Navigate WebView history if exists, else go to previous app screen |
| Change semester in Profile | Reload Home WebView with new URL |

---

#### 4.2.3 Collaborate Screen (WebView)

**URL**: `'https://mantavyam.notion.site/18152f7cde8880d699a5f2e65f87374e?pvs=105'`

**Identical WebView configuration to Home Screen**, except:
- No dynamic URL logic (static Notion form URL)
- Form submissions handled by Notion (no app-side validation)

**Special Handling**:
- If user is authenticated, pre-fill email in form (if Notion allows via URL params)
  - Example: `...?email={userEmail}`
  - Implementation note: Test if Notion supports this

---

#### 4.2.4 Feedback Screen (WebView)

**URL**: `'https://mantavyam.notion.site/17e52f7cde8880e0987fd06d33ef6019?pvs=105'`

**Identical implementation to Collaborate Screen**

---

### 4.3 Profile Screen

#### 4.3.1 Authenticated User View

**Layout Structure**:

**Section 1: User Information**
- Avatar (80x80dp circular)
  - Display initials if no photo (e.g., "JD" for John Doe)
  - Background color: Generated from user ID hash
- Display name (24sp, bold)
  - Editable: Tap pencil icon → TextField appears inline
  - Save on focus loss or "Enter" key
- Email address (14sp, grey, non-editable)
- Horizontal divider (16dp vertical margin)

**Section 2: Quick Links**
- List tiles (48dp height each)
- Format: Icon (leading, 24dp) | Title (16sp) | Chevron right (trailing)

| Link Title | Icon | Target URL |
|------------|------|------------|
| Search Database | `Icons.search` | `https://mantavyam.gitbook.io/vaultscapes?q=` |
| GitHub Repository | `Icons.code` | `https://github.com/mantavyam/vaultscapesDB` |
| Discord Community | Custom Discord icon | `https://discord.com/invite/AQ7PNzdCnC` |
| How to Use Database | `Icons.help_outline` | `https://mantavyam.gitbook.io/vaultscapes/how-to-use-database` |
| How to Collaborate | `Icons.people_outline` | `https://mantavyam.gitbook.io/vaultscapes/how-to-collaborate` |
| Collaborators | `Icons.groups` | `https://mantavyam.gitbook.io/vaultscapes/collaborators` |

**Behavior**: Tap any link → Navigate to new screen with WebView (includes back button in AppBar)

**Section 3: Settings**
- Horizontal divider
- **Semester Preference** setting
  - Display: "Semester: {selected}" (16sp)
  - Tap → Opens dropdown modal
  - Options: "Default", "Sem 1", "Sem 2", ..., "Sem 8"
  - Current selection has checkmark icon
  - On selection: Save to local storage + Firestore (Phase 2), refresh Home WebView
  
**Section 4: Account Actions**
- Horizontal divider
- **Logout Button** (text button, red color)
  - Tap → Confirmation dialog: "Are you sure you want to log out?"
  - Confirm → Clear local storage, navigate to Welcome Screen

---

#### 4.3.2 Guest User View

**Layout Structure**:

**Section 1: Call to Action**
- Generic avatar (80x80dp, grey placeholder)
- "Welcome, Guest!" (24sp, bold)
- Subtext: "Sign in to save your preferences" (14sp, grey)
- **"Create Profile" button** (filled, primary color, full width minus 32dp margins)
- **"Login" button** (outlined, secondary color, same width)
- 12dp spacing between buttons
- Horizontal divider (24dp vertical margin)

**Behavior**:
- Tap either button → Navigate to Welcome Screen → Open Auth Bottom Sheet

**Section 2: Quick Links**
- Identical to authenticated view (all 6 links accessible)

**Section 3: Settings**
- **Not visible** in guest mode
- Settings only appear after authentication

---

#### 4.3.3 Special Screen: Search with Keyboard Trigger

**Trigger**: User taps "Search Database" in Profile Screen

**Implementation**:
```
Navigate to new screen with:
- AppBar with "Search" title
- TextField (autofocus: true, keyboard auto-opens)
- WebView below TextField (initially loads base search URL)

User types query in TextField
  ↓
On submit (keyboard "Go" button or search icon):
  ↓
Construct URL: 'https://mantavyam.gitbook.io/vaultscapes?q={encodedQuery}'
  ↓
Load URL in WebView below
  ↓
Keyboard dismisses, WebView displays results
```

**Alternative Simpler Implementation**:
```
Navigate directly to WebView with search URL
  ↓
WebView loads GitBook search page
  ↓
Use JavaScript injection to focus search input:
  webViewController.runJavaScript('document.querySelector("input[type=search]").focus();');
  ↓
Keyboard opens automatically (GitBook's native search)
```

**Recommendation**: Use Alternative (simpler, leverages GitBook's existing search UX)

---

### 4.4 URL Management System

#### 4.4.1 URLService Class (Conceptual)

**Responsibility**: Centralize all URL logic and construction

**Core Methods**:

```
getHomeURL(int? semesterPreference)
  ↓
  If semesterPreference is null or 0:
    return 'https://mantavyam.gitbook.io/vaultscapes'
  Else:
    return 'https://mantavyam.gitbook.io/vaultscapes/sem-{semesterPreference}'

getSearchURL(String query)
  ↓
  return 'https://mantavyam.gitbook.io/vaultscapes?q={Uri.encodeComponent(query)}'

getCollaborateURL()
  ↓
  return 'https://mantavyam.notion.site/18152f7cde8880d699a5f2e65f87374e?pvs=105'

getFeedbackURL()
  ↓
  return 'https://mantavyam.notion.site/17e52f7cde8880e0987fd06d33ef6019?pvs=105'

getQuickLinkURL(QuickLinkType type)
  ↓
  switch (type):
    case GITHUB: return 'https://github.com/mantavyam/vaultscapesDB'
    case DISCORD: return 'https://discord.com/invite/AQ7PNzdCnC'
    case HOW_TO_USE: return 'https://mantavyam.gitbook.io/vaultscapes/how-to-use-database'
    case HOW_TO_COLLABORATE: return 'https://mantavyam.gitbook.io/vaultscapes/how-to-collaborate'
    case COLLABORATORS: return 'https://mantavyam.gitbook.io/vaultscapes/collaborators'
```

**Usage Example**:
```
// In Home Screen
final url = URLService.getHomeURL(userPreferences.semesterPreference);
webViewController.loadRequest(Uri.parse(url));
```

---