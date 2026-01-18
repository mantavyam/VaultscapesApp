## 2. Functional Requirements

### 2.1 Onboarding & Authentication

#### 2.1.1 Initial Launch Screen
**Components:**
- Hero section with Vaultscapes branding
- Two primary CTAs:
  - **"Get Started"** (Primary button)
  - **"Explore"** (Secondary/Ghost button)

**User Flows:**

**Flow A: "Get Started" Path**
1. User taps "Get Started"
2. Bottom sheet slides up with authentication options
3. **Phase 1 (MVP)**: Mock authentication with loading indicator (2-3 seconds)
4. **Phase 2**: "Continue with Google" OAuth integration
5. Post-authentication:
   - **New Users**: Optional profile customization screen
     - Display name fetched from provider (editable)
     - Skip option available
   - **Returning Users**: Direct navigation to Home
6. Navigate to Bottom Navigation interface

**Flow B: "Explore" Path**
1. User taps "Explore"
2. Immediate navigation to Bottom Navigation interface (Guest Mode)
3. Limited Profile functionality (prompts for authentication)

#### 2.1.2 Authentication Data Model
```
User {
  uid: String (unique identifier)
  email: String (from provider, non-editable)
  displayName: String (from provider, initial value)
  customName: String (optional, user-editable)
  profilePictureUrl: String (from provider)
  homepagePreference: String (default: 'root', options: 'root', 'sem-1' through 'sem-8')
  createdAt: DateTime
  lastLoginAt: DateTime
  isGuest: Boolean
}
```

### 2.2 Bottom Navigation Architecture

#### 2.2.1 Navigation Structure
Four-tab bottom navigation bar (persistent across authenticated/guest modes):

1. **HOME** (Icon: Home/Dashboard)
2. **ALPHASIGNAL.AI** (Icon: Brain/AI)
3. **FEEDBACK + COLLABORATE** (Icon: MessageSquare/Handshake)
4. **PROFILE** (Icon: User/Account)

#### 2.2.2 Navigation Behavior
- Active tab highlighted with accent color
- Tab switching preserves scroll position within each section
- Deep linking support for direct navigation to specific semesters/subjects

---

### 2.3 HOME Section

#### 2.3.1 Root Homepage (Default View)
**Layout:**
- App Bar with Vaultscapes branding and search icon
- Greeting based on time of day (authenticated users) or generic welcome (guests)
- Grid/List of semester cards (Semester 1 through Semester 8)

**Semester Card Components (shadcn_flutter):**
- `Card` widget with `CardImage` for semester thumbnail
- `CardTitle`: "Semester X"
- `CardDescription`: Brief summary (e.g., "Foundational Courses")
- Navigation arrow/chevron icon
- Tap interaction navigates to Semester Overview Page

#### 2.3.2 Semester Overview Page
**Structure:**
- `AppBar` with back button, semester title, and share icon
- Collapsible sections using `Accordion` or `Collapsible` components:

**Section 1: Syllabus**
- Download button for semester syllabus PDF
- Uses `Button` with download icon

**Section 2: Exam Schedule (Optional)**
- Conditional rendering if data exists
- Display as `Timeline` or `Table` component

**Section 3: Subject Wise Resources**
- Two subsections using nested `Accordion`:
  - **General/Core Subjects**: List of 6 core subjects
  - **Specialisation Subjects**: List of 4 specialization subjects (if applicable)
- Each subject as a tappable `Card` or list item navigating to Subject Page

**Section 4: Notes**
- `Chip` tags for note categories (Short Notes, Mid-Sem, End-Sem, One-shot)
- Download links using `Button` with file type icons

**Section 5: Assignments**
- List of assignment PDFs with download functionality
- Optional solutions displayed with `Badge` ("Solution Available")

**Section 6: Previous Year Questions**
- Nested `Tabs` for Mid-Sem PYQ and End-Sem PYQ
- Filterable by subject and year using `Select` dropdowns
- Download buttons for each PDF

**Section 7: Back Papers (Optional)**
- Similar structure to PYQs

#### 2.3.3 Subject Page
**Layout:**
- `AppBar` with subject code and name
- `TabList` with the following tabs:

**Tab 1: Syllabus**
- Syllabus PDF download button
- Reference links as external link buttons

**Tab 2: Resources**
- `Accordion` for 5 modules:
  - Module header shows module number and topic
  - Expanded view shows:
    - Lecture notes download links
    - YouTube video embeds/links (open in-app or external)
    - Subtopic list with `Chip` tags

**Tab 3: Notes**
- Categorized note downloads (Short Notes, Summaries)

**Tab 4: Questions Directory**
- Nested structure:
  - Question Bank download
  - Assignments (collapsible list)
  - PYQs (Mid-Sem, End-Sem, Back Papers)
  - Expected Questions (optional)

