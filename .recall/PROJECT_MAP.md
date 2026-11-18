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

### `lib/features/whiteboard/screens/whiteboard_canvas_screen.dart` (6,360 lines)
- **L35**: `CanvasSnapshot` (class)
- **L47**: `CanvasHistoryManager` (class)
- **L55**: `recordSnapshot` (method)
- **L83**: `clear` (method)
- **L91**: `WhiteboardCanvasScreen` (class)
- **L102**: `computeNodesBounds` (method)
- **L166**: `createState` (method)
- **L169**: `_WhiteboardCanvasScreenState` (class)
- **L214**: `selectEdgeForTesting` (method)
- **L216**: `selectNodeForTesting` (method)
- **L218**: `branchFromNodeForTesting` (method)
- **L221**: `deleteEdgeForTesting` (method)
- **L230**: `toggleSnapToGridForTesting` (method)
- **L233**: `toggleMinimapForTesting` (method)
- **L236**: `toggleZenModeForTesting` (method)
- **L238**: `_resolveNodeAssetPath` (method)

### `lib/features/notes/widgets/rich_note_content_view.dart` (3,954 lines)
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

### `lib/features/notes/screens/note_editor_screen.dart` (3,023 lines)
- **L53**: `NoteEditorScreen` (class)
- **L66**: `createState` (method)
- **L69**: `_NoteEditorScreenState` (class)
- **L97**: `initState` (method)
- **L148**: `_scrollToHeadingAnchor` (method)
- **L167**: `didChangeDependencies` (method)
- **L172**: `_buildUpdatedItem` (method)
- **L234**: `_flushSave` (method)
- **L244**: `didChangeAppLifecycleState` (method)
- **L256**: `dispose` (method)
- **L271**: `_toggleViewMode` (method)
- **L314**: `_scheduleScrollRestore` (method)
- **L316**: `applyJump` (method)
- **L340**: `_handleBackPress` (method)
- **L363**: `_jumpToLineIndex` (method)
- **L396**: `_showDocumentOutlineSheet` (method)

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

### `lib/features/tasks/screens/today_screen.dart` (1,325 lines)
- **L37**: `TodayScreen` (class)
- **L46**: `createState` (method)
- **L49**: `_TodayScreenState` (class)
- **L78**: `build` (method)
- **L382**: `_TodaysDailyNoteCard` (class)
- **L398**: `build` (method)
- **L407**: `buildDailyBody` (method)
- **L557**: `_SegmentedTasksCard` (class)
- **L587**: `build` (method)
- **L922**: `_TaskRow` (class)
- **L936**: `build` (method)
- **L1132**: `_WorthRevisitingCard` (class)
- **L1140**: `build` (method)
- **L1251**: `_QuietEmptyBox` (class)
- **L1263**: `build` (method)

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

### `lib/features/notes/widgets/slash_command_sheet.dart` (1,146 lines)
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
- **L667**: `_selectInsertCommand` (method)
- **L673**: `_buildTransformTab` (method)
- **L768**: `_iconForBlockKind` (method)
- **L798**: `_ModeSegmentPill` (class)
- **L812**: `build` (method)

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

### `lib/features/notes/widgets/markdown_text_editing_controller.dart` (998 lines)
- **L9**: `MarkdownTextEditingController` (class)
- **L17**: `paletteId` (method)
- **L263**: `flush` (method)
- **L867**: `_isWhitespace` (method)
- **L873**: `_isWordChar` (method)
- **L875**: `_canOpenUnderscore` (method)

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

### `lib/features/about/screens/about_tack_screen.dart` (759 lines)
- **L12**: `AboutTackScreen` (class)
- **L16**: `createState` (method)
- **L19**: `_AboutTackScreenState` (class)
- **L25**: `initState` (method)
- **L31**: `_onTabChanged` (method)
- **L40**: `dispose` (method)
- **L47**: `build` (method)
- **L260**: `_buildStackJourneyTab` (method)
- **L335**: `_buildStageCard` (method)
- **L428**: `_buildPrivacyLegalTab` (method)
- **L540**: `_buildOpenSourceTab` (method)
- **L662**: `_buildPackageCard` (method)
- **L728**: `_JourneyStage` (class)
- **L744**: `_OssPackage` (class)

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

### `lib/core/theme/app_theme.dart` (604 lines)
- **L10**: `AppTheme` (class)
- **L13**: `Light Theme ("Paper & Pin")` (section)
- **L219**: `Dark Theme (Warm Charcoal)` (section)
- **L419**: `_TackFadePageTransitionsBuilder` (class)
- **L441**: `TackAnimatedTransition` (class)
- **L474**: `switcherTransition` (method)
- **L482**: `createState` (method)
- **L485**: `_TackAnimatedTransitionState` (class)
- **L492**: `initState` (method)
- **L498**: `didUpdateWidget` (method)
- **L514**: `_initAnimations` (method)
- **L552**: `_disposeAnimations` (method)
- **L559**: `dispose` (method)
- **L565**: `build` (method)
- **L584**: `AppInputDecorations` (class)
- **L600**: `bareWithHint` (method)

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

### `lib/features/notes/widgets/document_outline_sheet.dart` (565 lines)
- **L13**: `DocumentOutlineSheet` (class)
- **L117**: `createState` (method)
- **L120**: `_DocumentOutlineSheetState` (class)
- **L125**: `dispose` (method)
- **L131**: `build` (method)
- **L368**: `InlineTocCard` (class)
- **L381**: `createState` (method)
- **L384**: `_InlineTocCardState` (class)
- **L388**: `build` (method)


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
