<!-- recall:project-map:begin -->
# Project Map & Topology

> **AI AGENTS**: Use this blueprint to locate files directly. **DO NOT** execute recursive `list_dir` or crawl directories.

**Project Type**: Flutter / Dart

## Primary Entry Points
- `lib/main.dart`
- `web/index.html`

## Design System & Theme Tokens
When modifying UI components, reuse tokens from:
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_theme.dart`
## Large File Landmarks & Codebase API Surface (Direct Jump Targets)
> **AI AGENTS**: Do NOT grep inside these files or re-read them to discover APIs. Use these line numbers and symbol signatures directly.

### `lib/features/whiteboard/screens/whiteboard_canvas_screen.dart` (5,610 lines)
- **L34**: `CanvasSnapshot` (class)
- **L46**: `CanvasHistoryManager` (class)
- **L54**: `recordSnapshot` (method)
- **L62**: `undo` (method)
- **L69**: `redo` (method)
- **L76**: `clear` (method)
- **L84**: `WhiteboardCanvasScreen` (class)
- **L95**: `computeNodesBounds` (method)
- **L159**: `createState` (method)
- **L162**: `_WhiteboardCanvasScreenState` (class)
- **L205**: `selectEdgeForTesting` (method)
- **L207**: `selectNodeForTesting` (method)
- **L209**: `branchFromNodeForTesting` (method)
- **L211**: `deleteEdgeForTesting` (method)
- **L219**: `toggleSnapToGridForTesting` (method)
- **L221**: `toggleMinimapForTesting` (method)

### `lib/features/notes/widgets/rich_note_content_view.dart` (3,741 lines)
- **L32**: `RichNoteNavigationController` (class)
- **L47**: `jumpToHeading` (method)
- **L57**: `RichNoteContentView` (class)
- **L84**: `createState` (method)
- **L87**: `_RichNoteContentViewState` (class)
- **L96**: `initState` (method)
- **L102**: `didUpdateWidget` (method)
- **L111**: `dispose` (method)
- **L117**: `_keyForHeading` (method)
- **L120**: `_unfoldCoveringSections` (method)
- **L156**: `_jumpToHeadingLine` (method)
- **L157**: `scrollToTarget` (method)
- **L191**: `_wrapHeadingTarget` (method)
- **L220**: `_wrapLineTap` (method)
- **L229**: `_toggleCheckbox` (method)
- **L240**: `build` (method)

### `lib/features/notes/screens/note_editor_screen.dart` (2,796 lines)
- **L50**: `NoteEditorScreen` (class)
- **L63**: `createState` (method)
- **L66**: `_NoteEditorScreenState` (class)
- **L93**: `initState` (method)
- **L137**: `_scrollToHeadingAnchor` (method)
- **L156**: `didChangeDependencies` (method)
- **L161**: `_buildUpdatedItem` (method)
- **L222**: `_flushSave` (method)
- **L232**: `didChangeAppLifecycleState` (method)
- **L244**: `dispose` (method)
- **L258**: `_toggleViewMode` (method)
- **L320**: `_handleBackPress` (method)
- **L343**: `_jumpToLineIndex` (method)
- **L378**: `_showDocumentOutlineSheet` (method)
- **L405**: `_isCursorInsideMermaidBlock` (method)
- **L416**: `_insertMermaidSnippet` (method)

### `lib/features/notes/widgets/mermaid/mermaid_diagram_card.dart` (2,050 lines)
- **L18**: `MermaidDiagramCard` (class)
- **L29**: `createState` (method)
- **L32**: `_MermaidDiagramCardState` (class)
- **L37**: `initState` (method)
- **L43**: `didUpdateWidget` (method)
- **L51**: `dispose` (method)
- **L58**: `_openInWhiteboard` (method)
- **L70**: `_convertToWhiteboardItem` (method)
- **L282**: `collectMindmap` (method)
- **L334**: `_computeErEntitiesForBoard` (method)
- **L342**: `build` (method)
- **L376**: `_buildRawCodeView` (method)
- **L401**: `_buildDiagramView` (method)
- **L454**: `_FlowchartLayoutResult` (class)
- **L554**: `subgraphChainKey` (method)
- **L706**: `depthOf` (method)

### `lib/features/notes/widgets/mermaid/mermaid_diagram_parser.dart` (1,498 lines)
- **L31**: `MermaidNode` (class)
- **L60**: `MermaidSubgraph` (class)
- **L75**: `MermaidEdge` (class)
- **L92**: `MermaidPieSlice` (class)
- **L103**: `MermaidSequenceMessage` (class)
- **L118**: `MermaidTimelineItem` (class)
- **L131**: `MermaidErAttribute` (class)
- **L146**: `MermaidErEntity` (class)
- **L161**: `MermaidErRelation` (class)
- **L180**: `MermaidGanttTask` (class)
- **L205**: `MermaidMindmapNode` (class)
- **L222**: `ParsedMermaidDiagram` (class)
- **L264**: `_MutableSubgraph` (class)
- **L276**: `addNode` (method)
- **L283**: `_MutableMindmapEntry` (class)
- **L299**: `freeze` (method)

### `lib/features/notes/widgets/mermaid/mermaid_extra_renderers.dart` (1,300 lines)
- **L23**: `_branchAccentColor` (method)
- **L32**: `MermaidErWidget` (class)
- **L45**: `build` (method)
- **L121**: `_buildEntityCard` (method)
- **L244**: `_buildKeyBadge` (method)
- **L273**: `_ErLayoutResult` (class)
- **L285**: `_computeErLayout` (method)
- **L359**: `_ErRelationPainter` (class)
- **L373**: `paint` (method)
- **L483**: `_drawStyledPath` (method)
- **L540**: `_drawLabelPill` (method)
- **L577**: `shouldRepaint` (method)
- **L584**: `MermaidGanttWidget` (class)
- **L602**: `build` (method)
- **L804**: `_rowsHeight` (method)
- **L812**: `_formatShortDate` (method)

### `lib/features/tasks/screens/today_screen.dart` (1,277 lines)
- **L37**: `TodayScreen` (class)
- **L46**: `createState` (method)
- **L49**: `_TodayScreenState` (class)
- **L78**: `build` (method)
- **L382**: `_TodaysDailyNoteCard` (class)
- **L398**: `build` (method)
- **L407**: `buildDailyBody` (method)
- **L555**: `_SegmentedTasksCard` (class)
- **L585**: `build` (method)
- **L893**: `_TaskRow` (class)
- **L907**: `build` (method)
- **L1096**: `_WorthRevisitingCard` (class)
- **L1104**: `build` (method)
- **L1203**: `_QuietEmptyBox` (class)
- **L1215**: `build` (method)

### `lib/features/settings/screens/settings_screen.dart` (1,219 lines)
- **L36**: `ProfileSettingsScreen` (class)
- **L45**: `createState` (method)
- **L51**: `_ProfileSettingsScreenState` (class)
- **L59**: `initState` (method)
- **L71**: `_onTabChanged` (method)
- **L81**: `dispose` (method)
- **L87**: `_loadProfileName` (method)
- **L97**: `_editProfileName` (method)
- **L116**: `_exportBackup` (method)
- **L187**: `_showRestoreDialog` (method)
- **L207**: `build` (method)
- **L807**: `_StatMetricPill` (class)
- **L819**: `build` (method)
- **L851**: `_ThemeSegmentedControl` (class)
- **L857**: `build` (method)
- **L925**: `_RestoreBackupDialog` (class)

### `lib/shared/providers/workspace_provider.dart` (1,123 lines)
- **L27**: `WorkspaceProvider` (class)
- **L41**: `_nextId` (method)
- **L67**: `_loadPrefsAndItems` (method)
- **L97**: `getItemById` (method)
- **L99**: `restoreItem` (method)
- **L267**: `_sortItemsList` (method)
- **L285**: `resolveEffectiveFolder` (method)
- **L304**: `getChildItems` (method)
- **L313**: `getBreadcrumbChain` (method)
- **L327**: `getItemByIdSync` (method)
- **L344**: `loadItems` (method)
- **L373**: `setBottomNavIndex` (method)
- **L378**: `setCategoryFilter` (method)
- **L383**: `setCategory` (method)
- **L385**: `setTagFilter` (method)
- **L394**: `setSelectedTag` (method)

### `lib/features/graph/screens/knowledge_graph_screen.dart` (1,118 lines)
- **L28**: `_GraphNode` (class)
- **L54**: `_GraphEdge` (class)
- **L69**: `KnowledgeGraphScreen` (class)
- **L79**: `createState` (method)
- **L82**: `_KnowledgeGraphScreenState` (class)
- **L101**: `initState` (method)
- **L111**: `dispose` (method)
- **L117**: `_centerCamera` (method)
- **L125**: `_rebuildGraphIfNeeded` (method)
- **L164**: `addEdge` (method)
- **L344**: `_handleCanvasTapUp` (method)
- **L364**: `_openNodeItem` (method)
- **L391**: `build` (method)
- **L850**: `_buildSelectedNodeDock` (method)
- **L938**: `_KnowledgeGraphPainter` (class)
- **L956**: `paint` (method)

### `lib/features/notes/widgets/slash_command_sheet.dart` (1,107 lines)
- **L24**: `SlashCommandItem` (class)
- **L44**: `SlashCommandsCatalog` (class)
- **L218**: `filter` (method)
- **L230**: `SlashCommandInlineBar` (class)
- **L243**: `build` (method)
- **L337**: `SlashAndBlockActionsSheet` (class)
- **L384**: `createState` (method)
- **L388**: `_SlashAndBlockActionsSheetState` (class)
- **L393**: `initState` (method)
- **L399**: `dispose` (method)
- **L405**: `build` (method)
- **L632**: `_selectInsertCommand` (method)
- **L638**: `_buildTransformTab` (method)
- **L725**: `_iconForBlockKind` (method)
- **L755**: `_ModeSegmentPill` (class)
- **L769**: `build` (method)

### `lib/features/notes/widgets/markdown_text_editing_controller.dart` (928 lines)
- **L8**: `MarkdownTextEditingController` (class)
- **L16**: `paletteId` (method)
- **L245**: `flush` (method)
- **L802**: `_isWhitespace` (method)
- **L808**: `_isWordChar` (method)
- **L810**: `_canOpenUnderscore` (method)

### `android/app/src/main/kotlin/com/notes/tacknotes/MainActivity.kt` (852 lines)
- **L24**: `MainActivity` (class)
- **L33**: `showQuickCaptureNotificationOn` (function)
- **L91**: `showFallbackStatusNotification` (function)
- **L149**: `onCreate` (function)
- **L156**: `enableHighRefreshRate` (function)
- **L179**: `onNewIntent` (function)
- **L185**: `configureFlutterEngine` (function)
- **L312**: `onDestroy` (function)
- **L321**: `hasNotificationPermission` (function)
- **L327**: `canScheduleExactAlarmsCompat` (function)
- **L333**: `requestNotificationPermissionWithResult` (function)
- **L350**: `onRequestPermissionsResult` (function)
- **L366**: `openAppNotificationSettings` (function)
- **L381**: `openAppExactAlarmSettings` (function)
- **L394**: `createNotificationChannels` (function)
- **L433**: `showQuickCaptureNotification` (function)

### `lib/features/home/screens/home_screen.dart` (785 lines)
- **L35**: `HomeScreen` (class)
- **L52**: `createState` (method)
- **L55**: `_HomeScreenState` (class)
- **L58**: `_openItem` (method)
- **L70**: `_openCaptureSheet` (method)
- **L83**: `_handleBottomNavTap` (method)
- **L96**: `_titleForTab` (method)
- **L111**: `_subtitleForTab` (method)
- **L124**: `_showSortSheet` (method)
- **L207**: `build` (method)
- **L337**: `_stackIndexForTab` (method)
- **L353**: `_LibraryView` (class)
- **L362**: `_showFolderSheet` (method)
- **L370**: `build` (method)
- **L382**: `resetAllFilters` (method)
- **L388**: `emptyTitle` (method)

### `lib/features/tasks/services/open_tasks_service.dart` (762 lines)
- **L15**: `TaskRecurrence` (class)
- **L39**: `parse` (method)
- **L93**: `toToken` (method)
- **L126**: `nextDueAfter` (method)
- **L220**: `_daysInMonth` (method)
- **L237**: `TaskToggleResult` (class)
- **L258**: `ParsedTaskMetadata` (class)
- **L274**: `DerivedTaskItem` (class)
- **L313**: `isDueToday` (method)
- **L322**: `isOverdue` (method)
- **L336**: `formatDueLabel` (method)
- **L371**: `_formatTime12h` (method)
- **L379**: `compareUrgency` (method)
- **L392**: `_urgencyBucket` (method)
- **L403**: `OpenTasksService` (class)
- **L531**: `formatDueToken` (method)

### `lib/features/notes/services/note_export_service.dart` (752 lines)
- **L17**: `NoteExportService` (class)

### `lib/features/about/screens/about_tack_screen.dart` (742 lines)
- **L12**: `AboutTackScreen` (class)
- **L16**: `createState` (method)
- **L19**: `_AboutTackScreenState` (class)
- **L25**: `initState` (method)
- **L31**: `_onTabChanged` (method)
- **L40**: `dispose` (method)
- **L47**: `build` (method)
- **L241**: `_buildStackJourneyTab` (method)
- **L316**: `_buildStageCard` (method)
- **L409**: `_buildPrivacyLegalTab` (method)
- **L521**: `_buildOpenSourceTab` (method)
- **L645**: `_buildPackageCard` (method)
- **L711**: `_JourneyStage` (class)
- **L727**: `_OssPackage` (class)

### `lib/features/notes/widgets/code_syntax_highlighter.dart` (720 lines)
- **L20**: `_PatternRule` (class)
- **L26**: `_LanguageSpec` (class)
- **L46**: `_CompiledGrammar` (class)
- **L61**: `CodeSyntaxHighlighter` (class)
- **L77**: `_normalizeLanguage` (method)
- **L161**: `_grammarFor` (method)
- **L167**: `_buildSpec` (method)
- **L695**: `_isFollowedByCallParen` (method)
- **L708**: `_isPascalCase` (method)

### `lib/features/notes/widgets/frontmatter_properties_bar.dart` (718 lines)
- **L20**: `FrontmatterPropertiesBar` (class)
- **L34**: `_cycleOrPickStatus` (method)
- **L44**: `_cyclePriority` (method)
- **L54**: `_clampDate` (method)
- **L60**: `_pickTargetDate` (method)
- **L86**: `build` (method)
- **L246**: `_PropertyPill` (class)
- **L268**: `build` (method)
- **L309**: `FrontmatterEditorSheet` (class)
- **L338**: `createState` (method)
- **L341**: `_FrontmatterEditorSheetState` (class)
- **L349**: `initState` (method)
- **L357**: `dispose` (method)
- **L363**: `_commit` (method)
- **L367**: `_setProp` (method)
- **L378**: `_addCustomField` (method)

### `lib/features/search/screens/search_command_screen.dart` (708 lines)
- **L24**: `SearchCommandScreen` (class)
- **L33**: `createState` (method)
- **L36**: `_SearchCommandScreenState` (class)
- **L41**: `dispose` (method)
- **L46**: `_buildCommands` (method)
- **L129**: `build` (method)
- **L489**: `_SearchGroupCard` (class)
- **L495**: `build` (method)
- **L515**: `_CommandEntry` (class)
- **L529**: `_GroupHeader` (class)
- **L535**: `build` (method)
- **L550**: `_CommandRow` (class)
- **L556**: `build` (method)
- **L613**: `_SearchResultItemRow` (class)
- **L625**: `build` (method)

### `lib/shared/widgets/create_item_sheet.dart` (660 lines)
- **L25**: `CreateItemSheet` (class)
- **L43**: `createState` (method)
- **L46**: `_CreateItemSheetState` (class)
- **L58**: `initState` (method)
- **L77**: `_loadTemplates` (method)
- **L85**: `dispose` (method)
- **L98**: `_handleSaveToInbox` (method)
- **L137**: `_handleOpenAsNote` (method)
- **L204**: `_handleNewBoard` (method)
- **L235**: `_handlePasteClipboard` (method)
- **L272**: `build` (method)
- **L606**: `_QuietCaptureOption` (class)
- **L620**: `build` (method)

### `lib/features/notes/widgets/whiteboard_embed_card.dart` (589 lines)
- **L16**: `WorkspaceEmbedCard` (class)
- **L31**: `build` (method)
- **L47**: `_buildUnresolvedCard` (method)
- **L345**: `_buildTranscludedLine` (method)
- **L461**: `_MiniWhiteboardPreviewPainter` (class)
- **L473**: `paint` (method)
- **L582**: `shouldRepaint` (method)

### `lib/core/theme/app_colors.dart` (587 lines)
- **L10**: `AppColors` (class)
- **L47**: `Dark Semantic Tokens (Soft Carbon Monochrome)` (section)
- **L81**: `State Tokens (Light & Dark)` (section)
- **L94**: `Backwards-Compatible Token Aliases` (section)
- **L256**: `normalizePaletteId` (method)
- **L268**: `getPaletteById` (method)
- **L279**: `getPaletteByColor` (method)
- **L290**: `getHighlightColor` (method)
- **L298**: `tryParseHexColor` (method)
- **L321**: `TackColorPalette` (class)
- **L341**: `resolveFill` (method)
- **L344**: `resolveBandColor` (method)
- **L346**: `resolveCardColor` (method)
- **L347**: `resolveSoftBackground` (method)
- **L349**: `resolveTextColor` (method)
- **L353**: `resolveAccentColor` (method)

### `lib/core/theme/app_theme.dart` (550 lines)
- **L9**: `AppTheme` (class)
- **L12**: `Light Theme ("Paper & Pin")` (section)
- **L182**: `Dark Theme (Warm Charcoal)` (section)
- **L355**: `_TackFadePageTransitionsBuilder` (class)
- **L377**: `TackAnimatedTransition` (class)
- **L410**: `switcherTransition` (method)
- **L418**: `createState` (method)
- **L421**: `_TackAnimatedTransitionState` (class)
- **L428**: `initState` (method)
- **L434**: `didUpdateWidget` (method)
- **L449**: `_initAnimations` (method)
- **L489**: `_disposeAnimations` (method)
- **L496**: `dispose` (method)
- **L502**: `build` (method)
- **L527**: `AppInputDecorations` (class)
- **L543**: `bareWithHint` (method)

### `lib/features/about/widgets/release_notes_tab.dart` (531 lines)
- **L21**: `_ReleaseEntry` (class)
- **L43**: `ReleaseNotesTab` (class)
- **L47**: `createState` (method)
- **L50**: `_ReleaseNotesTabState` (class)
- **L185**: `build` (method)
- **L251**: `_buildHeroReleaseBanner` (method)
- **L344**: `_buildMetricChip` (method)
- **L362**: `_buildReleaseCard` (method)
- **L476**: `_buildPreviousVersionCard` (method)


## Directory Topology
| Directory | Files | Primary Extensions |
| :--- | :--- | :--- |
| `android/` | 8 | .kts, .properties, .bat |
| `android/app/` | 1 | .kts |
| `android/app/src/` | 0 | - |
| `android/gradle/` | 0 | - |
| `android/gradle/wrapper/` | 2 | .jar, .properties |
| `assets/` | 0 | - |
| `assets/images/` | 0 | - |
| `assets/images/onboarding/` | 4 | .jpg |
| `docs/` | 0 | - |
| `docs/design/` | 11 | .md |
| `docs/design/onboarding-references/` | 7 | .jpg, .png, .md |
| `icons/` | 18 | .svg |
| `icons/dark-icons/` | 112 | .svg |
| `icons/white-icons/` | 112 | .svg |
| `lib/` | 2 | .dart, .md |
| _... (28 more subdirectories)_ | - | _(use targeted live search)_ |

## Directory Tree (Top Levels)
```text
|-- android/
|   |-- app/
|   |   |-- src/
|   |   |   |-- debug/
|   |   |   |-- main/
|   |   |   \-- profile/
|   |-- gradle/
|   |   \-- wrapper/
|   |-- .gitignore
|   |-- build.gradle.kts
|   |-- gradle.properties
|   |-- gradlew
|   |-- gradlew.bat
|   |-- local.properties
|   \-- ... (2 more files)
|-- assets/
|   \-- images/
|       \-- onboarding/
|-- docs/
|   \-- design/
|       |-- onboarding-references/
|-- icons/
|   |-- dark-icons/
|   |-- white-icons/
|   |-- icon-clipboard.svg
|   |-- icon-connector.svg
|   |-- icon-copy.svg
|   |-- icon-draw.svg
|   |-- icon-edit.svg
|   |-- icon-eye.svg
|   \-- ... (12 more files)
|-- lib/
|   |-- core/
|   |   |-- constants/
|   |   |-- routing/
|   |   |-- services/
|   |   |-- theme/
|   |   \-- utils/
|   |-- features/
|   |   |-- about/
|   |   |   |-- screens/
|   |   |   \-- widgets/
|   |   |-- folders/
|   |   |   \-- screens/
|   |   |-- graph/
|   |   |   \-- screens/
|   |   |-- home/
|   |   |   \-- screens/
|   |   |-- notes/
|   |   |   |-- models/
|   |   |   |-- screens/
|   |   |   |-- services/
|   |   |   \-- widgets/
|   |   |-- onboarding/
|   |   |   |-- screens/
|   |   |   \-- widgets/
|   |   |-- search/
|   |   |   \-- screens/
|   |   |-- settings/
|   |   |   \-- screens/
|   |   |-- tasks/
|   |   |   |-- screens/
|   |   |   |-- services/
|   |   |   \-- widgets/
|   |   \-- whiteboard/
|   |       |-- models/
|   |       |-- screens/
|   |       \-- widgets/
|   |-- shared/
|   |   |-- data/
|   |   |-- models/
|   |   |-- providers/
|   |   \-- widgets/
|   |-- main.dart
|   \-- README.md
|-- web/
|   |-- icons/
|   |-- favicon.png
|   |-- index.html
|   \-- manifest.json
|-- windows/
|   |-- flutter/
|   |-- runner/
|   |   |-- resources/
|   |-- .gitignore
|   \-- CMakeLists.txt
|-- .gitignore
|-- .metadata
|-- AGENTS.md
|-- analysis_options.yaml
|-- AUDIT.md
|-- CONTRIBUTING.md
\-- ... (6 more files)
```
<!-- recall:project-map:end -->
