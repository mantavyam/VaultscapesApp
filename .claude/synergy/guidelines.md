# Vaultscapes Form Design Specification
**For: Flutter Developer | Using: shadcn_flutter | Scope: Feedback & Collaborate Forms**

---

## 1. Design Philosophy

These forms follow **minimal cognitive load principles**. Every element serves a functional purpose. Visual hierarchy is created through **spacing, not decoration**. Users should complete forms in **three mental steps**: (1) Identity, (2) Context, (3) Action.

---

## 2. Global Constants (Copy-Paste to `lib/core/form_constants.dart`)

```dart
import 'package:flutter/widgets.dart';

class FormConstants {
  // 8-Point Grid System
  static const double spaceXS = 4.0;   // Icon-to-text, checkbox spacing
  static const double spaceSM = 8.0;   // Label-to-input, radio offset
  static const double spaceMD = 16.0;  // Field pairs, internal padding
  static const double spaceLG = 24.0;  // Card padding
  static const double spaceXL = 32.0;  // Major section separation
  static const double spaceXXL = 48.0; // Critical: Last field to submit button
  static const double spaceXXXL = 64.0; // Page header to form start

  // Component Dimensions
  static const double inputHeight = 56.0;
  static const double buttonHeight = 56.0;
  static const double minTouchTarget = 48.0;
  static const double borderRadius = 8.0;
  static const double cardRadius = 12.0;
  static const double sectionRadius = 16.0;

  // Icon Sizing Rule: 0.9× capital letter height
  static const double iconInline = 20.0; // Inside input fields
  static const double iconCard = 48.0;   // Section headers

  // Color Palette (Functional)
  static const Color primary = Color(0xFF0EA5E9); // sky-500
  static const Color primaryLight = Color(0xFFF0F9FF); // sky-50
  
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color error = Color(0xFFEF4444); // red-500
  
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
}
```

---

## 3. Page Structure Template

```dart

Scaffold(
  backgroundColor: FormConstants.slate50,
  appBar: AppBar(
    title: const Text('Provide Feedback'), // Or 'Collaborate on Vaultscapes'
    backgroundColor: Colors.white,
    elevation: 1,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => _handleBackNavigation(context),
    ),
  ),
  body: SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640.0),
        child: Padding(
          padding: const EdgeInsets.all(FormConstants.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form header
              _buildFormHeader(),
              const SizedBox(height: FormConstants.spaceXXXL),
              
              // Group 1: Identity
              _buildSection1(),
              const SizedBox(height: FormConstants.spaceXL),
              
              // Group 2: Context
              _buildSection2(),
              const SizedBox(height: FormConstants.spaceXL),
              
              // Group 3: Details
              _buildSection3(),
              const SizedBox(height: FormConstants.spaceXL),
              
              // Group 4: Final action
              _buildSection4(),
              const SizedBox(height: FormConstants.spaceXXL),
              
              // Submit button (isolated)
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    ),
  ),
)
```

---

## 4. Component Specifications

### A. Text Input Field (Name, Email, Subject Code, URL)

**Anatomy:**
```dart
ShadInput(
  placeholder: const Text('Enter Your Name'),
  style: const TextStyle(fontSize: FormConstants.fontInput),
  decoration: ShadDecoration(
    label: Text(
      'Hi, I\'m',
      style: TextStyle(
        fontSize: FormConstants.fontLabel,
        fontWeight: FontWeight.w500,
        color: FormConstants.slate700,
      ),
    ),
    helper: Text(
      'Email will only be used to respond to your feedback!',
      style: TextStyle(
        fontSize: FormConstants.fontHelper,
        color: FormConstants.slate500,
      ),
    ),
  ),
)
```

**Specs:**
- Height: **56px** fixed
- Horizontal padding: **16px**
- Border radius: **8px**
- Label position: **Above field** (never placeholder-only)
- Helper text: **8px** below input
- Icon (if any): **20px**, color: slate-400, positioned 12px from right edge
- **States:**
  - Default: Border: slate-300, 1px
  - Focused: Border: sky-500, 2px, Background: sky-50
  - Error: Border: red-500, 2px, Background: red-50, Helper text turns red-600
  - Disabled: Background: slate-100, Border: slate-200

