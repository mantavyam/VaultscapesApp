# Breakthrough UI Screen - Technical Documentation

## Overview

The **Breakthrough** UI screen displays AI newsletter content from AlphaSignal.ai in a clean, ad-free format. It uses Flutter's `webview_flutter` package to embed web content while applying JavaScript-based filtering to remove unwanted promotional elements.

## Architecture

### Main Components

```
AlphaSignalWebViewScreen (StatefulWidget)
├── Main WebView (displays email content)
├── Loading Overlay (shown during page load)
├── FAB (opens archive bottom sheet)
└── _ArchiveBottomSheet (StatefulWidget)
    └── Archive WebView (for selecting past emails)
```

### File Location
`lib/presentation/screens/alphasignal/alphasignal_webview_screen.dart`

---

## Content Rendering Strategy

### 1. Default View (`/last-email`)

When the screen loads, it displays `https://alphasignal.ai/last-email` which shows the most recent newsletter.

### 2. Email Page Structure

AlphaSignal email pages have a two-layer structure:

```
Page Level (document)
├── <header> - Logo, Advertise button
├── <div.container>
│   ├── <a href="/archive"> - "← Back to list" link
│   ├── <div.heading> - Title + Timestamp
│   └── <div.my-5>
│       └── <iframe srcdoc="..."> - ACTUAL EMAIL CONTENT
└── <footer> - Copyright, Privacy Policy, Terms
```

The actual email content lives inside an `<iframe>` with a `srcdoc` attribute containing the full HTML of the newsletter.

---

## Element Hiding Strategy

### Page-Level Hiding (Outside Iframe)

The JavaScript processor hides these elements on the parent page:

| Element | Selector | Purpose |
|---------|----------|---------|
| Header | `header` | Contains "Advertise" button |
| Back Link | `a[href="/archive"]` | "← Back to list" |
| Heading | `.heading` | Title and timestamp |
| Footer | `footer` | Copyright, legal links |

**CSS Injection:**
```css
header, footer { display: none !important; }
.heading, a[href="/archive"] { display: none !important; }
.container { max-width: 100%; padding: 0; margin: 0; }
```

### Iframe Content Hiding

Inside the iframe, we hide promotional sections using **pattern matching with size guards**:

| Pattern | Selector Logic | Size Guard |
|---------|---------------|------------|
| Menu Bar | `.menu-bar` class or "Signup" + "Follow on X" text | Any size |
| Author Section | Contains "Today's Author" | < 500 chars |
| Rating Section | Contains "How was today" | < 300 chars |
| Footer | Contains "214 Barton Springs" | < 800 chars |
| Promotion | Contains "Looking to promote" | < 500 chars |

**Critical Safety Mechanism:**
- Tables with `height > 30% of body height` are **NEVER hidden**
- Tables with `text length > 2000 characters` are **NEVER hidden**
- This prevents accidentally hiding the main email content

---

## State Management

### Main Screen States

| State | Purpose |
|-------|---------|
| `_isContentReady` | `true` when page finished loading + JS executed |
| `_isNavigating` | `true` when transitioning from archive to email |
| `_loadingProgress` | 0.0-1.0 progress for loading indicator |
| `_canGoBack` | Whether WebView can navigate back |
| `_hasError` | Whether a network error occurred |

### Loading Overlay Logic

```dart
// Overlay shown when:
if (!_isContentReady || _isNavigating) {
  // Show loading overlay with progress bar
}
```

---

## Archive Bottom Sheet Flow

### User Interaction Flow

```
1. User taps FAB (archive icon)
   ↓
2. Bottom sheet opens (50% screen height)
   ↓
3. Archive page loads in embedded WebView
   - Header/footer hidden via JS
   - Link interceptor injected
   ↓
4. User scrolls and taps an article
   ↓
5. Link interceptor catches click
   - Prevents default navigation
   - Sends URL to Flutter via JavaScript channel
   ↓
6. Flutter receives URL
   - Sets _isNavigating = true
   - Closes bottom sheet
   - Loads URL in main WebView
   ↓
7. Email page loads
   - Page chrome hidden
   - Iframe maximized
   - Promotional content filtered
   ↓
8. _isContentReady = true
   - Loading overlay removed
   - Content visible
```

### Link Interception Mechanism

