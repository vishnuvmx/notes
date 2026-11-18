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

### `lib/features/whiteboard/screens/whiteboard_canvas_screen.dart` (5,631 lines)
- **L33**: `CanvasSnapshot` (class)
- **L45**: `CanvasHistoryManager` (class)
- **L53**: `recordSnapshot` (method)
- **L61**: `undo` (method)
- **L68**: `redo` (method)
- **L75**: `clear` (method)
- **L83**: `WhiteboardCanvasScreen` (class)
- **L94**: `computeNodesBounds` (method)
- **L158**: `createState` (method)
- **L161**: `_WhiteboardCanvasScreenState` (class)
- **L204**: `selectEdgeForTesting` (method)
- **L206**: `selectNodeForTesting` (method)
- **L208**: `branchFromNodeForTesting` (method)
- **L210**: `deleteEdgeForTesting` (method)
- **L218**: `toggleSnapToGridForTesting` (method)
- **L220**: `toggleMinimapForTesting` (method)

### `lib/features/notes/widgets/rich_note_content_view.dart` (3,580 lines)
- **L34**: `RichNoteContentView` (class)
- **L59**: `createState` (method)
- **L62**: `_RichNoteContentViewState` (class)
- **L77**: `_wrapLineTap` (method)
- **L86**: `_toggleCheckbox` (method)
- **L97**: `build` (method)
- **L596**: `_buildLineWidget` (method)
- **L1195**: `_buildMacDot` (method)
- **L1216**: `parseCells` (method)
- **L1504**: `_buildImageError` (method)
- **L1615**: `flushBuffer` (method)
- **L2150**: `_isWhitespace` (method)
- **L2156**: `_isWordChar` (method)
- **L2158**: `_canOpenUnderscore` (method)
- **L2669**: `_buildHashTokenSpan` (method)
- **L2865**: `_isNonDefinitionTermLine` (method)

### `lib/features/notes/screens/note_editor_screen.dart` (2,745 lines)
- **L50**: `NoteEditorScreen` (class)
- **L63**: `createState` (method)
- **L66**: `_NoteEditorScreenState` (class)
- **L91**: `initState` (method)
- **L135**: `_scrollToHeadingAnchor` (method)
- **L154**: `didChangeDependencies` (method)
- **L159**: `_buildUpdatedItem` (method)
- **L220**: `_flushSave` (method)
- **L230**: `didChangeAppLifecycleState` (method)
- **L242**: `dispose` (method)
- **L256**: `_toggleViewMode` (method)
- **L318**: `_handleBackPress` (method)
- **L341**: `_jumpToLineIndex` (method)
- **L369**: `_showDocumentOutlineSheet` (method)
- **L396**: `_isCursorInsideMermaidBlock` (method)
- **L407**: `_insertMermaidSnippet` (method)

### `lib/features/notes/widgets/mermaid/mermaid_diagram_card.dart` (2,052 lines)
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
- **L403**: `_buildDiagramView` (method)
- **L456**: `_FlowchartLayoutResult` (class)
- **L556**: `subgraphChainKey` (method)
- **L708**: `depthOf` (method)

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

### `lib/features/tasks/screens/today_screen.dart` (1,231 lines)
- **L36**: `TodayScreen` (class)
- **L45**: `createState` (method)
- **L48**: `_TodayScreenState` (class)
- **L77**: `build` (method)
- **L384**: `_TodaysDailyNoteCard` (class)
- **L400**: `build` (method)
- **L542**: `_SegmentedTasksCard` (class)
- **L572**: `build` (method)
- **L851**: `_TaskRow` (class)
- **L865**: `build` (method)
- **L1054**: `_WorthRevisitingCard` (class)
- **L1064**: `build` (method)
- **L1164**: `_QuietEmptyBox` (class)
- **L1176**: `build` (method)

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

### `lib/features/graph/screens/knowledge_graph_screen.dart` (1,145 lines)
- **L27**: `_GraphNode` (class)
- **L53**: `_GraphEdge` (class)
- **L68**: `KnowledgeGraphScreen` (class)
- **L78**: `createState` (method)
- **L81**: `_KnowledgeGraphScreenState` (class)
- **L100**: `initState` (method)
- **L110**: `dispose` (method)
- **L116**: `_centerCamera` (method)
- **L124**: `_rebuildGraphIfNeeded` (method)
- **L163**: `addEdge` (method)
- **L343**: `_handleCanvasTapUp` (method)
- **L363**: `_openNodeItem` (method)
- **L390**: `build` (method)
- **L877**: `_buildSelectedNodeDock` (method)
- **L965**: `_KnowledgeGraphPainter` (class)
- **L983**: `paint` (method)

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