**Tab 5: External Sources (Optional)**
- Book links and tutorial website buttons

#### 2.3.4 Homepage Preference Override
**Implementation:**
- Setting stored in `User.homepagePreference`
- Available in Profile section
- Uses `Select` dropdown with options:
  - "Root Homepage (Default)"
  - "Semester 1" through "Semester 8"
- On app launch, check preference:
  ```
  if (user.isAuthenticated && user.homepagePreference != 'root') {
    navigateToSemester(user.homepagePreference)
  } else {
    navigateToRootHomepage()
  }
  ```

---

### 2.4 ALPHASIGNAL.AI Section

#### 2.4.1 WebView Implementation
**Requirements:**
- Full-screen WebView displaying `https://alphasignal.ai/last-email`
- Loading indicator using `CircularProgress` or `LinearProgress` until content loads
- Pull-to-refresh functionality using `RefreshTrigger`
- Browser controls:
  - Refresh button in AppBar
  - Share button to share URL
  - "Open in Browser" option in overflow menu (`DropdownMenu`)

#### 2.4.2 Error Handling
- Network error state with retry button
- Timeout handling (15 seconds)
- Fallback message with support contact

---

### 2.5 FEEDBACK + COLLABORATE Section

#### 2.5.1 Layout Structure
**Two-Big Squircle Card interface vertically stacked:** (TODO: Undo Tablist approach)
- Tab 1: PROVIDE FEEDBACK
- Tab 2: COLLABORATE NOW

#### 2.5.2 Tab 1: PROVIDE FEEDBACK Form

**Form Fields (using shadcn_flutter components):**

# Feedback Form | Vaultscapes
Vaultscapes is an Open-Source Academic Resource Database.

**Hi, I'm_____________**
Enter Your Name:
→ Component: **Text Input**

**Email ID**
Email will only be used to respond to your feedback! We respect your privacy.
→ Component: **Text Input** (with use of basic email format validation)

**Select Your Role**
(Respondents can select up to 1)
- Student
- Faculty
- Alumni
- Staff
- Others
→ Component: **Radio Group** or **Select**

**How often do you use Vaultscapes?**
(Respondents can select as many as they like)
- Daily
- Weekly
- Once in a Month
- Exam Time Only
- Amateur New User
→ Component: **Multi Select** or **Checkbox** group

**Which semester are you providing feedback about?**
(Respondents can select up to 1)
- Semester 1 / BTECH
- Semester 2 / BTECH
- Semester 3 / BTECH
- Semester 4 / BTECH
- Semester 5 / BTECH
- Semester 6 / BTECH
- Semester 7 / BTECH
- Semester 8 / BTECH
→ Component: **Select** or **Radio Group**

**What type of feedback are you providing?**
(Respondents can select up to 1)
- Grievance (eg Broken/Incorrect Links or Missing/Incorrect Resource)
- Improvement Suggestion (eg Additional Resources or New Feature Ideas)
- General Feedback (eg User feedback or overall satisfaction)
- Technical Issues (eg Navigation Issues or Unresponsiveness)
→ Component: **Radio Group** or **Select**

**Please describe your feedback in detail**
Provide as much detail as possible about the issue, suggestion, or comment.
→ Component: **Text Area**

**Enter the Link to the Page:**
Copy and Paste the URL of Web-Page you're having issues with.
→ Component: **Text Input**

**Attach Files & media (Optional)**
Screen Shots/Recordings will help us identify the issue faster.
→ Component: **Custom File Picker** (not in shadcn_flutter - need native Flutter implementation)

**How would you Rate the overall usability of Vaultscapes?**
(Optional)
(Respondents can select as many as they like where 5 being very easy and 1 being very hard)
- 5
- 4
- 3
- 2
- 1
→ Component: **Star Rating** or **Radio Group** or **Slider**

**Submit Button**
 - Primary `Button` with loading state
 - Success `Toast` notification on submission
 - `AlertDialog` for confirmation

#### 2.5.3 Tab 2: COLLABORATE NOW Form

**Form Fields (using shadcn_flutter components):**

# Collaborate on Vaultscapes

**What are you submitting?**
(Respondents can select as many as they like)
- Notes
- Assignment
- Lab Manual (Expt)
- Question Bank
- Exam Papers (PYQ)
- Code Examples
- External Link / Sources
→ Component: **Multi Select** or **Checkbox** group

**What is the source of your submission?**
- Self Written
- Internet Document/Resource
- Faculty Provided Material
- AI-Assisted Human-guided Content
→ Component: **Radio Group** or **Select**

