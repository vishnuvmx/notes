# Tack Dart Application Architecture (`lib/`)

This directory contains the cross-platform Dart code for the **Tack** application. The codebase is organized into distinct layers to separate business logic, data persistence, and user interface concerns.

---

## 📂 Directory Layout

```
lib/
├── main.dart             # Application entry point and Provider tree initialization
├── core/                 # Shared foundations and design system tokens
│   ├── theme/            # Colors, typography, spacing, and icon mapping
│   └── utils/            # Date formatting, geometry helpers, and URL launchers
├── domain/               # Core business abstractions and data models
│   ├── interfaces/       # Repository and storage contracts (IWorkspaceRepository, IStorageDriver)
│   ├── models/           # Domain entities (BaseWorkspaceItem, TextNote, StickyNote, Whiteboard, Clipboard)
│   └── services/         # Platform integration services (shortcuts, text processing, export, notifications)
├── data/                 # Concrete storage implementations
│   ├── mock/             # Default initial items for first-launch onboarding
│   └── repositories/     # LocalStorageWorkspaceRepository (SharedPreferences + JSON serialization)
├── state/                # Reactive state controllers
│   ├── theme_provider.dart       # Dark, light, and system theme switching
│   └── workspace_provider.dart   # Workspace CRUD, search, filter, and backup operations
└── ui/                   # Visual presentation layer
    ├── components/       # Atomic widgets: cards, toolbars, app bars, dialogs, inputs, navigation
    └── screens/          # Full application screens (Home, Note Editor, Whiteboard Canvas, Settings)
```

---

## 🏛️ Core Architectural Patterns

### 1. Domain Modeling & Polymorphism
All workspace elements inherit from the abstract base class `BaseWorkspaceItem`:

```
               ┌────────────────────────┐
               │   BaseWorkspaceItem    │
               │      (abstract)        │
               └───────────┬────────────┘
                           │
       ┌───────────────────┼───────────────────┐
       ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐
│   TextNote   │    │  StickyNote  │    │ WhiteboardCanvasItem │
└──────────────┘    └──────────────┘    └──────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ClipboardItem │
                    └──────────────┘
```

- **`BaseWorkspaceItem`**: Declares universal properties (`id`, `title`, `createdAt`, `updatedAt`, `paletteId`, `isFavorite`, `isArchived`, `isTrash`) and methods (`getSummary()`, `matchesQuery()`, `toJson()`, `copyWith()`).
- **`TextNote`**: Encapsulates rich Markdown content, extracted tags, word/character metrics, and reading time estimation.
- **`StickyNote`**: Encapsulates rapid reminders with rotational tilt and priority levels.
- **`WhiteboardCanvasItem`**: Composes a collection of `CanvasNode` entities and directional `CanvasEdge` connectors.
- **`ClipboardItem`**: Stores temporary and pinned clipboard snippets with app attribution.

### 2. Interface-Driven Data Persistence
- **`IWorkspaceRepository`**: Interface defining asynchronous operations for fetching, searching, archiving, favoriting, and deleting workspace items.
- **`LocalStorageWorkspaceRepository`**: Implementation that caches active items in memory for sub-millisecond retrieval while asynchronously persisting state as serialized JSON via `SharedPreferences`.

### 3. State Management
- **`WorkspaceProvider`** (ChangeNotifier): Mediates between UI and repository. Dispatches updates when notes are created, modified, searched, or restored.
- **`ThemeProvider`** (ChangeNotifier): Handles user preference for Light, Dark, or System brightness.

### 4. UI Layer Organization
- **Screens**:
  - `HomeScreen`: Hub displaying sticky note grids or notebook lists, category filter pills, and bottom navigation.
  - `NoteEditorScreen`: Markdown editor with live preview, syntax highlighting, formatting toolbar, and Mermaid diagrams.
  - `WhiteboardCanvasScreen`: Interactive 2D canvas with pan/zoom matrix, node creation palette, and snap-to-grid.
  - `SettingsScreen` & `AboutTackScreen`: Configuration, backup export/restore, and open-source attributions.
- **Components**: Grouped by function into `app_bars/`, `cards/`, `dialogs_sheets/`, `inputs/`, `navigation/`, and `toolbars/`.

---

## 🧪 Development Guidelines

- **Formatting**: Run `dart format .` before submitting code changes.
- **Linter Rules**: Verify adherence to rules configured in `analysis_options.yaml`.
- **Imports**: Use relative imports within `lib/` to maintain modularity.
- **Assets**: Reference icons and static images through `TackIcons` rather than hardcoding asset paths.
