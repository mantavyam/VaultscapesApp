# Gitbook to shadcn_flutter Component Mapping

This document defines the standard mapping strategy between Gitbook markdown blocks and their corresponding shadcn_flutter widget implementations for the Vaultscapes application.

## Overview

When fetching content from Gitbook pages (via `.md` suffix URLs), the raw markdown content needs to be parsed and converted into Flutter widgets using shadcn_flutter components. This ensures a consistent, native-looking UI while preserving the semantic meaning of the original content.

---

## Block Mappings

### 1. Paragraphs
**Gitbook Syntax:**
```markdown
Simple text content without any special formatting.
```

**shadcn_flutter Implementation:**
```dart
Text(
  'Content here',
  style: TextStyle(), // Use theme typography
)
```

**Notes:** Standard text rendering with theme-aware styling.

---

### 2. Headings

**Gitbook Syntax:**
```markdown
# Page Title (H1)
## Heading 1 (H2)
### Heading 2 (H3)
#### Heading 3 (H4)
```

**shadcn_flutter Implementation:**
```dart
// H1 - Page titles
Text('Title', style: theme.typography.h1)

// H2 - Section titles
Text('Section', style: theme.typography.h2)

// H3 - Subsection titles
Text('Subsection', style: theme.typography.h3)

// H4 - Minor headings
Text('Minor heading', style: theme.typography.h4)
```

**Notes:** Use theme typography scale for consistent sizing.

---

### 3. Unordered Lists

**Gitbook Syntax:**
```markdown
- Item 1
  - Nested item 1.1
    - Deeply nested
  - Nested item 1.2
- Item 2
```

**shadcn_flutter Implementation:**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•', style: TextStyle(fontSize: 16)),
        SizedBox(width: 8),
        Expanded(child: Text('Item text')),
      ],
    ),
    // Nested items with additional left padding
    Padding(
      padding: EdgeInsets.only(left: 16),
      child: Row(/* nested item */),
    ),
  ],
)
```

**Notes:** Use indentation for nesting, bullet character for markers.

---

### 4. Ordered Lists

**Gitbook Syntax:**
```markdown
1. First item
   1. Nested first
   2. Nested second
2. Second item
```

**shadcn_flutter Implementation:**
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Text('1.', textAlign: TextAlign.right),
        ),
        SizedBox(width: 8),
        Expanded(child: Text('First item')),
      ],
    ),
  ],
)
```

**Notes:** Numbered markers with appropriate width allocation.

---

### 5. Task Lists

**Gitbook Syntax:**
```markdown
- [ ] Unchecked task
- [x] Checked task
  - [ ] Nested task
```

**shadcn_flutter Implementation:**
```dart
Row(
  children: [
    Checkbox(
      state: isChecked ? CheckboxState.checked : CheckboxState.unchecked,
      onChanged: null, // Read-only for display
    ),
    SizedBox(width: 8),
    Expanded(child: Text('Task description')),
  ],
)
```

**Notes:** Use shadcn Checkbox in read-only mode for display.

---

### 6. Hints/Callouts

**Gitbook Syntax:**
```markdown
{% hint style="info" %}
Information content here
{% endhint %}

{% hint style="success" %}
Success message
{% endhint %}

{% hint style="warning" %}
Warning message
{% endhint %}

{% hint style="danger" %}
Danger/Error message
{% endhint %}
```

**shadcn_flutter Implementation:**
```dart
Alert(
  leading: Icon(_getHintIcon(style)),
  title: Text(title ?? _getDefaultTitle(style)),
  content: Text(content),
  destructive: style == 'danger',
)

// Helper for icons
Icon _getHintIcon(String style) {
  switch (style) {
    case 'info': return Icon(LucideIcons.info);
    case 'success': return Icon(LucideIcons.circleCheck);
    case 'warning': return Icon(LucideIcons.triangleAlert);
    case 'danger': return Icon(LucideIcons.circleX);
  }
}
```

**Notes:** Map hint styles to Alert variants with appropriate icons.