**For which semester are you submitting this resource?**
(Respondents can select up to 1)
- Semester 1 / BTECH
- Semester 2 / BTECH
- Semester 3 / BTECH
- Semester 4 / BTECH
- Semester 5 / BTECH
- Semester 6 / BTECH
- Semester 7 / BTECH
- Semester 8 / BTECH
→ Component: **Select** or **Radio Group**

**What is the subject name and code?**
(E.g., Computer Science - CS101)
→ Component: **Text Input**

**Attach (Field 1): Please attach your files here**
You can upload 10 files at a time with a size Limit of 5 mb
→ Component: **Custom File Picker** (not in shadcn_flutter - need native Flutter implementation)

**Attach (Field 2): Optional for URL Submission**
→ Component: **Text Input**

**Describe your submission.**
(A Short explanation of what this resource contains or why it's useful.)
→ Component: **Text Area**

**Would you like to be credited for this submission on Vaultscapes?**
[YES] [NO]
→ Component: **Switch** or **Radio Group**

**If yes, please provide the name or details you'd like to be credited with.**
(E.g., Full Name, Email, Social Media Handle, or "Anonymous")
→ Component: **Text Input**

**Optional Notes for Admins**
Any additional notes or information you'd like to share with us?
→ Component: **Text Area**

**Submit Button**
 - Primary `Button` with loading state
 - Success `Toast` notification
 - `AlertDialog` for confirmation

---

**Note:** The shadcn_flutter package doesn't include a file picker component, so you'll need to use Flutter's native file picker packages like file_picker or image_picker for file upload functionality.

### 2.6 PROFILE Section

#### 2.6.1 Authenticated User View

**Profile Card (using `Card` component):**
- Profile picture (circular `Avatar` from provider)
- Email address (read-only, from provider)
- Display name with edit icon
  - Tap to open `Dialog` with `TextInput` for name editing
  - Save/Cancel buttons

**Settings Section:**

**Homepage Preference**
- `Card` with title "Default Homepage"
- `Select` dropdown:
  - Options: "Root Homepage", "Semester 1" through "Semester 8"
  - Helper text: "Skip navigation by setting your default semester"
- Auto-save on selection change with `Toast` confirmation

**Quick Links Section (`Card` with list items):**
Each link opens in WebView or external browser:

1. **Open Search**
   - Opens: `https://mantavyam.gitbook.io/vaultscapes?q=`
   - Triggers keyboard with search input overlay
   - Icon: Search/Magnifying glass

2. **GitHub**
   - URL: `https://github.com/mantavyam/vaultscapesDB`
   - Icon: GitHub logo

3. **Discord**
   - URL: `https://discord.com/invite/AQ7PNzdCnC`
   - Icon: Discord logo

4. **How to Use Database?**
   - URL: `https://mantavyam.gitbook.io/vaultscapes/how-to-use-database`
   - Icon: Help Circle

5. **How to Collaborate?**
   - URL: `https://mantavyam.gitbook.io/vaultscapes/how-to-collaborate`
   - Icon: Users/Group

6. **Collaborators**
   - URL: `https://mantavyam.gitbook.io/vaultscapes/collaborators`
   - Icon: Award/Star

7. **Privacy Policy**
   - URL: `https://mantavyam.gitbook.io/vaultscapes/privacy-policy`
   - Icon: Shield

8. **Terms of Service**
   - URL: `https://mantavyam.gitbook.io/vaultscapes/terms-of-service`
   - Icon: File Text

**Logout Button:**
- Destructive `Button` at bottom
- `AlertDialog` confirmation before logout

#### 2.6.2 Guest User View
**Components:**
- Generic avatar placeholder
- Text: "You're browsing as a guest"
- Primary `Button`: "Create Profile / Login"
  - Opens authentication bottom sheet (same as "Get Started" flow)

**Quick Links Section:**
- Same as authenticated view (links don't require authentication)

---

## 7. Non-Functional Requirements

### 7.1 Performance
- App launch time: < 2 seconds
- Screen transition animations: 60 FPS
- WebView load time: < 5 seconds (dependent on network)
- PDF download initiation: < 1 second

### 7.2 Compatibility
- **Android**: API Level 24+ (Android 7.0+)
- **iOS**: iOS 12.0+
- **Flutter**: 3.16.0+

### 7.3 Accessibility
- Screen reader support (TalkBack, VoiceOver)
- Minimum touch target size: 48x48 dp
- Color contrast ratio: WCAG AA compliance
- Text scaling support (up to 200%)

### 7.4 Security
- HTTPS for all network requests
- Secure storage for authentication tokens
- Input validation and sanitization
- No hardcoded sensitive credentials

### 7.5 Analytics (Phase 2)
- Screen view tracking
- User engagement metrics (session duration, features used)
- Error logging (Crashlytics, Sentry)
- Feedback submission rates

---