### `lib/features/home/screens/home_screen.dart` (826 lines)
- **L34**: `HomeScreen` (class)
- **L51**: `createState` (method)
- **L54**: `_HomeScreenState` (class)
- **L57**: `_openItem` (method)
- **L69**: `_openCaptureSheet` (method)
- **L82**: `_handleBottomNavTap` (method)
- **L95**: `_titleForTab` (method)
- **L110**: `_subtitleForTab` (method)
- **L123**: `_showSortSheet` (method)
- **L206**: `build` (method)
- **L336**: `_stackIndexForTab` (method)
- **L352**: `_LibraryView` (class)
- **L361**: `_showFolderSheet` (method)
- **L369**: `build` (method)
- **L381**: `resetAllFilters` (method)
- **L387**: `emptyTitle` (method)

### `lib/features/notes/widgets/slash_command_sheet.dart` (773 lines)
- **L14**: `SlashCommandItem` (class)
- **L34**: `SlashCommandsCatalog` (class)
- **L203**: `filter` (method)
- **L215**: `SlashCommandInlineBar` (class)
- **L228**: `build` (method)
- **L318**: `SlashAndBlockActionsSheet` (class)
- **L365**: `createState` (method)
- **L368**: `_SlashAndBlockActionsSheetState` (class)
- **L373**: `initState` (method)
- **L379**: `dispose` (method)
- **L385**: `build` (method)
- **L743**: `_iconForBlockKind` (method)

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

### `lib/features/notes/widgets/frontmatter_properties_bar.dart` (728 lines)
- **L21**: `FrontmatterPropertiesBar` (class)
- **L35**: `_statusColor` (method)
- **L49**: `_cycleOrPickStatus` (method)
- **L59**: `_cyclePriority` (method)
- **L69**: `_clampDate` (method)
- **L75**: `_pickTargetDate` (method)
- **L101**: `build` (method)
- **L251**: `_PropertyPill` (class)
- **L275**: `build` (method)
- **L319**: `FrontmatterEditorSheet` (class)
- **L348**: `createState` (method)
- **L351**: `_FrontmatterEditorSheetState` (class)
- **L359**: `initState` (method)
- **L367**: `dispose` (method)
- **L373**: `_commit` (method)
- **L377**: `_setProp` (method)

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

### `lib/shared/widgets/create_item_sheet.dart` (673 lines)
- **L24**: `CreateItemSheet` (class)
- **L42**: `createState` (method)
- **L45**: `_CreateItemSheetState` (class)
- **L57**: `initState` (method)
- **L76**: `_loadTemplates` (method)
- **L84**: `dispose` (method)
- **L97**: `_handleSaveToInbox` (method)
- **L136**: `_handleOpenAsNote` (method)
- **L203**: `_handleNewBoard` (method)
- **L234**: `_handlePasteClipboard` (method)
- **L271**: `build` (method)
- **L619**: `_QuietCaptureOption` (class)
- **L633**: `build` (method)

### `lib/features/notes/widgets/whiteboard_embed_card.dart` (610 lines)
- **L16**: `WorkspaceEmbedCard` (class)
- **L29**: `build` (method)
- **L44**: `_buildUnresolvedCard` (method)
- **L366**: `_buildTranscludedLine` (method)
- **L482**: `_MiniWhiteboardPreviewPainter` (class)
- **L494**: `paint` (method)
- **L603**: `shouldRepaint` (method)

### `lib/features/about/widgets/release_notes_tab.dart` (577 lines)
- **L21**: `_ReleaseEntry` (class)
- **L43**: `ReleaseNotesTab` (class)
- **L47**: `createState` (method)
- **L50**: `_ReleaseNotesTabState` (class)
- **L185**: `build` (method)
- **L298**: `_buildHeroReleaseBanner` (method)
- **L391**: `_buildMetricChip` (method)
- **L409**: `_buildReleaseCard` (method)
- **L522**: `_buildPreviousVersionCard` (method)

### `lib/core/theme/app_colors.dart` (565 lines)
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
- **L351**: `resolveAccentColor` (method)

### `lib/features/tasks/widgets/task_reminder_sheet.dart` (554 lines)
- **L16**: `TaskReminderSelection` (class)
- **L30**: `TaskReminderSheet` (class)
- **L64**: `createState` (method)
- **L67**: `_TaskReminderSheetState` (class)
- **L83**: `initState` (method)
- **L90**: `_selectPreset` (method)
- **L98**: `_pickCustomDate` (method)
- **L128**: `_pickCustomTime` (method)
- **L152**: `_previewLabel` (method)
- **L173**: `_handleSave` (method)
- **L204**: `build` (method)
- **L491**: `_isSameDay` (method)
- **L497**: `_ReminderChoiceChip` (class)
- **L509**: `build` (method)


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
