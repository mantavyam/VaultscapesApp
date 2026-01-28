# Vaultscapes

Vaultscapes is a mobile-first educational resource aggregation platform designed to provide BTech students with seamless access to semester-wise academic materials, including notes, assignments, previous year questions, and curated learning resources.

## Tech Stack

- **Application**: Flutter, Dart
- **Authentication** - Google

## Target Project Structure

### 3.2 Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── route_constants.dart
│   │   └── url_constants.dart (GitBook base URLs)
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── color_scheme.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── helpers.dart
│   │   ├── extensions.dart
│   │   └── markdown_helpers.dart (markdown parsing utilities)
│   └── error/
│       ├── exceptions.dart
│       └── failures.dart
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── navigation_model.dart (navigation manifest)
│   │   ├── semester_model.dart
│   │   ├── subject_model.dart
│   │   ├── cached_markdown_model.dart (markdown + timestamp)
│   │   ├── feedback_model.dart
│   │   └── collaboration_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── markdown_repository.dart (fetch & cache markdown)
│   │   ├── navigation_repository.dart (load navigation manifest)
│   │   ├── user_preferences_repository.dart
│   │   ├── feedback_repository.dart
│   │   └── collaboration_repository.dart
│   ├── services/
│   │   ├── markdown_fetcher_service.dart (HTTP fetching)
│   │   ├── markdown_cache_service.dart (Hive caching)
│   │   ├── local_storage_service.dart
│   │   └── analytics_service.dart
│   └── parsers/
│       ├── gitbook_markdown_parser.dart (custom GitBook block parser)
│       ├── hint_block_parser.dart
│       ├── tabs_block_parser.dart
│       ├── expandable_block_parser.dart
│       └── card_block_parser.dart
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   ├── semester.dart
│   │   ├── subject.dart
│   │   ├── markdown_content.dart
│   │   └── navigation_item.dart
│   └── usecases/
│       ├── authenticate_user.dart
│       ├── get_markdown_content.dart
│       ├── refresh_markdown_cache.dart
│       ├── load_navigation_structure.dart
│       ├── submit_feedback.dart
│       └── submit_collaboration.dart
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── markdown_provider.dart (manages markdown state)
│   │   ├── navigation_provider.dart
│   │   └── cache_provider.dart
│   ├── screens/
│   │   ├── onboarding/
│   │   │   ├── welcome_screen.dart
│   │   │   └── profile_setup_screen.dart
│   │   ├── home/
│   │   │   ├── root_homepage_screen.dart
│   │   │   ├── semester_overview_screen.dart (renders markdown)
│   │   │   └── subject_detail_screen.dart (renders markdown)
│   │   ├── breakthrough/
│   │   │   └── breakthrough_webview_screen.dart
│   │   ├── synergy/
│   │   │   ├── synergy_screen.dart
│   │   │   ├── feedback_form_tab.dart
│   │   │   └── collaborate_form_tab.dart
│   │   ├── profile/
│   │   │   ├── profile_screen.dart
│   │   │   └── edit_profile_dialog.dart
│   │   └── main_navigation_screen.dart
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_widget.dart
│   │   │   └── empty_state_widget.dart
│   │   ├── cards/
│   │   │   ├── semester_card.dart
│   │   │   ├── subject_card.dart
│   │   │   └── resource_card.dart
│   │   ├── markdown/
│   │   │   ├── markdown_renderer.dart (custom renderer)
│   │   │   ├── hint_block_widget.dart (renders hints as Alerts)
│   │   │   ├── tabs_block_widget.dart (renders tabs as TabList)
│   │   │   ├── expandable_block_widget.dart (renders as Accordion)
│   │   │   ├── card_block_widget.dart (renders GitBook cards)
│   │   │   └── pdf_link_widget.dart (download button for PDFs)
│   │   ├── forms/
│   │   │   ├── custom_text_input.dart
│   │   │   ├── custom_dropdown.dart
│   │   │   └── file_picker_widget.dart
│   │   └── navigation/
│   │       └── custom_bottom_nav_bar.dart
│   └── routes/
│       └── app_router.dart
└── config/
    └── environment_config.dart
```

**New Asset Structure:**
```
assets/
├── data/
│   └── navigation.json (lightweight navigation manifest)
├── images/
│   ├── logo.png
│   ├── semester_thumbnails/
│   │   ├── sem_1.png
│   │   └── ...
│   └── placeholders/
└── fonts/ (if using custom fonts)
```

## Reference Documentation

Read these documents when working on specific areas:

| Document | When to Read |
|----------|--------------|
| `.claude/reference/overview.md` | Product Overview & Objectives, Development Phases & Acceptance Criteria, Success Criteria Summary, Appendix |
| `.claude/PRD.md` | Understanding functional and non-functional requirements |
| `.claude/reference/architecture.md` | App Architecture including Tech Stack, Project Structure, Data Architecture, Authentication Architecture, Modular Content Management, Error Handling Strategy, Performance Optimisation|
| `.claude/reference/userflow.md` | Detailed Userflows including 'First-Time User Journey', 'Returning User Journey (with Homepage Preference)', 'Guest User Journey', 'Profile Customization Flow', 'Feedback+Collaboration Submission Flow' |
| `.claude/reference/ui-ux.md` | UI/UX Specs including Component Mapping from shadcn_flutter package, Design System (Color Palette, Typography Scale, Spacing System, Interactive States), Responsive Behavior |