---

### 7. Quotes/Blockquotes

**Gitbook Syntax:**
```markdown
> "Quote text here" — Author
```

**shadcn_flutter Implementation:**
```dart
Container(
  decoration: BoxDecoration(
    border: Border(
      left: BorderSide(
        color: theme.colorScheme.border,
        width: 4,
      ),
    ),
  ),
  padding: EdgeInsets.only(left: 16),
  child: Text(
    '"Quote text"',
    style: TextStyle(fontStyle: FontStyle.italic),
  ),
)
```

**Notes:** Left border styling to indicate quote block.

---

### 8. Code Blocks

**Gitbook Syntax:**
```markdown
{% code title="filename.dart" lineNumbers="true" %}
```dart
code content here
```
{% endcode %}
```

**shadcn_flutter Implementation:**
```dart
Card(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null)
        Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(LucideIcons.fileCode, size: 16),
              SizedBox(width: 8),
              Text(title, style: theme.typography.small),
            ],
          ),
        ),
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        color: theme.colorScheme.muted,
        child: SelectableText(
          code,
          style: TextStyle(fontFamily: 'monospace'),
        ),
      ),
    ],
  ),
)
```

**Notes:** Use Card for container, monospace font for code.

---

### 9. Files/Downloads

**Gitbook Syntax:**
```markdown
{% file src="url" %}
Caption text
{% endfile %}
```

**shadcn_flutter Implementation:**
```dart
Card(
  child: InkWell(
    onTap: () => _downloadFile(url),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(LucideIcons.fileDown),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(filename),
                if (caption != null)
                  Text(caption, style: theme.typography.muted),
              ],
            ),
          ),
          Icon(LucideIcons.download),
        ],
      ),
    ),
  ),
)
```

**Notes:** Clickable card with download icon and file info.

---

### 10. Images

**Gitbook Syntax:**
```markdown
![Alt text](image_url)

<figure>
  <img src="url" alt="Alt text">
  <figcaption>Caption</figcaption>
</figure>
```

**shadcn_flutter Implementation:**
```dart
Column(
  children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Skeleton(width: double.infinity, height: 200);
        },
        errorBuilder: (context, error, stack) {
          return Container(
            height: 200,
            color: theme.colorScheme.muted,
            child: Icon(LucideIcons.imageOff),
          );
        },
      ),
    ),
    if (caption != null)
      Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(caption, style: theme.typography.muted),
      ),
  ],
)
```

**Notes:** Handle loading and error states appropriately.

---

### 11. Embedded URLs

**Gitbook Syntax:**
```markdown
{% embed url="https://example.com" %}
```

**shadcn_flutter Implementation:**
```dart
Card(
  child: InkWell(
    onTap: () => _launchUrl(url),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(LucideIcons.externalLink),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_extractDomain(url)),
                Text(url, style: theme.typography.muted, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
)
```

**Notes:** Display as clickable link card.

---

### 12. Tables

**Gitbook Syntax:**
```markdown
| Header 1 | Header 2 |
| -------- | -------- |
| Cell 1   | Cell 2   |
```

**shadcn_flutter Implementation:**
```dart
Table(
  border: TableBorder.all(
    color: theme.colorScheme.border,
    width: 1,
  ),
  children: [
    TableRow(
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
      ),
      children: headers.map((h) => 
        Padding(
          padding: EdgeInsets.all(12),
          child: Text(h, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ).toList(),
    ),
    ...rows.map((row) => TableRow(
      children: row.map((cell) =>
        Padding(
          padding: EdgeInsets.all(12),
          child: Text(cell),
        ),
      ).toList(),
    )),
  ],
)
```

**Notes:** Use Flutter's Table widget with theme-consistent styling.

---

### 13. Tabs

**Gitbook Syntax:**
```markdown
{% tabs %}
{% tab title="Tab 1" %}
Content 1
{% endtab %}
{% tab title="Tab 2" %}
Content 2
{% endtab %}
{% endtabs %}
```