---

### B. Radio Group (Role, Semester, Feedback Type, Source)

```dart
ShadRadioGroup<String>(
  initialValue: selectedRole,
  onChanged: (value) => setState(() => selectedRole = value),
  items: [
    ShadRadio(value: 'student', label: const Text('Student')),
    ShadRadio(value: 'faculty', label: const Text('Faculty')),
    // ... other options
  ],
)
```

**Specs:**
- **Vertical spacing between items: 12px**
- Radio button size: **20px**
- Label offset: **8px** from button
- Entire row is tappable (wrap in InkWell)
- Selected state: Button fill: primary, Label: slate-900, weight: 500
- Unselected: Button stroke: slate-300, Label: slate-700

---

### C. Checkbox / Multi-Select Group (Usage Frequency, Submission Types)

```dart
// Use Wrap for multi-column layout
Wrap(
  spacing: FormConstants.spaceMD,
  runSpacing: FormConstants.spaceSM,
  children: usageOptions.map((option) => ShadCheckbox(
    value: selectedOptions.contains(option),
    onChanged: (checked) => _toggleOption(option, checked),
    label: Text(option, style: const TextStyle(fontSize: FormConstants.fontInput)),
  )).toList(),
)
```

**Specs:**
- **Item height: 48px** (touch target)
- Checkbox size: **20px**
- Spacing from label: **8px**
- Selected background (optional): slate-100 with 8px padding
- **Column count:** Mobile: 1, Tablet: 2, Desktop: 3

---

### D. Select/Dropdown (Semester - alternative to radio)

```dart
ShadSelect<String>(
  placeholder: const Text('Select Semester'),
  options: semesters.map((s) => ShadOption(value: s, child: Text(s))).toList(),
  selectedOptionBuilder: (context, value) => Text(value),
)
```

**Specs:**
- Height: **56px** (match text inputs exactly)
- Trailing icon: `Icons.expand_more`, **24px**, color: slate-400
- Menu elevation: **4**
- Max menu height: **200px** (scroll after)
- Selected item: Background: primaryLight, Checkmark icon: primary

---

### E. Text Area (Description, Admin Notes)

```dart
ShadTextarea(
  maxLines: 4,
  minLines: 4,
  maxLength: 1000,
  placeholder: const Text('Provide as much detail as possible...'),
  decoration: ShadDecoration(
    counter: ShadCounter(
      builder: (context, length) => Text(
        '$length/1000',
        style: TextStyle(fontSize: FormConstants.fontHelper, color: FormConstants.slate500),
      ),
    ),
  ),
)
```

**Specs:**
- Min height: **120px**
- Max height: **240px** (auto-expand)
- Padding: **16px** all sides
- Border specs identical to text input
- Counter: **Bottom-right**, 12px, slate-400
- Character limit: Show counter only after 500 chars typed

---

### F. Star Rating Component (Custom - not in shadcn)

```dart
// Create lib/widgets/star_rating.dart
class StarRating extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          icon: Icon(
            starValue <= value ? Icons.star : Icons.star_border,
            size: 32.0, // Critical size
            color: starValue <= value ? FormConstants.warning : FormConstants.slate300,
          ),
          onPressed: () => onChanged(starValue),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: FormConstants.minTouchTarget),
        );
      }),
    );
  }
}
```

**Specs:**
- Star size: **32px**
- Active color: amber-500, Inactive: slate-300
- Spacing between stars: **4px**
- Include label below: ["Very Hard", "Hard", "Neutral", "Easy", "Very Easy"] - map to 1-5 stars
- Touch target: **48px** minimum per star

---

### G. Switch (Credit Toggle)

```dart
ShadSwitch(
  value: creditEnabled,
  onChanged: (value) => setState(() => creditEnabled = value),
  label: const Text('Would you like to be credited?'),
)
```

