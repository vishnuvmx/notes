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

### `lib/features/whiteboard/screens/whiteboard_canvas_screen.dart` (6,414 lines)
- **L36**: `CanvasSnapshot` (class)
- **L48**: `CanvasHistoryManager` (class)
- **L56**: `recordSnapshot` (method)
- **L84**: `clear` (method)
- **L92**: `WhiteboardCanvasScreen` (class)
- **L103**: `computeNodesBounds` (method)
- **L167**: `createState` (method)
- **L170**: `_WhiteboardCanvasScreenState` (class)
- **L215**: `selectEdgeForTesting` (method)
- **L217**: `selectNodeForTesting` (method)
- **L219**: `branchFromNodeForTesting` (method)
- **L222**: `deleteEdgeForTesting` (method)
- **L231**: `toggleSnapToGridForTesting` (method)
- **L234**: `toggleMinimapForTesting` (method)
- **L237**: `toggleZenModeForTesting` (method)
- **L239**: `_resolveNodeAssetPath` (method)

### `lib/features/notes/widgets/rich_note_content_view.dart` (3,956 lines)
- **L36**: `RichNoteNavigationController` (class)
- **L51**: `jumpToHeading` (method)
- **L61**: `RichNoteContentView` (class)
- **L88**: `createState` (method)
- **L91**: `_RichNoteContentViewState` (class)
- **L100**: `initState` (method)
- **L106**: `didUpdateWidget` (method)
- **L115**: `dispose` (method)
- **L121**: `_keyForHeading` (method)
- **L124**: `_unfoldCoveringSections` (method)
- **L160**: `_jumpToHeadingLine` (method)
- **L161**: `scrollToTarget` (method)
- **L195**: `_wrapHeadingTarget` (method)
- **L221**: `_wrapLineTap` (method)
- **L230**: `_toggleCheckbox` (method)
- **L241**: `build` (method)

### `lib/features/notes/screens/note_editor_screen.dart` (3,075 lines)
- **L53**: `NoteEditorScreen` (class)
- **L66**: `createState` (method)
- **L69**: `_NoteEditorScreenState` (class)
- **L118**: `_ensureContentMetrics` (method)
- **L155**: `initState` (method)
- **L206**: `_scrollToHeadingAnchor` (method)
- **L225**: `didChangeDependencies` (method)
- **L230**: `_buildUpdatedItem` (method)
- **L292**: `_flushSave` (method)
- **L302**: `didChangeAppLifecycleState` (method)
- **L314**: `dispose` (method)
- **L329**: `_toggleViewMode` (method)
- **L372**: `_scheduleScrollRestore` (method)
- **L374**: `applyJump` (method)
- **L398**: `_handleBackPress` (method)
- **L421**: `_jumpToLineIndex` (method)

### `lib/features/notes/widgets/mermaid/mermaid_diagram_card.dart` (2,415 lines)
- **L18**: `MermaidDiagramCard` (class)
- **L25**: `createState` (method)
- **L28**: `_MermaidDiagramCardState` (class)
- **L34**: `initState` (method)
- **L40**: `didUpdateWidget` (method)
- **L48**: `dispose` (method)
- **L55**: `_openInWhiteboard` (method)
- **L67**: `_convertToWhiteboardItem` (method)
- **L385**: `_computeErEntitiesForBoard` (method)
- **L393**: `build` (method)
- **L427**: `_buildRawCodeView` (method)
- **L452**: `_buildDiagramView` (method)
- **L502**: `_FlowchartLayoutResult` (class)
- **L602**: `subgraphChainKey` (method)
- **L756**: `depthOf` (method)
- **L770**: `includeRect` (method)

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

### `lib/features/notes/widgets/mermaid/mermaid_extra_renderers.dart` (1,485 lines)
- **L24**: `_branchAccentColor` (method)
- **L33**: `MermaidZoomViewer` (class)
- **L48**: `build` (method)
- **L84**: `MermaidErWidget` (class)
- **L97**: `build` (method)
- **L165**: `_buildEntityCard` (method)
- **L296**: `_buildKeyBadge` (method)
- **L328**: `_ErLayoutResult` (class)
- **L340**: `_computeErLayout` (method)
- **L419**: `_ErRelationPainter` (class)
- **L433**: `paint` (method)
- **L588**: `_drawStyledPath` (method)
- **L648**: `_drawLabelPill` (method)
- **L690**: `shouldRepaint` (method)
- **L697**: `MermaidGanttWidget` (class)
- **L725**: `build` (method)

### `lib/features/notes/widgets/code_syntax_highlighter.dart` (1,381 lines)
- **L20**: `_PatternRule` (class)
- **L26**: `_LanguageSpec` (class)
- **L46**: `_CompiledGrammar` (class)
- **L61**: `CodeSyntaxHighlighter` (class)
- **L77**: `_normalizeLanguage` (method)
- **L161**: `_grammarFor` (method)
- **L167**: `_buildSpec` (method)
- **L1356**: `_isFollowedByCallParen` (method)
- **L1369**: `_isPascalCase` (method)

