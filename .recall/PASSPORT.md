<!-- recall:passport:begin -->
# Project Passport (Non-Volatile Blueprint)

> **AI MODELS**: Non-volatile architecture, commands, module exports, and durable rules. Read this once per new chat instead of cold-scanning the repository. Use `recall where <symbol>` for exact line numbers and `recall context "<topic>"` for deeper history.

## 1. Identity & Tech Stack
- **Project**: `notes`
- **Purpose**: Tack Tactile Note-Taking, Flowchart Whiteboards, Sticky Notes & Clipboard Management for Android Built with Flutter & Dart
- **Stack**: Flutter / Dart

## 3. Non-Volatile Rules, Decisions & Invariants
- **[decision] Locked Product & Navigation Rules**: Notes view in Tack is GRID ONLY (no list-view mode or toggle anywhere). No redundant buttons on the same screen. Note navigation follows ... _(mem_001)_
- **[design_system] Centralized TackTokens, Typography & Touch Targets**: All widgets must use context.tokens (TackTokens: canvasPrimary, surfacePrimary, canvasSunken, textPrimary, textSecondary, textTertiary, b... _(mem_002)_
- **[convention] Settings Copy & Privacy Legal Coverage**: Keep ProfileSettingsScreen rows minimal without section subheadings or verbose subtitles (All files, Trash, Export backup, Restore backup... _(mem_003)_
- **[lesson] Notification Permission Rationale & Headless Test Guard**: Guard ensureNotificationPermissionWithRationale calls in TaskReminderSheet with !kIsWeb && Platform.isAndroid, avoid showing an infinite ... _(mem_004)_
- **[bugfix] Cross-Screen UX & Search Filter Invariants**: Library filter bar scrolls with CustomScrollView and clips within viewport; TodayScreen groups tasks by noteId (separating identically ti... _(mem_005)_
- **[convention] Verified Test & Kotlin Build Commands**: Verify Flutter widget/unit tests with flutter test (59 passing tests covering card_grid_layout_test.dart, latex_math_test.dart, phase2_ui... _(mem_006)_
- **[bugfix] Composited fade-out transitions via TackAnimatedTransition**: In Flutter CurvedAnimation, reverse evaluation calls activeCurve.transform(parent.value) directly as t drops from 1.0 to 0.0 (not 1 - cur... _(mem_007)_

## 4. Core Modules & Exported Surface
- `lib/core/constants/app_constants.dart`: `AppConstants`
- `lib/core/routing/app_router.dart`: `TackRootNavigator`
- `lib/core/services/pinned_notification_service.dart`: `PinnedNotificationService`
- `lib/core/services/process_text_service.dart`: `IncomingTextData`, `ProcessTextService`
- `lib/core/services/task_reminder_service.dart`: `TaskReminderPayload`, `TaskReminderService`
- `lib/core/theme/app_colors.dart`: `AppColors`, `TackColorPalette`
- `lib/core/theme/app_spacing.dart`: `AppSpacing`
- `lib/core/theme/app_theme.dart`: `AppTheme`, `TackAnimatedTransition`, `AppInputDecorations`
- `lib/core/theme/app_typography.dart`: `AppTypography`
- `lib/core/theme/smooth_border.dart`: `SmoothRectangleBorder`
- `lib/core/theme/tack_icons.dart`: `TackSvgIcon`, `TackIcons`, `TackIcon`, `TackPinBadge`
- `lib/core/theme/theme_provider.dart`: `ThemeProvider`
- `lib/core/utils/date_formatter.dart`: `DateFormatter`
- `lib/core/utils/url_launcher_helper.dart`: `UrlLauncherHelper`
- `lib/features/about/screens/about_tack_screen.dart`: `AboutTackScreen`
- `lib/features/about/widgets/release_notes_tab.dart`: `ReleaseNotesTab`
- `lib/features/folders/screens/folder_view_screen.dart`: `FolderViewScreen`
- `lib/features/graph/screens/knowledge_graph_screen.dart`: `KnowledgeGraphScreen`
- `lib/features/home/screens/home_screen.dart`: `HomeScreen`
- `lib/features/notes/models/text_note.dart`: `TextNote`
- `lib/features/notes/screens/note_editor_screen.dart`: `NoteEditorScreen`
- `lib/features/notes/services/block_transform_service.dart`: `BlockTransformService`
- `lib/features/notes/services/frontmatter_service.dart`: `ParsedNoteFrontmatter`, `FrontmatterService`
- `lib/features/notes/services/latex_math_service.dart`: `ParsedInlineMath`, `ParsedBlockMath`, `LatexMathService`
- `lib/features/notes/services/markdown_table_service.dart`: `EditableMarkdownTable`, `MarkdownTableService`
- _... (64 more modules — query `recall where <name>`)_
<!-- recall:passport:end -->