**Specs:**
- Track width: **48px**, height: **28px**
- Thumb size: **24px**
- Active: Track: primary, Thumb: white
- Inactive: Track: slate-300, Thumb: white
- Label spacing: **12px** to the right

---

### H. File Picker (Custom Implementation)

```dart
// Create lib/widgets/file_picker.dart
class FilePickerField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        height: 120.0,
        decoration: BoxDecoration(
          border: Border.all(color: FormConstants.slate300, style: BorderStyle.dashed),
          borderRadius: BorderRadius.circular(FormConstants.cardRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, size: 32.0, color: FormConstants.slate400),
            const SizedBox(height: FormConstants.spaceSM),
            Text('Drop files or browse', style: TextStyle(fontSize: FormConstants.fontLabel, color: FormConstants.slate700)),
            Text('Max 10MB per file', style: TextStyle(fontSize: FormConstants.fontHelper, color: FormConstants.slate500)),
          ],
        ),
      ),
    );
  }
}
```

**Specs:**
- Height: **120px**
- Border: **Dashed**, slate-300, 2px
- Radius: **12px**
- File chips (when selected): Height **32px**, background: slate-100, padding: 8px, delete icon: 16px
- Upload limit: **5MB** per file, **10 files** max
- Progress indicator: Linear inside chip if uploading

---

### I. Submit Button

```dart
ShadButton(
  onPressed: isLoading ? null : _handleSubmit,
  size: ShadButtonSize.lg, // Will respect height: 56px when combined with constraints
  loading: isLoading,
  child: const Text(
    'Submit',
    style: TextStyle(
      fontSize: FormConstants.fontButton,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

**Specs:**
- Height: **56px** (mandatory)
- Min width: **200px**
- Border radius: **8px**
- Typography: **16px, SemiBold** (Bold is too heavy)
- Loading state: Built-in spinner, text changes to "Submitting..."
- **Critical**: Place button directly in Column, **48px below last field** (no wrapping containers)
- Disabled state: Background: slate-300, **must meet 4.5:1 contrast** with white text

---

## 5. Field Grouping & Spacing Layout

### Feedback Form Section Breakdown

```
[Page Header]
    ↓ spaceXXXL (64px)
    
Section 1: IDENTITY
├─ Hi, I'm_____________ [Text Input]
│   ↓ spaceMD (16px)
├─ Email ID [Text Input]
│   ↓ spaceMD (16px)
└─ Select Your Role [Radio Group]
    ↓ spaceXL (32px) // END SECTION
    
Section 2: CONTEXT
├─ How often do you use Vaultscapes? [Checkbox Group]
│   ↓ spaceMD (16px)
└─ Which semester? [Select/Radio]
    ↓ spaceXL (32px) // END SECTION
    
Section 3: FEEDBACK DETAILS
├─ What type of feedback? [Radio Group]
│   ↓ spaceMD (16px)
├─ Describe in detail [Text Area]
│   ↓ spaceMD (16px)
├─ Link to page [Text Input]
│   ↓ spaceMD (16px)
└─ Attach files [File Picker]
    ↓ spaceXL (32px) // END SECTION
    
Section 4: RATING
└─ Rate usability [Star Rating]
    ↓ spaceXXL (48px) // CRITICAL SEPARATION
    
[SUBMIT BUTTON] // Aligned horizontally center
```

### Collaborate Form Section Breakdown

```
[Page Header]
    ↓ spaceXXXL (64px)
    
Section 1: SUBMISSION TYPE
├─ What are you submitting? [Checkbox Group]
│   ↓ spaceMD (16px)
└─ What is the source? [Radio Group]
    ↓ spaceXL (32px)
    
Section 2: TARGET
├─ For which semester? [Select/Radio]
│   ↓ spaceMD (16px)
└─ Subject name & code [Text Input]
    ↓ spaceXL (32px)
    
Section 3: CONTENT
├─ Attach files [File Picker]
│   ↓ spaceMD (16px)
├─ Optional URL [Text Input]
│   ↓ spaceMD (16px)
└─ Describe submission [Text Area]
    ↓ spaceXL (32px)
    