### `lib/features/tasks/screens/today_screen.dart` (1,310 lines)
- **L37**: `TodayScreen` (class)
- **L44**: `createState` (method)
- **L47**: `_TodayScreenState` (class)
- **L76**: `build` (method)
- **L378**: `_TodaysDailyNoteCard` (class)
- **L394**: `build` (method)
- **L403**: `buildDailyBody` (method)
- **L553**: `_SegmentedTasksCard` (class)
- **L583**: `build` (method)
- **L909**: `_TaskRow` (class)
- **L923**: `build` (method)
- **L1122**: `_WorthRevisitingCard` (class)
- **L1128**: `build` (method)
- **L1239**: `_QuietEmptyBox` (class)
- **L1251**: `build` (method)

### `lib/features/settings/screens/settings_screen.dart` (1,240 lines)
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
- **L814**: `_StatMetricPill` (class)
- **L826**: `build` (method)
- **L858**: `_ThemeSegmentedControl` (class)
- **L864**: `build` (method)
- **L945**: `_RestoreBackupDialog` (class)

### `lib/shared/providers/workspace_provider.dart` (1,213 lines)
- **L25**: `WorkspaceProvider` (class)
- **L39**: `_nextId` (method)
- **L83**: `_invalidateDerivedCaches` (method)
- **L105**: `notifyListeners` (method)
- **L117**: `_loadPrefsAndItems` (method)
- **L148**: `getItemById` (method)
- **L150**: `restoreItem` (method)
- **L354**: `_sortItemsList` (method)
- **L373**: `resolveEffectiveFolder` (method)
- **L392**: `getChildItems` (method)
- **L407**: `getBreadcrumbChain` (method)
- **L421**: `getItemByIdSync` (method)
- **L443**: `loadItems` (method)
- **L472**: `setBottomNavIndex` (method)
- **L477**: `setCategoryFilter` (method)
- **L482**: `setCategory` (method)

### `lib/features/notes/widgets/slash_command_sheet.dart` (1,147 lines)
- **L24**: `SlashCommandItem` (class)
- **L44**: `SlashCommandsCatalog` (class)
- **L217**: `filter` (method)
- **L229**: `SlashCommandInlineBar` (class)
- **L244**: `build` (method)
- **L371**: `SlashAndBlockActionsSheet` (class)
- **L418**: `createState` (method)
- **L422**: `_SlashAndBlockActionsSheetState` (class)
- **L427**: `initState` (method)
- **L433**: `dispose` (method)
- **L439**: `build` (method)
- **L668**: `_selectInsertCommand` (method)
- **L674**: `_buildTransformTab` (method)
- **L769**: `_iconForBlockKind` (method)
- **L799**: `_ModeSegmentPill` (class)
- **L813**: `build` (method)

### `lib/features/graph/screens/knowledge_graph_screen.dart` (1,122 lines)
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
- **L853**: `_buildSelectedNodeDock` (method)
- **L941**: `_KnowledgeGraphPainter` (class)
- **L959**: `paint` (method)

### `lib/features/notes/widgets/markdown_text_editing_controller.dart` (1,019 lines)
- **L9**: `MarkdownTextEditingController` (class)
- **L22**: `paletteId` (method)
- **L284**: `flush` (method)
- **L888**: `_isWhitespace` (method)
- **L894**: `_isWordChar` (method)
- **L896**: `_canOpenUnderscore` (method)

### `android/app/src/main/kotlin/com/notes/tacknotes/MainActivity.kt` (867 lines)
- **L24**: `MainActivity` (class)
- **L33**: `showQuickCaptureNotificationOn` (function)
- **L91**: `showFallbackStatusNotification` (function)
- **L149**: `onCreate` (function)
- **L156**: `onResume` (function)
- **L161**: `enableHighRefreshRate` (function)
- **L194**: `onNewIntent` (function)
- **L200**: `configureFlutterEngine` (function)
- **L327**: `onDestroy` (function)
- **L336**: `hasNotificationPermission` (function)
- **L342**: `canScheduleExactAlarmsCompat` (function)
- **L348**: `requestNotificationPermissionWithResult` (function)
- **L365**: `onRequestPermissionsResult` (function)
- **L381**: `openAppNotificationSettings` (function)
- **L396**: `openAppExactAlarmSettings` (function)
- **L409**: `createNotificationChannels` (function)

### `lib/features/home/screens/home_screen.dart` (769 lines)
- **L35**: `HomeScreen` (class)
- **L53**: `createState` (method)
- **L56**: `_HomeScreenState` (class)
- **L59**: `_openItem` (method)
- **L67**: `_openCaptureSheet` (method)
- **L77**: `_handleBottomNavTap` (method)
- **L90**: `_titleForTab` (method)
- **L105**: `_subtitleForTab` (method)
- **L118**: `_showSortSheet` (method)
- **L205**: `build` (method)
- **L317**: `_stackIndexForTab` (method)
- **L333**: `_LibraryView` (class)
- **L340**: `_showFolderSheet` (method)
- **L348**: `build` (method)
- **L361**: `resetAllFilters` (method)
- **L367**: `emptyTitle` (method)

