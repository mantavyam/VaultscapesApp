# Overview
## Vaultscapes Mobile Application

---

## 1. Product Overview & Objectives

### 1.1 Product Vision
Vaultscapes is a mobile-first educational resource aggregation platform designed to provide BTech students with seamless access to semester-wise academic materials, including notes, assignments, previous year questions, and curated learning resources.

### 1.2 Core Value Proposition
- **Centralized Access**: Single platform for all academic resources across 8 semesters
- **Structured Navigation**: Hierarchical organization (Semester → Subject → Module → Resources)
- **Flexible Onboarding**: Guest exploration or authenticated personalized experience
- **Community-Driven**: Built-in feedback and collaboration mechanisms

### 1.3 Target Users
- **Primary**: BTech undergraduate students (Semesters 1-8)
- **Secondary**: Faculty, alumni, and academic staff
- **Tertiary**: Prospective students exploring course structure

### 1.4 Success Metrics
- User engagement (daily/weekly active users)
- Resource download/view counts
- Feedback submission rate
- Collaboration contributions per semester
- Guest-to-authenticated user conversion rate
- Average session duration
- Homepage preference adoption rate

---

## 5. Development Phases & Acceptance Criteria

### 5.1 Phase 1: MVP (Core Functionality with Mock Auth)

#### 5.1.1 Deliverables
1. **Onboarding & Navigation**
   - Welcome screen with "Get Started" and "Explore" buttons
   - Mock authentication with 2-second loading
   - Bottom navigation with 4 tabs
   - Guest mode functionality

2. **HOME Section**
   - Root homepage with 8 semester cards
   - Semester overview screen with collapsible sections
   - Subject detail screen with tabbed layout
   - PDF download functionality (using external browser/PDF viewer)

3. **ALPHASIGNAL.AI Section**
   - WebView implementation with loading indicator
   - Pull-to-refresh functionality
   - Error handling for network failures

4. **SYNERGY Section** (formerly Feedback + Collaborate)
   - Two-tab layout
   - Complete feedback form with all fields
   - Complete collaboration form with file upload
   - Form validation and submission (mock API)

5. **PROFILE Section**
   - Guest view with "Create Profile" CTA
   - Authenticated view with profile card
   - Homepage preference setting (functional)
   - Quick links to external resources

#### 5.1.2 Acceptance Criteria

**AC-1.1: Welcome Screen**
- [ ] Screen displays Vaultscapes branding
- [ ] "Get Started" and "Explore" buttons are clearly visible
- [ ] Button tap animations work smoothly
- [ ] Complies with shadcn_flutter design system

**AC-1.2: Mock Authentication**
- [ ] Bottom sheet slides up on "Get Started" tap
- [ ] Loading indicator displays for 2 seconds
- [ ] Mock user created with unique UID
- [ ] Navigation to main screen occurs after authentication

**AC-1.3: Bottom Navigation**
- [ ] All 4 tabs are visible and labeled correctly
- [ ] Active tab is highlighted
- [ ] Tab switching preserves scroll position
- [ ] Icons match specified design (Home, Brain, MessageSquare, User)

**AC-1.4: Root Homepage**
- [ ] 8 semester cards displayed in grid/list layout
- [ ] Cards show semester number and description
- [ ] Tap on card navigates to semester overview
- [ ] Search icon in app bar (functional in Phase 2)

**AC-1.5: Semester Overview**
- [ ] Back button navigates to root homepage
- [ ] All 7 sections (Syllabus, Exam Schedule, etc.) render correctly
- [ ] Accordion expands/collapses smoothly
- [ ] Subject cards navigate to subject detail screen
- [ ] Download buttons open PDFs in external viewer

**AC-1.6: Subject Detail Screen**
- [ ] All 5 tabs render (Syllabus, Resources, Notes, Questions, External)
- [ ] Module accordion expands with notes/videos
- [ ] YouTube links open in external app/browser
- [ ] PDF downloads function correctly

**AC-1.7: WebView**
- [ ] Alphasignal URL loads completely
- [ ] Loading indicator dismisses after page load
- [ ] Pull-to-refresh reloads page
- [ ] Network error displays error widget with retry button

**AC-1.8: Feedback Form**
- [ ] All 11 form fields render correctly
- [ ] Radio groups, checkboxes, and dropdowns function
- [ ] File picker allows selection of up to 5 files
- [ ] Form validation prevents submission with missing required fields
- [ ] Submit button shows loading state
- [ ] Toast confirmation appears on successful submission