Section 4: ATTRIBUTION
├─ Would you like credit? [Switch]
│   ↓ spaceMD (16px)
└─ [Conditional] Credit name [Text Input]
    ↓ spaceXL (32px)
    
Section 5: ADMIN NOTES
└─ Optional notes for admins [Text Area]
    ↓ spaceXXL (48px) // CRITICAL SEPARATION
    
[SUBMIT BUTTON]
```

---

## 6. Color Palette (Functional Only)

```dart
// Add to form_constants.dart
class FormColors {
  // Primary Action
  static const Color primary = Color(0xFF0EA5E9); // sky-500
  static const Color primaryLight = Color(0xFFF0F9FF); // sky-50
  
  // Semantic
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color error = Color(0xFFEF4444); // red-500
  
  // Neutrals (Slate)
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
  
  // Backgrounds
  static const Color pageBg = slate50;
  static const Color cardBg = Colors.white;
  static const Color disabledBg = slate100;
  
  // Borders
  static const Color borderDefault = slate300;
  static const Color borderFocus = primary;
  static const Color borderError = error;
}
```

**Contrast Requirements:**
- **PASS:** Primary button (white on primary) = 4.8:1 ✓
- **PASS:** Input text (slate-900 on white) = 15.3:1 ✓
- **PASS:** Helper text (slate-500 on white) = 4.6:1 ✓
- **FAIL:** Placeholder (slate-400 on white) = 2.9:1 → **Do not use for critical info**

---

## 7. State Management & UI Feedback

### Validation Strategy
- **When to validate:** On field blur (`onFieldSubmitted`), NOT while typing
- **When to show success:** After successful submission, clear form and show toast
- **When to disable submit:** When any required field is empty OR validation errors exist

### Loading States
```dart
// Button state
ShadButton(
  loading: _isSubmitting,
  onPressed: _isSubmitting ? null : _submit,
  child: const Text('Submit'),
)

// Full-screen loading overlay (for file uploads)
if (_isUploading)
  Container(
    color: Colors.black54,
    child: const Center(child: CircularProgressIndicator()),
  )
```

### Success/Error Feedback
```dart
// Success: Toast notification (persistent until dismissed)
ShadToaster(
  child: ShadToast(
    title: const Text('Feedback submitted successfully!'),
    description: const Text('We\'ll respond within 48 hours.'),
    action: ShadButton.destructive(
      child: const Text('Dismiss'),
      onPressed: () => ShadToaster.of(context).hide(),
    ),
  ),
),

// Error: Inline field error + Toast for network errors
ShadToaster(
  child: ShadToast.destructive(
    title: const Text('Submission failed'),
    description: const Text('Please check your connection and try again.'),
  ),
)
```

---

## 8. Accessibility Checklist (WCAG 2.1 AA)

**Mandatory Implementation:**

- [ ] **Touch Targets:** All interactive elements ≥ **48×48px** (buttons, radios, checkboxes, stars)
- [ ] **Focus Indicators:** Visible 2px outline on keyboard navigation
```dart
Focus(
  child: OutlineButton(
    focusColor: FormColors.primary.withOpacity(0.2),
    focusedBorderColor: FormColors.borderFocus,
  ),
)
```
- [ ] **Screen Reader Labels:** Every input has `semanticLabel`
```dart
Semantics(
  label: 'Feedback description, required, 1000 character limit',
  child: ShadTextarea(...),
)
```
- [ ] **Error Identification:** Errors announced with both color AND icon + text
- [ ] **Required Fields:** Mark with `*` and add `aria-required` equivalent
- [ ] **Keyboard Navigation:** Tab order flows top-to-bottom, left-to-right
- [ ] **Zoom Support:** Layout must work at 200% zoom (use relative units)

---

## 9. Responsive Behavior

```dart
// In build method
bool isMobile = MediaQuery.of(context).size.width < 600;
bool isTablet = MediaQuery.of(context).size.width < 1024;

