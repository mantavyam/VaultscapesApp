## 7. UI/UX Specifications

### 7.1 Design System

#### 7.1.1 Color Palette

**Primary Colors**:
- **Primary**: `#1E88E5` (Blue 600) - CTAs, selected icons, links
- **Primary Light**: `#64B5F6` (Blue 400) - Hover states
- **Primary Dark**: `#1565C0` (Blue 800) - Active states

**Secondary Colors**:
- **Secondary**: `#FFC107` (Amber 500) - Secondary CTAs, accents
- **Secondary Light**: `#FFD54F` (Amber 300)
- **Secondary Dark**: `#FFA000` (Amber 700)

**Neutral Colors**:
- **Background**: `#FFFFFF` (White)
- **Surface**: `#F5F5F5` (Grey 100) - Cards, elevated surfaces
- **Outline**: `#E0E0E0` (Grey 300) - Dividers, borders
- **Text Primary**: `#212121` (Grey 900)
- **Text Secondary**: `#757575` (Grey 600)

**Status Colors**:
- **Error**: `#E53935` (Red 600)
- **Success**: `#43A047` (Green 600)
- **Warning**: `#FB8C00` (Orange 600)

#### 7.1.2 Typography

**Font Family**: 
- Primary: `Roboto` (default Material font)
- Headings: `Poppins` (bold weight for visual hierarchy)

**Type Scale**:
| Style | Font | Size | Weight | Use Case |
|-------|------|------|--------|----------|
| Headline 1 | Poppins | 24sp | Bold (700) | Screen titles |
| Headline 2 | Poppins | 20sp | Bold (700) | Section headers |
| Body Large | Roboto | 16sp | Regular (400) | Primary content |
| Body Medium | Roboto | 14sp | Regular (400) | Secondary content |
| Caption | Roboto | 12sp | Regular (400) | Helper text |
| Button | Roboto | 16sp | Medium (500) | All button text |

#### 7.1.3 Spacing System

**Base Unit**: 4dp (all spacing is multiples of 4)

| Token | Value | Use Case |
|-------|-------|----------|
| XXS | 4dp | Icon padding |
| XS | 8dp | Tight spacing |
| SM | 12dp | Default item spacing |
| MD | 16dp | Screen padding, section spacing |
| LG | 24dp | Large section gaps |
| XL | 32dp | Screen margins |
| XXL | 48dp | Major section breaks |

#### 7.1.4 Component Specifications

**Buttons**:
```
Filled Button (Primary CTA):
- Height: 48dp
- Horizontal padding: 24dp
- Border radius: 8dp
- Background: Primary color
- Text: White, 16sp, medium weight
- Elevation: 2dp
- Press state: Elevation 8dp, slight scale

Outlined Button (Secondary CTA):
- Height: 48dp
- Horizontal padding: 24dp
- Border: 2dp, Primary color
- Border radius: 8dp
- Background: Transparent
- Text: Primary color, 16sp, medium weight
- Press state: Background 5% primary color
```

**Bottom Sheet**:
```
- Drag handle: 32dp wide, 4dp tall, rounded, grey
- Corner radius: 16dp (top corners only)
- Background: Surface color
- Content padding: 24dp all sides
- Max height: 70% of screen
- Dismissible: Drag down or tap outside
```

**List Tiles** (Quick Links):
```
- Height: 56dp (Material standard)
- Leading icon: 24dp, 16dp from left edge
- Title: 16sp, 72dp from left edge
- Trailing icon (chevron): 24dp, 16dp from right edge
- Divider: 1dp, Outline color, inset 72dp from left
- Press state: Surface color overlay
```

**WebView Loading**:
```
Linear Progress Indicator:
- Height: 4dp
- Position: Top edge of WebView
- Color: Primary color
- Indeterminate animation: Sweeping motion
```

---

### 7.2 Responsive Design Guidelines

**Breakpoints**:
- **Mobile**: < 600dp width (primary target)
- **Tablet**: 600dp - 839dp (secondary consideration)
- **Desktop**: > 840dp (out of scope for initial release)

**Mobile-Specific Optimizations**:
- All touch targets minimum 48dp x 48dp
- Safe area insets respected (notches, home indicators)
- Bottom navigation bar height accounts for gesture bars on iOS/Android 10+
- Text scales with system font size settings (accessibility)

---

### 7.3 Accessibility Requirements

**WCAG 2.1 Level AA Compliance**:

1. **Color Contrast**:
   - Text on background: Minimum 4.5:1 ratio
   - Large text (18sp+): Minimum 3:1 ratio
   - Primary blue (#1E88E5) on white: 4.51:1 ✓

2. **Semantic Labels**:
   - All icons have text alternatives (e.g., "Home" for home icon)
   - WebViews have loading announcements for screen readers
   - Buttons have clear action labels ("Continue with Google" not just "Continue")

3. **Focus Management**:
   - Keyboard navigation order follows visual hierarchy
   - Focus indicators visible (2dp outline, primary color)
   - Modal bottom sheets trap focus until dismissed

4. **Dynamic Text Sizing**:
   - All text scales with system settings (up to 200%)
   - Layout remains usable at maximum text size

---