**AC-1.9: Collaboration Form**
- [ ] All 10 form fields render correctly
- [ ] Conditional credit name field appears/disappears based on YES/NO selection
- [ ] File upload supports 10 files, 5MB each
- [ ] Submit triggers success toast

**AC-1.10: Profile (Guest Mode)**
- [ ] Generic avatar and "browsing as guest" text displayed
- [ ] "Create Profile / Login" button opens auth bottom sheet
- [ ] Quick links section functional

**AC-1.11: Profile (Authenticated Mode)**
- [ ] Profile picture, email, and name display correctly
- [ ] Name edit dialog opens on tap
- [ ] Homepage preference dropdown saves selection
- [ ] All quick links open in WebView/external browser
- [ ] Logout button displays confirmation dialog

#### 5.1.3 Testing Requirements
- [ ] Unit tests for data models and repositories
- [ ] Widget tests for all custom components
- [ ] Integration tests for complete user flows
- [ ] Manual testing on Android and iOS devices
- [ ] Accessibility testing (screen reader, contrast)
- [ ] Performance testing (app size, load times)

---

### 5.2 Phase 2: Real Authentication & Backend Integration

#### 5.2.1 Deliverables
1. **Google OAuth Integration**
   - Firebase Authentication setup
   - Google Sign-In flow
   - User profile sync with backend
   - Logout functionality

2. **Backend API Integration**
   - RESTful API for content fetching
   - Feedback/collaboration submission endpoints
   - User preferences sync
   - Analytics tracking

3. **Enhanced Features**
   - Search functionality (GitBook search API)
   - Push notifications (optional)
   - Offline mode with cached content
   - Content refresh mechanism

#### 5.2.2 Acceptance Criteria

**AC-2.1: Google OAuth**
- [ ] "Continue with Google" button functional
- [ ] User can authorize app via Google consent screen
- [ ] User data (email, name, photo) fetched correctly
- [ ] New user profile created in backend database
- [ ] Returning user data loaded from backend

**AC-2.2: Backend Integration**
- [ ] Content API returns semester/subject data
- [ ] Feedback submissions persist in database
- [ ] Collaboration submissions persist with file uploads
- [ ] User preferences sync across devices
- [ ] Error handling for API failures

**AC-2.3: Search Functionality**
- [ ] Search icon in HOME app bar opens search overlay
- [ ] Search queries sent to GitBook API
- [ ] Results displayed in list format
- [ ] Tap on result navigates to relevant page

#### 5.2.3 Testing Requirements
- [ ] End-to-end testing with real Google accounts
- [ ] API integration tests with mock servers
- [ ] Load testing for concurrent users
- [ ] Security audit (authentication, data storage)

---

### 5.3 Phase 3: Advanced Features (Future Scope)

#### 5.3.1 Potential Features
- Admin dashboard for content management
- User-generated content moderation system
- Bookmarking and favorites
- Collaborative note-taking
- In-app chat/discussion forums
- Dark mode support
- Multilingual support
- Accessibility improvements (font scaling, voice navigation)

---


## 8. Success Criteria Summary

### 8.1 Phase 1 Success Metrics
- [ ] App builds successfully on Android and iOS
- [ ] All acceptance criteria pass
- [ ] No critical bugs in core flows
- [ ] Performance benchmarks met
- [ ] Positive feedback from 5 beta testers

### 8.2 Phase 2 Success Metrics
- [ ] 100% of users can authenticate successfully
- [ ] Backend API response time < 500ms
- [ ] Feedback/collaboration submission success rate > 95%
- [ ] User retention rate > 60% after 7 days

### 8.3 Long-Term Success Metrics (6 months)
- 1,000+ active users
- 500+ resource downloads per week
- 50+ collaboration submissions
- 4+ star rating on app stores
- < 1% crash rate

---

## 9. Appendix

### 9.1 Glossary
- **PYQ**: Previous Year Questions
- **CTA**: Call to Action
- **MVP**: Minimum Viable Product
- **OAuth**: Open Authorization (authentication protocol)
- **WebView**: Embedded browser component
- **Guest Mode**: Using app without authentication

### 9.2 References
- shadcn_flutter Documentation: https://sunarya-thito.github.io/shadcn_flutter/
- shadcn_flutter pub.dev: https://pub.dev/packages/shadcn_flutter
- GitBook Content Space Hosting Content: https://mantavyam.gitbook.io/vaultscapes
- GitBook Documentation to Understand Blocks created by Gitbook in Markdown: https://gitbook.com/docs/creating-content/blocks
- Flutter Documentation: https://docs.flutter.dev/

### 9.3 Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-17 | Development Team | Initial PRD |

---

**End of Document**