**shadcn_flutter Implementation:**
```dart
Tabs(
  index: currentTab,
  onChanged: (i) => setState(() => currentTab = i),
  children: tabs.map((tab) => TabChild(
    tab: Text(tab.title),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: _buildContent(tab.content),
    ),
  )).toList(),
)
```

**Notes:** Use shadcn Tabs component for tabbed content.

---

### 14. Expandable/Details

**Gitbook Syntax:**
```markdown
<details>
<summary>Click to expand</summary>
Hidden content here
</details>
```

**shadcn_flutter Implementation:**
```dart
Collapsible(
  children: [
    CollapsibleTrigger(
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight),
          SizedBox(width: 8),
          Text('Click to expand'),
        ],
      ),
    ),
    CollapsibleContent(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: _buildContent(content),
      ),
    ),
  ],
)
```

**Notes:** Use shadcn Collapsible for expandable sections.

---

### 15. Stepper

**Gitbook Syntax:**
```markdown
{% stepper %}
{% step %}
### Step 1 title
Step 1 content
{% endstep %}
{% step %}
### Step 2 title
Step 2 content
{% endstep %}
{% endstepper %}
```

**shadcn_flutter Implementation:**
```dart
Stepper(
  direction: Axis.vertical,
  children: steps.asMap().entries.map((entry) => Step(
    title: Text(entry.value.title),
    content: _buildContent(entry.value.content),
  )).toList(),
)
```

**Notes:** Use shadcn Stepper for step-by-step content.

---

### 16. Math/TeX

**Gitbook Syntax:**
```markdown
$$f(x) = x * e^{2 pi i \xi x}$$
```

**shadcn_flutter Implementation:**
```dart
// Use flutter_math_fork package
Math.tex(
  r'f(x) = x * e^{2 \pi i \xi x}',
  textStyle: theme.typography.p,
)
```

**Notes:** Requires flutter_math_fork dependency for LaTeX rendering.

---

### 17. Dividers

**Gitbook Syntax:**
```markdown
---
```

**shadcn_flutter Implementation:**
```dart
Divider()
```

**Notes:** Simple divider from shadcn_flutter.

---

## Loading States

While content is being fetched and parsed, use Skeleton placeholders:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Title skeleton
    Skeleton(width: 200, height: 32),
    SizedBox(height: 16),
    // Paragraph skeletons
    Skeleton(width: double.infinity, height: 16),
    SizedBox(height: 8),
    Skeleton(width: double.infinity, height: 16),
    SizedBox(height: 8),
    Skeleton(width: 250, height: 16),
    SizedBox(height: 24),
    // Image skeleton
    Skeleton(width: double.infinity, height: 200),
  ],
)
```

---

## Error States

For failed content loading:

```dart
Alert(
  leading: Icon(LucideIcons.circleAlert),
  title: Text('Failed to load content'),
  content: Text('Please check your connection and try again.'),
  destructive: true,
)
```

---

## Implementation Notes

1. **One Page = One Screen**: Each Gitbook URL should render as a single vertically-scrollable screen.

2. **Dynamic Rendering**: Parse markdown at runtime and build widget tree dynamically.

3. **Caching**: Consider caching parsed content for offline access and performance.

4. **Theme Awareness**: All components should respect the current theme (light/dark mode).

5. **Accessibility**: Ensure proper semantics for screen readers.

6. **Link Handling**: Internal links should navigate within the app; external links open in browser.

---

## Dependencies

Required packages:
- `shadcn_flutter: ^0.0.47` - UI components
- `markdown: ^7.1.1` - Markdown parsing
- `url_launcher: ^6.2.1` - External link handling
- `flutter_math_fork: ^0.7.1` - Math/TeX rendering (optional)
- `cached_network_image: ^3.3.0` - Image caching

---

## Future Enhancements

1. **Syntax Highlighting**: Add code syntax highlighting for code blocks
2. **Offline Support**: Cache rendered content for offline viewing
3. **Search**: Full-text search across all fetched content
4. **Bookmarks**: Allow users to bookmark specific sections
