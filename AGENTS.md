# Project Context & Design System Guidelines: Tack (Android Flutter)

## 0. Locked Product Decisions (READ BEFORE EVERY FUTURE CHANGE)

These product and engineering decisions are **strictly locked**. Never violate or regress them in any future change:

1. **Notes view is GRID ONLY**:
   - There must be NO grid/list toggle, tab, or setting anywhere in the app.
   - All list-view code, state (`HomeViewMode`), UI toggles (`_ViewModeSegment`, Settings switch), and persisted preferences (`home_view_mode`) must be removed.
2. **No redundant buttons**:
   - Every control on a screen must have a unique, necessary purpose.
   - If a feature is reachable in two places on the same screen, keep only one canonical control.
3. **Navigation hierarchy (`Home → Read mode → Edit mode`)**:
   - Opening a note from Home enters **Read mode** (or Edit mode for a newly created blank note, where Back still transitions to Read mode or pops cleanly as specified).
   - Pressing Back from **Edit mode** returns to **Read mode** (flushing auto-save).
   - Pressing Back from **Read mode** returns to **Home** (or the previous route).
4. **Single source of truth for design tokens**:
   - All colors, spacing, radii, and text styles must come from the centralized theme/design-token files (`lib/core/theme/`).
   - No hardcoded `Color(0x...)`, magic spacing/radius numbers, or inline `TextStyle` definitions in widgets.
5. **Future Locked Decisions**:
   - Any additional product decisions confirmed by the user must be appended here immediately before implementation.

---

## Project Overview

**Tack** is an Android-first, tactile, modern note-taking, whiteboard flowchart, sticky notes, and clipboard management app built with Flutter. The app features a playful and modern personality (with brand icon `icon.png`). It reimagines desktop sticky note and notebook interfaces into an ergonomic mobile experience.

---

## 1. Design System Tokens & Guidelines

- **Typography**: `DM Sans` used across all text hierarchy. Apply ~-2% letter spacing (`letterSpacing: -0.3` to `-0.6`) for sleek, modern readability. Avoid default Roboto/Material generic typography.
- **Color Palette**:
  - Light Surface: `#F8F9FA`, Card: `#FFFFFF`, Primary Text: `#191A23`
  - Dark Surface: `#121316`, Card: `#1E1F24`, Primary Text: `#F4F4F6`
  - 8 Curated Sticky Pastels:
    1. _Sunset Peach_: `#FF8F6B` (Light) / `#7A3622` (Dark)
    2. _Warm Amber_: `#F5B842` (Light) / `#755214` (Dark)
    3. _Coral Blush_: `#E05D5D` (Light) / `#6B2323` (Dark)
    4. _Lavender Mist_: `#9D84D6` (Light) / `#43326B` (Dark)
    5. _Cyan Breeze_: `#1BA5BA` (Light) / `#0C4F5A` (Dark)
    6. _Lime Zing_: `#B2CD4D` (Light) / `#4D5C1A` (Dark)
    7. _Rose Bubble_: `#F48FB1` (Light) / `#732A46` (Dark)
    8. _Slate Pure_: `#E2E8F0` (Light) / `#2D3748` (Dark)
- **Iconography**: `HeroIcons` (`heroicons` package via `TackIcon`) with cute rounded caps, soft line weights, and outline/solid style pairings. Avoid generic sharp Material default icons.
- **Radii & Elevation**:
  - Radii: 8dp (sm), 16dp (md - cards/buttons), 24dp (lg - sheets/dialogs), 999dp (pill).
  - Shadows: Soft, diffused drop shadows (`blurRadius: 12-20`, opacity `0.06 - 0.12`).
  - Touch Targets: Minimum 48x48 dp for interactive elements.

---

## 2. Component Inventory

- **App Bars**: `AppHeaderBar` (home/feed), `EditorAppBar` (note editor with auto-save pill), `CanvasAppBar` (whiteboard with undo/redo/share).
- **Cards**:
  - `NeoNoteCard` & `StickyNoteCard`: Colorful rounded grid cards with smooth press elevation.
  - `ClipboardCard`: Snippet previews with copy action.
- **Toolbars**:
  - `EditorFormattingToolbar`: Keyboard-docked rich text formatting toolbar.
  - `CanvasToolRail` & `CanvasNodePalette`: Floating whiteboard tools and flowchart node palette (Start/End, Process, Decision, I/O, Connector).
- **Dialogs & Sheets**:
  - `CreateItemSheet`: Native bottom sheet for fast creation of notes, stickies, whiteboards, or clips with color selector.
  - `ColorSwatchPicker`: Interactive color selector.
- **Navigation**:
  - `SmartBottomNavBar`: 5-destination bottom navigation (Home, Notes, (+) FAB, Whiteboard, Clipboard).
  - `AppNavDrawer`: Secondary destinations (All, Favorites, Archive, Trash, Settings).

---

## 3. Object-Oriented Architecture (OOP Principles)

The domain layer demonstrates clear Java/Dart OOP concepts:

1. **Abstraction & Interfaces**:
   - `abstract class BaseWorkspaceItem`: Base class for all workspace items (`id`, `title`, `createdAt`, `colorValue`, `isFavorite`, `isArchived`, `isTrash`, `getSummary()`, `copyWith()`, `toJson()`).
   - `abstract class IWorkspaceRepository`: Contract for CRUD, query, and folder management.
   - `abstract class IStorageDriver`: Storage abstraction.
2. **Inheritance & Polymorphism**:
   - `TextNote extends BaseWorkspaceItem`: Content, tags, word/letter counters.
   - `StickyNote extends BaseWorkspaceItem`: Pinned rotation, priority.
   - `WhiteboardCanvasItem extends BaseWorkspaceItem`: Composed with `CanvasNode` & `CanvasEdge`.
   - `ClipboardItem extends BaseWorkspaceItem`: Raw text, source app, pin state.
   - All subclasses are handled polymorphically in search, trash, archive, and feeds.
3. **Encapsulation**:
   - State and data stores maintain private members with public immutable getters and pure updater methods.
4. **Composition**:
   - `WorkspaceService` orchestrates `IWorkspaceRepository` and `IStorageDriver`.
   - `WhiteboardCanvasItem` composes node elements, connectors, and canvas transformations.

---

## 4. Feature-First Directory Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/ (app_constants)
│   ├── routing/ (app_router)
│   ├── services/ (pinned_notification_service, process_text_service)
│   ├── theme/ (app_colors, app_typography, app_spacing, app_theme, smooth_border, tack_icons, theme_provider)
│   └── utils/ (date_formatter, url_launcher_helper)
├── shared/
│   ├── data/ (i_workspace_repo, workspace_repo_impl, mock_initial_data)
│   ├── models/ (base_item, sticky_note, clipboard_item, item_serializer)
│   ├── providers/ (workspace_provider)
│   └── widgets/ (app_header_bar, neo_note_card, responsive_card_grid, smart_bottom_nav_bar, sheets, dialogs, inputs)
└── features/
    ├── about/ (screens/about_tack_screen, widgets/release_notes_tab)
    ├── folders/ (screens/folder_view_screen)
    ├── graph/ (screens/knowledge_graph_screen)
    ├── home/ (screens/home_screen)
    ├── notes/ (models/text_note, screens/note_editor_screen, services/*, widgets/*, widgets/mermaid/*)
    ├── search/ (screens/search_command_screen)
    ├── settings/ (screens/settings_screen)
    ├── tasks/ (screens/today_screen, services/open_tasks_service)
    └── whiteboard/ (models/whiteboard_item, screens/whiteboard_canvas_screen, widgets/board_grid_card)
```
