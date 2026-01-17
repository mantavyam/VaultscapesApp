## 4. User Experience Flows

### 4.1 First-Time User Journey

```
App Launch
    ↓
Welcome Screen (Get Started / Explore)
    ↓
[User chooses "Get Started"]
    ↓
Bottom Sheet: Authentication Options
    ↓
[Mock Auth Loading - Phase 1]
    ↓
Profile Setup Screen (Optional)
    ↓
Main Navigation Screen (HOME tab active)
    ↓
Root Homepage (Grid of semester cards)
    ↓
[User selects "Semester 3"]
    ↓
Semester Overview Screen
    ↓
[User taps "Subject Wise Resources"]
    ↓
Expands Accordion → Taps "CS301 / Data Structures"
    ↓
Subject Detail Screen (Resources tab)
    ↓
[User expands "Module 2: Trees"]
    ↓
Downloads lecture notes PDF
    ↓
[User navigates to "Questions Directory" tab]
    ↓
Downloads Mid-Sem PYQ
```

### 4.2 Returning User Journey (with Homepage Preference)

```
App Launch
    ↓
[Check user.homepagePreference = "sem-5"]
    ↓
Directly navigate to Semester 5 Overview Screen
    ↓
[User navigates to ALPHASIGNAL.AI tab]
    ↓
WebView loads https://alphasignal.ai/last-email
    ↓
[User scrolls, refreshes content]
    ↓
[User switches to FEEDBACK + COLLABORATE tab]
    ↓
Taps "COLLABORATE NOW" tab
    ↓
Fills form, uploads assignment PDF
    ↓
Submits → Toast confirmation
```

### 4.3 Guest User Journey

```
App Launch
    ↓
Welcome Screen
    ↓
[User chooses "Explore"]
    ↓
Main Navigation Screen (HOME tab active)
    ↓
Browses semesters, downloads resources
    ↓
[User switches to PROFILE tab]
    ↓
Sees "Create Profile / Login" button
    ↓
[User decides to authenticate]
    ↓
Taps button → Bottom Sheet opens
    ↓
Mock Auth Flow
    ↓
Profile Setup → Authenticated state
```

### 4.4 Profile Customization Flow

```
Main Navigation Screen (PROFILE tab)
    ↓
[User taps edit icon next to name]
    ↓
Dialog opens with TextInput
    ↓
User enters custom name
    ↓
Taps "Save" → Updates locally & syncs to backend
    ↓
Toast confirmation: "Profile updated"
    ↓
[User scrolls to "Default Homepage" setting]
    ↓
Opens dropdown, selects "Semester 6"
    ↓
Auto-saves → Toast: "Homepage preference saved"
    ↓
Next app launch will open Semester 6 directly
```

### 4.5 Feedback Submission Flow

```
FEEDBACK + COLLABORATE tab
    ↓
"PROVIDE FEEDBACK" tab active
    ↓
User fills form:
    - Name: Auto-populated (if authenticated)
    - Email: Auto-populated
    - Role: Selects "Student"
    - Frequency: Checks "Daily" + "Exam Time Only"
    - Semester: Selects "Semester 4"
    - Type: Selects "Grievance"
    - Description: Types issue details
    - URL: Pastes broken link
    - Attaches screenshot
    - Rates usability: 4 stars
    ↓
Taps "Submit"
    ↓
Button shows loading spinner
    ↓
[Backend API call]
    ↓
Success → Toast: "Feedback submitted successfully!"
    ↓
Form resets
```

---