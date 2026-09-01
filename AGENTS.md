# Project Context & Design System Guidelines: Tack (Android Flutter)

## Project Overview
**Tack** is an Android-first, tactile, modern note-taking, whiteboard flowchart, sticky notes, and clipboard management app built with Flutter. The app features a playful and modern personality (with brand icon `icon.png`). It reimagines desktop sticky note and notebook interfaces into an ergonomic mobile experience.

---

## 1. Design System Tokens & Guidelines
- **Typography**: `DM Sans` used across all text hierarchy. Apply ~-2% letter spacing (`letterSpacing: -0.3` to `-0.6`) for sleek, modern readability. Avoid default Roboto/Material generic typography.
- **Color Palette**:
  - Light Surface: `#F8F9FA`, Card: `#FFFFFF`, Primary Text: `#191A23`
  - Dark Surface: `#121316`, Card: `#1E1F24`, Primary Text: `#F4F4F6`
  - 8 Curated Sticky Pastels:
    1. *Sunset Peach*: `#FF8F6B` (Light) / `#7A3622` (Dark)
    2. *Warm Amber*: `#F5B842` (Light) / `#755214` (Dark)
    3. *Coral Blush*: `#E05D5D` (Light) / `#6B2323` (Dark)
    4. *Lavender Mist*: `#9D84D6` (Light) / `#43326B` (Dark)
    5. *Cyan Breeze*: `#1BA5BA` (Light) / `#0C4F5A` (Dark)
    6. *Lime Zing*: `#B2CD4D` (Light) / `#4D5C1A` (Dark)
    7. *Rose Bubble*: `#F48FB1` (Light) / `#732A46` (Dark)
    8. *Slate Pure*: `#E2E8F0` (Light) / `#2D3748` (Dark)
- **Iconography**: `HeroIcons` (`heroicons` package via `TackIcon`) with cute rounded caps, soft line weights, and outline/solid style pairings. Avoid generic sharp Material default icons.
- **Radii & Elevation**:
  - Radii: 8dp (sm), 16dp (md - cards/buttons), 24dp (lg - sheets/dialogs), 999dp (pill).
  - Shadows: Soft, diffused drop shadows (`blurRadius: 12-20`, opacity `0.06 - 0.12`).
  - Touch Targets: Minimum 48x48 dp for interactive elements.


---

## 2. Component Inventory
- **App Bars**: `AppHeaderBar` (home/feed), `EditorAppBar` (note editor with auto-save pill), `CanvasAppBar` (whiteboard with undo/redo/share).
- **Cards**:
  - `StickyNoteCard`: Colorful rounded cards with smooth press elevation.
  - `SmartNoteListCard`: Tactile spiral notebook spine layout with large colored index numbers (`01`, `02`...).
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

## 4. Layered Directory Structure
```
lib/
├── core/
│   ├── theme/ (app_colors, app_typography, app_spacing, app_theme)
│   └── utils/
├── domain/
│   ├── models/ (base_item, text_note, sticky_note, whiteboard_item, clipboard_item)
│   ├── interfaces/ (i_workspace_repo, i_storage_driver)
│   └── services/ (workspace_service)
├── data/
│   ├── repositories/ (workspace_repo_impl)
│   └── mock/ (mock_initial_data)
├── state/ (workspace_provider, theme_provider)
└── ui/
    ├── components/ (app_bars, cards, dialogs_sheets, inputs, toolbars, navigation, whiteboard)
    └── screens/ (home, editor, whiteboard, sticky_board, clipboard, folders, settings)
```