```javascript
// Capture all clicks on anchor tags
document.addEventListener('click', function(e) {
  var target = e.target;
  // Traverse up to find <a> tag
  while (target && target.tagName !== 'A') {
    target = target.parentElement;
  }
  
  if (target && target.href.includes('/email/')) {
    e.preventDefault();
    e.stopPropagation();
    // Send to Flutter
    LinkHandler.postMessage(fullUrl);
  }
}, true);
```

### Debounce Protection

Multiple layers prevent duplicate callbacks:

1. **JavaScript Level**: `window._vaultscapesLinkSent = true` after first intercept
2. **Widget Level**: `_isHandlingEmailSelection = true` flag
3. **Parent Level**: `hasHandledSelection = true` in `_showArchiveSheet()`

---

## JavaScript Execution Timing

### Email Page (`_hideEmailElementsJs`)

```
onPageFinished
  ↓
runJavaScript(_hideEmailElementsJs)
  ↓
Immediate execution
  ↓
Retry at: 100ms, 300ms, 600ms, 1000ms, 2000ms, 3500ms
  ↓
MutationObserver watches for DOM changes
  ↓
Disconnect observer after 10 seconds
```

### Archive Page (`_hideArchiveElementsJs` + `_linkInterceptorJs`)

```
onPageFinished
  ↓
runJavaScript(_hideArchiveElementsJs)
  ↓
runJavaScript(_linkInterceptorJs)
  ↓
300ms delay
  ↓
Set _isLoading = false
```

---

## Bottom Sheet Scroll Handling

The archive WebView is wrapped in a `GestureDetector` to prevent scroll gestures from closing the bottom sheet:

```dart
GestureDetector(
  onVerticalDragUpdate: (_) {}, // Absorb vertical drags
  child: WebViewWidget(controller: _archiveController),
)
```

Additionally, CSS is injected to ensure proper scrolling:

```css
html, body {
  overflow-y: auto !important;
  -webkit-overflow-scrolling: touch !important;
  touch-action: pan-y !important;
}
```

---

## Error Handling

### Network Errors
```dart
onWebResourceError: (error) {
  setState(() {
    _hasError = true;
    _isContentReady = true; // Remove loading overlay
  });
}
```

Displays `AppErrorWidget.network()` with retry button.

### Navigation Protection

Only allowed navigations in archive WebView:
- `alphasignal.ai/archive` - Main archive page
- `alphasignal.ai/email/*` - Individual emails (intercepted)
- `alphasignal.ai/last-email` - Latest email (intercepted)

All other URLs are blocked with `NavigationDecision.prevent`.

---

## Key Design Decisions

### 1. Why JavaScript Injection vs. Native Parsing?

JavaScript injection allows us to:
- Hide elements dynamically as they load
- Access iframe content (same-origin)
- Apply CSS rules that override site styles
- React to dynamic content changes via MutationObserver

### 2. Why Size Guards for Table Hiding?

Email newsletters use heavily nested `<table>` layouts. A footer with "unsubscribe" text is inside a table that's inside the main content table. Without size guards, hiding based on text patterns would hide the entire email.

### 3. Why Bottom Sheet Instead of Dialog?

- **Better UX**: Natural swipe-to-dismiss gesture
- **Scroll Handling**: Easier to prevent accidental dismissals
- **Mobile Native Feel**: Matches platform conventions

---

## Maintenance Notes

### If AlphaSignal Changes Their Structure

1. **Page structure change**: Update selectors in `hidePageChrome()`
2. **New promotional section**: Add pattern to `hideUnwantedElements()`
3. **iframe changes**: May need to adjust iframe detection logic

### Debug Logging

All JavaScript functions include `console.log()` statements prefixed with `VaultScapes:`. View in Android Studio Logcat or by running:

```bash
adb logcat | grep -i "VaultScapes\|chromium.*CONSOLE"
```

### Testing Checklist

- [ ] Last-email loads without white screen
- [ ] Page chrome (header/footer/title) is hidden
- [ ] Email content is visible and scrollable
- [ ] Promotional sections inside email are hidden
- [ ] Archive bottom sheet opens at 50% height
- [ ] Archive scrolling works without closing sheet
- [ ] Clicking email in archive opens in main view
- [ ] No duplicate navigation/callbacks
- [ ] Back navigation works correctly
- [ ] Refresh button reloads content
- [ ] Home button returns to last-email