### `lib/features/about/screens/about_tack_screen.dart` (765 lines)
- **L12**: `AboutTackScreen` (class)
- **L16**: `createState` (method)
- **L19**: `_AboutTackScreenState` (class)
- **L25**: `initState` (method)
- **L31**: `_onTabChanged` (method)
- **L40**: `dispose` (method)
- **L47**: `build` (method)
- **L266**: `_buildStackJourneyTab` (method)
- **L339**: `_buildStageCard` (method)
- **L432**: `_buildPrivacyLegalTab` (method)
- **L544**: `_buildOpenSourceTab` (method)
- **L668**: `_buildPackageCard` (method)
- **L734**: `_JourneyStage` (class)
- **L750**: `_OssPackage` (class)

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

### `lib/features/notes/widgets/frontmatter_properties_bar.dart` (734 lines)
- **L21**: `FrontmatterPropertiesBar` (class)
- **L35**: `_cycleOrPickStatus` (method)
- **L49**: `_cyclePriority` (method)
- **L63**: `_clampDate` (method)
- **L69**: `_pickTargetDate` (method)
- **L95**: `build` (method)
- **L246**: `_PropertyPill` (class)
- **L268**: `build` (method)
- **L304**: `FrontmatterEditorSheet` (class)
- **L333**: `createState` (method)
- **L336**: `_FrontmatterEditorSheetState` (class)
- **L344**: `initState` (method)
- **L352**: `dispose` (method)
- **L358**: `_commit` (method)
- **L362**: `_setProp` (method)
- **L373**: `_addCustomField` (method)

### `lib/shared/widgets/create_item_sheet.dart` (713 lines)
- **L25**: `CreateItemSheet` (class)
- **L43**: `createState` (method)
- **L46**: `_CreateItemSheetState` (class)
- **L58**: `initState` (method)
- **L77**: `_loadTemplates` (method)
- **L85**: `dispose` (method)
- **L98**: `_handleSaveToInbox` (method)
- **L134**: `_handleOpenAsNote` (method)
- **L202**: `_handleNewBoard` (method)
- **L232**: `_handlePasteClipboard` (method)
- **L269**: `build` (method)
- **L656**: `_QuietCaptureOption` (class)
- **L670**: `build` (method)

### `lib/features/search/screens/search_command_screen.dart` (710 lines)
- **L24**: `SearchCommandScreen` (class)
- **L31**: `createState` (method)
- **L34**: `_SearchCommandScreenState` (class)
- **L39**: `dispose` (method)
- **L44**: `_buildCommands` (method)
- **L124**: `build` (method)
- **L491**: `_SearchGroupCard` (class)
- **L497**: `build` (method)
- **L517**: `_CommandEntry` (class)
- **L531**: `_GroupHeader` (class)
- **L537**: `build` (method)
- **L552**: `_CommandRow` (class)
- **L558**: `build` (method)
- **L615**: `_SearchResultItemRow` (class)
- **L627**: `build` (method)

### `lib/features/notes/widgets/whiteboard_embed_card.dart` (637 lines)
- **L17**: `WorkspaceEmbedCard` (class)
- **L32**: `build` (method)
- **L48**: `_buildUnresolvedCard` (method)
- **L371**: `_buildTranscludedLine` (method)
- **L500**: `_MiniWhiteboardPreviewPainter` (class)
- **L512**: `paint` (method)
- **L631**: `shouldRepaint` (method)

### `lib/core/theme/app_theme.dart` (610 lines)
- **L10**: `AppTheme` (class)
- **L13**: `Light Theme ("Paper & Pin")` (section)
- **L219**: `Dark Theme (Warm Charcoal)` (section)
- **L419**: `_TackFadePageTransitionsBuilder` (class)
- **L441**: `TackAnimatedTransition` (class)
- **L476**: `switcherTransition` (method)
- **L484**: `createState` (method)
- **L487**: `_TackAnimatedTransitionState` (class)
- **L494**: `initState` (method)
- **L500**: `didUpdateWidget` (method)
- **L516**: `_initAnimations` (method)
- **L554**: `_disposeAnimations` (method)
- **L561**: `dispose` (method)
- **L567**: `build` (method)
- **L590**: `AppInputDecorations` (class)
- **L606**: `bareWithHint` (method)

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

### `lib/features/notes/widgets/document_outline_sheet.dart` (552 lines)
- **L14**: `DocumentOutlineSheet` (class)
- **L104**: `createState` (method)
- **L107**: `_DocumentOutlineSheetState` (class)
- **L112**: `dispose` (method)
- **L118**: `build` (method)
- **L355**: `InlineTocCard` (class)
- **L368**: `createState` (method)
- **L371**: `_InlineTocCardState` (class)
- **L375**: `build` (method)


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
\-- ... (7 more files)
```
<!-- recall:project-map:end -->
