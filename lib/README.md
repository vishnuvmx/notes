# Tack Dart Application Architecture (`lib/`)

This directory contains the cross-platform Dart code for **Tack**, organized using a clean, beginner-friendly **feature-first architecture**.

---

## 📂 Directory Layout

```
lib/
├── main.dart                  # Application entry point & Provider tree initialization
├── core/                      # Core foundations, design tokens, routing, and platform services
│   ├── constants/             # AppConstants (channel names, version, text scale bounds)
│   ├── routing/               # TackRootNavigator & Android intent routing (app_router.dart)
│   ├── services/              # PinnedNotificationService & ProcessTextService
│   ├── theme/                 # AppColors, AppSpacing, AppTheme, AppTypography, SmoothBorder, TackIcons, ThemeProvider
│   └── utils/                 # DateFormatter & UrlLauncherHelper
├── shared/                    # Shared workspace state, persistence, models, and reusable UI widgets
│   ├── data/                  # IWorkspaceRepository, LocalStorageWorkspaceRepository, MockInitialData
│   ├── models/                # BaseWorkspaceItem, StickyNote, ClipboardItem, ItemSerializer
│   ├── providers/             # WorkspaceProvider (ChangeNotifier)
│   └── widgets/               # Reusable cross-feature widgets (NeoNoteCard, SmartBottomNavBar, AppHeaderBar, sheets, dialogs)
└── features/                  # Self-contained feature modules
    ├── about/
    │   ├── screens/           # AboutTackScreen
    │   └── widgets/           # ReleaseNotesTab
    ├── folders/
    │   └── screens/           # FolderViewScreen (Favorites, Archive, Trash)
    ├── graph/
    │   └── screens/           # KnowledgeGraphScreen
    ├── home/
    │   └── screens/           # HomeScreen (5-slot navigation shell)
    ├── notes/
    │   ├── models/            # TextNote
    │   ├── screens/           # NoteEditorScreen (Read -> Edit hierarchy)
    │   ├── services/          # BlockTransform, Frontmatter, MarkdownTable, NoteExport, NoteTemplate, WikiLink
    │   └── widgets/           # RichNoteContentView, EditorFormattingToolbar, Mermaid renderers, editor sheets
    ├── search/
    │   └── screens/           # SearchCommandScreen
    ├── settings/
    │   └── screens/           # SettingsScreen
    ├── tasks/
    │   ├── screens/           # TodayScreen (Daily focus & open tasks)
    │   └── services/          # OpenTasksService
    └── whiteboard/
        ├── models/            # WhiteboardCanvasItem, CanvasNode, CanvasEdge
        ├── screens/           # WhiteboardCanvasScreen
        └── widgets/           # BoardGridCard
```
