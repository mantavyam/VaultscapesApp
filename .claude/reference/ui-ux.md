## 6. UI/UX Design with shadcn_flutter

- We don't want to use the Material or Cupertino instead we shall use a pub.dev package based on shadcn styling ubiquitous in web standard and actually very beautiful available at 'https://pub.dev/packages/shadcn_flutter' with version shadcn_flutter: ^0.0.47 and documentation for installation at 'https://sunarya-thito.github.io/shadcn_flutter/#/installation'


### 6.1 Component Mapping

#### 6.1.1 Core Components

**Welcome Screen:**
- `Button` (primary) for "Get Started"
- `Button` (outline/ghost) for "Explore"
- Custom hero image/illustration

**Bottom Sheet (Auth):**
- `Sheet` component for modal presentation
- `Button` with Google logo for OAuth

**Bottom Navigation:**
- Custom `NavigationBar` using shadcn buttons
- Icons from `lucide-react` (or Flutter Icons)

**Cards (Semester/Subject):**
- `Card` + `CardImage` for thumbnail
- `CardTitle` and `CardDescription` for text
- Tap gesture wrapping entire card

**Accordion Sections:**
- `Accordion` for collapsible semester overview sections
- `Collapsible` for nested content

**Tabs:**
- `TabList` for horizontal tab navigation
- `TabPane` for tab content containers

**Forms:**
- `TextInput` for text fields
- `TextArea` for multiline inputs
- `Select` for dropdowns
- `RadioGroup` for single-choice selections
- `Checkbox` for multi-choice selections
- `RadioCard` for visually distinct radio options
- `StarRating` for usability rating
- `Button` for form submission

**Dialogs:**
- `Dialog` for name edit modal
- `AlertDialog` for confirmations (logout, etc.)

**Feedback Elements:**
- `Toast` for success/error messages
- `CircularProgress` / `LinearProgress` for loading states
- `Skeleton` for content placeholders

**Utility Components:**
- `Badge` for status indicators (e.g., "Solution Available")
- `Chip` for tags (note categories, subjects)
- `Avatar` for profile picture
- `Divider` for visual separation
- `Tooltip` for helpful hints

#### 6.1.2 Layout Components

**App Structure:**
- `Scaffold` as base layout
- `AppBar` for top navigation
- Custom bottom navigation (not using shadcn's since it's custom)

**Content Layout:**
- `Card` for grouping related content
- `Timeline` for exam schedules (optional)
- `Table` for structured data (optional)
- `Carousel` for featured content (future)

### 6.2 Design System

#### 6.2.1 Typography Scale
- **Heading 1**: Semester titles, page headers
- **Heading 2**: Section titles
- **Heading 3**: Subsection titles
- **Body**: Descriptions, helper text
- **Caption**: Labels, metadata

#### 6.2.2 Color Palette
- **Primary**: Brand color for CTAs and accents
- **Secondary**: Supporting color for secondary actions
- **Destructive**: Red for logout, delete actions
- **Muted**: Background colors for cards
- **Border**: Dividers and outlines

#### 6.2.3 Spacing System
- Consistent padding/margin using 8px grid system
- Card spacing: 16px
- Section spacing: 24px
- Content padding: 16px horizontal, 12px vertical

#### 6.2.4 Interactive States
- Hover effects on buttons/cards
- Loading states for async operations
- Disabled states for unavailable actions
- Focus indicators for accessibility

### 6.3 Responsive Behavior
- Single-column layout for mobile
- Maximum content width for tablets (600-900px)
- Adapt bottom navigation to side navigation on larger screens (future)


### 6.4 Appendix for shadcn_flutter

## Introduction

- Installation
- Theme
- Typography
- Layout
- Web Preloader
- Components
- Icons
- Colors
- Material/Cupertino
- State Management

## Application

- App Example
- GoRouter Example
- ShadcnLayer

## Animation

- Animated Value
- Number Ticker
- Repeated Animation
- Timeline Animation

## Control

- Button

## Disclosure

- Accordion
- Collapsible

## Display

- Avatar
- Avatar Group
- Code Snippet
- Table
- Tracker

## Feedback

- Alert
- Alert Dialog
- Circular Progress
- Linear Progress
- Progress
- Skeleton
- Toast
- Form
- AutoComplete
- Checkbox
- Chip Input
- Color Picker
- Date Picker

## Form

- Formatted Input
- Input OTP
- Item Picker
- Multi Select
- Number Input
- Phone Input
- Radio Card
- Radio Group
- Select
- Slider
- Star Rating
- Switch
- Text Area
- Text Input
- Time Picker
- Toggle

## Layout

- App Bar
- Card
- Card Image
- Carousel
- Divider
- Resizable
- Scaffold
- Sortable
- Stepper
- Steps
- Timeline

## Navigation

- Breadcrumb
- Dot Indicator
- Expandable Sidebar
- Menubar
- Navigation Bar
- Navigation Menu
- Navigation Rail
- Navigation Sidebar
- Pagination
- Switcher
- Tab List
- Tab Pane
- Tabs
- Tree

## Overlay

- Dialog
- Drawer
- Hover Card
- Popover
- Sheet
- Swiper
- Tooltip

## Utility

- Badge
- Calendar
- Chip
- Command
- Context Menu
- Dropdown Menu
- Keyboard Display
- Overflow Marquee
- Refresh Trigger

---