// Field width
SizedBox(
  width: isMobile ? double.infinity : 500.0,
)

// Checkbox columns
Wrap(
  spacing: FormConstants.spaceMD,
  runSpacing: FormConstants.spaceSM,
  children: fields,
  // Tablet+: 2 columns
  alignment: isTablet ? WrapAlignment.start : WrapAlignment.center,
)

// Text alignment
crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
```

**Breakpoints:**
- **Mobile (< 600px):** Single column, full-width inputs, 16px page padding
- **Tablet (600-1024px):** Max width 500px, centered, 24px page padding
- **Desktop (> 1024px):** Max width 640px, some short fields side-by-side (Name + Email)

---

## 10. Micro-Interactions & Animation

```dart
// Field focus animation
AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  decoration: BoxDecoration(
    border: Border.all(
      color: isFocused ? FormColors.borderFocus : FormColors.borderDefault,
      width: isFocused ? 2.0 : 1.0,
    ),
  ),
)

// Page transition
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const FeedbackForm(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  ),
)

// Toast animation
ShadToaster(
  reverseAnimationDuration: const Duration(milliseconds: 300),
  animationDuration: const Duration(milliseconds: 300),
  alignment: Alignment.bottomCenter,
)
```

---

## 11. Developer Implementation Checklist

**Before PR Submission, Verify:**

- [ ] **Spacing Audit:** Every `SizedBox` height is from `FormConstants` (4, 8, 16, 24, 32, 48)
- [ ] **Height Consistency:** All text inputs, selects, buttons are exactly **56px**
- [ ] **Typography:** Urbanist
- [ ] **Color Check:** No hardcoded colors; all from `FormColors`
- [ ] **Button Separation:** **48px** space exists between last field and submit button
- [ ] **Validation:** Errors show on blur, not onChange
- [ ] **Loading States:** Button shows spinner, form disabled during submit
- [ ] **Accessibility:** Run `flutter test` with `ensureAccessibleNavigation()` and `checkTextContrast()`
- [ ] **File Upload:** Progress indicator shown, 5MB limit enforced before upload
- [ ] **Back Handler:** Shows confirmation dialog if form is dirty
- [ ] **Success Flow:** Toast shown, form cleared, returns to SYNERGY after 2s delay

---

## 13. Form-Specific Field Sequences

### Feedback Form Exact Order
1. **Name** (required, TextInputAction.next)
2. **Email** (required, email validator, TextInputAction.next)
3. **Role** (required, RadioGroup)
4. **Usage Frequency** (CheckboxGroup)
5. **Semester** (required, Select)
6. **Feedback Type** (required, RadioGroup)
7. **Description** (required, TextArea, maxLength: 1000)
8. **Page URL** (optional, url validator)
9. **File Attachments** (optional, max 5 files)
10. **Star Rating** (optional)
11. **Submit Button**

### Collaborate Form Exact Order
1. **Submission Type** (required, CheckboxGroup, min: 1)
2. **Source** (required, RadioGroup)
3. **Semester** (required, Select)
4. **Subject** (required, TextInputAction.next)
5. **File Attachments** (required, max 10 files)
6. **URL** (optional, url validator)
7. **Description** (required, TextArea, maxLength: 500)
8. **Credit Toggle** (Switch)
9. **Credit Name** (conditional required, visible when toggle is true)
10. **Admin Notes** (optional, TextArea)
11. **Submit Button**

---

## 14. Performance Considerations

- **Debounce validation:** 300ms delay on text fields to avoid rebuild spam
- **Lazy load file picker:** Load `file_picker` package only when widget mounts
- **Memoize sections:** Wrap each `_buildSection()` in `const` constructor if possible
- **Image compression:** Resize attachments >2000px width before upload
- **Avoid rebuilding:** Use `ValueNotifier` for form state, not `setState()` on every keystroke

---

**Document Version:** 1.0  
**Last Updated:** 2024-01-22  
**Design System:** Minimal 8-Point Grid  
**Component Library:** shadcn_flutter with custom additions