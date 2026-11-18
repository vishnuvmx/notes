import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/core/routing/tack_routes.dart';
import 'package:notes/core/theme/app_colors.dart';
import 'package:notes/core/theme/app_typography.dart';
import 'package:notes/features/notes/widgets/whiteboard_embed_card.dart';
import 'package:notes/shared/data/mock_initial_data.dart';
import 'package:notes/shared/data/workspace_repo_impl.dart';
import 'package:notes/features/notes/services/block_transform_service.dart';
import 'package:notes/features/notes/services/frontmatter_service.dart';
import 'package:notes/features/tasks/services/open_tasks_service.dart';
import 'package:notes/features/notes/widgets/document_outline_sheet.dart';
import 'package:notes/features/notes/widgets/mermaid/mermaid_diagram_parser.dart';
import 'package:notes/features/notes/widgets/rich_note_content_view.dart';
import 'package:notes/features/notes/widgets/slash_command_sheet.dart';
import 'package:notes/shared/widgets/tack_card_open_container.dart';
import 'package:notes/core/theme/app_spacing.dart';
import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/core/theme/tack_icons.dart';
import 'package:notes/shared/data/i_workspace_repo.dart';
import 'package:notes/shared/models/base_item.dart';
import 'package:notes/features/notes/models/text_note.dart';
import 'package:notes/features/notes/services/markdown_table_service.dart';
import 'package:notes/core/theme/theme_provider.dart';
import 'package:notes/shared/providers/workspace_provider.dart';
import 'package:notes/shared/widgets/neo_note_card.dart';
import 'package:notes/shared/widgets/responsive_card_grid.dart';
import 'package:notes/shared/widgets/app_bottom_sheet.dart';
import 'package:notes/shared/widgets/app_floating_dialog.dart';
import 'package:notes/shared/widgets/app_search_field.dart';
import 'package:notes/shared/widgets/z_order_column.dart';
import 'package:notes/shared/widgets/smart_bottom_nav_bar.dart';
import 'package:notes/shared/widgets/sliding_pill_track.dart';
import 'package:notes/shared/widgets/tactile_ink_target.dart';
import 'package:notes/features/about/widgets/release_notes_tab.dart';
import 'package:notes/features/home/screens/home_screen.dart';
import 'package:notes/features/search/screens/search_command_screen.dart';
import 'package:notes/features/tasks/screens/today_screen.dart';
import 'package:notes/features/notes/screens/note_editor_screen.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:notes/features/settings/screens/settings_screen.dart';
import 'package:notes/features/about/screens/about_tack_screen.dart';
import 'package:notes/features/graph/screens/knowledge_graph_screen.dart';
import 'package:notes/features/whiteboard/models/whiteboard_item.dart';
import 'package:notes/features/whiteboard/screens/whiteboard_canvas_screen.dart';
import 'package:notes/shared/widgets/empty_state_widget.dart';

class _MockWorkspaceRepo extends IWorkspaceRepository {
  final List<BaseWorkspaceItem> _store = [];

  @override
  List<BaseWorkspaceItem> get cachedActiveItems =>
      _store.where((i) => !i.isTrash && !i.isArchived).toList();

  @override
  Future<List<BaseWorkspaceItem>> getAllActiveItems() async => cachedActiveItems;

  @override
  Future<List<BaseWorkspaceItem>> getItemsByType(ItemType? type) async {
    if (type == null) return cachedActiveItems;
    return cachedActiveItems.where((i) => i.type == type).toList();
  }

  @override
  Future<List<BaseWorkspaceItem>> getFavoriteItems() async =>
      cachedActiveItems.where((i) => i.isFavorite).toList();

  @override
  Future<List<BaseWorkspaceItem>> getArchivedItems() async =>
      _store.where((i) => i.isArchived && !i.isTrash).toList();

  @override
  Future<List<BaseWorkspaceItem>> getTrashItems() async =>
      _store.where((i) => i.isTrash).toList();

  @override
  Future<List<BaseWorkspaceItem>> searchItems(String query, {ItemType? type}) async =>
      cachedActiveItems
          .where((i) =>
              (type == null || i.type == type) && i.matchesQuery(query))
          .toList();

  @override
  Future<BaseWorkspaceItem?> getItemById(String id) async =>
      _store.where((i) => i.id == id).firstOrNull;

  @override
  Future<void> saveItem(BaseWorkspaceItem item) async {
    final idx = _store.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _store[idx] = item;
    } else {
      _store.add(item);
    }
  }

  @override
  Future<void> moveToTrash(String id) async {}

  @override
  Future<void> restoreItem(String id) async {}

  @override
  Future<void> toggleArchive(String id) async {}

  @override
  Future<void> toggleFavorite(String id) async {}

  @override
  Future<void> deletePermanently(String id) async {
    _store.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> emptyTrash() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI & UX Audit Verifications', () {
    testWidgets('1. AppSearchField has a single container border and bare TextField input decoration', (tester) async {
      String query = '';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: AppSearchField(
                hintText: 'Search notes...',
                onChanged: (val) => query = val,
                onClear: () => query = '',
              ),
            ),
          ),
        ),
      );

      // Verify TextField exists and uses InputBorder.none to prevent nested border slop
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.border, equals(InputBorder.none));
      expect(textField.decoration?.focusedBorder, equals(InputBorder.none));
      expect(textField.decoration?.enabledBorder, equals(InputBorder.none));
      expect(textField.decoration?.filled, isFalse);

      // Verify parent Container has the single canonical rounded border
      final containerFinder = find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(Container),
      ).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as ShapeDecoration?;
      final shape = decoration?.shape as SmoothRectangleBorder?;
      expect(shape?.side, isNotNull);

      // Verify typing and clearing
      await tester.enterText(find.byType(TextField), 'Flutter clean architecture');
      await tester.pump();
      expect(query, equals('Flutter clean architecture'));

      // Clear button should be visible (using Semantics label)
      final clearButtonFinder = find.bySemanticsLabel('Clear search text');
      expect(clearButtonFinder, findsOneWidget);

      await tester.tap(clearButtonFinder);
      await tester.pump();
      expect(query, equals(''));
    });

    testWidgets('2. AppBottomSheet renders as a floating island modal with 28dp rounded corners and no drag handle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  AppBottomSheet.show(
                    context: ctx,
                    builder: (sheetCtx) => const SizedBox(
                      height: 180,
                      child: Text('Sheet Content'),
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsOneWidget);

      // Verify no drag handle semantics widget is present per reference UI requirements
      final handleFinder = find.bySemanticsLabel('Drag handle to dismiss');
      expect(handleFinder, findsNothing);

      // Verify floating modal card container has 28dp rounded corners and horizontal margin
      final containerFinder = find.ancestor(
        of: find.text('Sheet Content'),
        matching: find.byType(Container),
      ).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as ShapeDecoration?;
      final shape = decoration?.shape as SmoothRectangleBorder?;
      expect(shape?.borderRadius, equals(AppSpacing.roundedModal));
      expect(container.margin, equals(const EdgeInsets.symmetric(horizontal: AppSpacing.s4)));
    });

    test('3. Table editor round-trip strips markdown asterisks and regenerates clean markdown', () {
      const rawMarkdown = '''
| **Feature** | *Status* | `Complexity` |
| :--- | :---: | ---: |
| **Android 15 Edge** | *Done* | High |
| **Grid Only** | *Locked* | Low |
''';

      // 1. Parsing lines and stripping inline markdown formatting from cells
      final lines = rawMarkdown.trim().split('\n');
      final parsed = MarkdownTableService.parseTableLines(lines);
      expect(parsed, isNotNull);
      expect(parsed!.headers, equals(['Feature', 'Status', 'Complexity']));
      expect(parsed.rows[0], equals(['Android 15 Edge', 'Done', 'High']));
      expect(parsed.rows[1], equals(['Grid Only', 'Locked', 'Low']));

      // 2. Modify a cell and round-trip to Markdown
      parsed.rows[0][1] = 'Verified';
      final reGenerated = MarkdownTableService.toMarkdown(parsed);

      expect(reGenerated.contains('**'), isFalse, reason: 'Asterisks must not leak into generated cells');
      expect(reGenerated.contains('*Done*'), isFalse);
      expect(reGenerated.contains('Verified'), isTrue);

      // Verify replaceTableInDocument in-place replacement
      final fullDoc = '''
# Notes

$rawMarkdown

Footer text.
''';

      final replacedDoc = MarkdownTableService.replaceTableInDocument(
        rawDocument: fullDoc,
        startLine: 2,
        endLineExclusive: 7,
        updatedTable: parsed,
      );

      expect(replacedDoc.contains('Verified'), isTrue);
      expect(replacedDoc.contains('Footer text.'), isTrue);
    });

    testWidgets('4. Navigation hierarchy: Edit mode -> Back -> Read mode -> Back -> Home', (tester) async {
      final repo = _MockWorkspaceRepo();
      final workspaceProvider = WorkspaceProvider(repo);

      final existingNote = TextNote(
        id: 'test-note-1',
        title: 'Architecture Review',
        content: '# Heading 1\nAuditing navigation patterns.',
        folderName: 'All Notes',
        tags: const ['#work'],
        paletteId: 'peach',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await workspaceProvider.saveItem(existingNote);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => NoteEditorScreen(item: existingNote),
                        ),
                      );
                    },
                    child: const Text('Open Note'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // 1. Home screen: Tap 'Open Note'
      await tester.tap(find.text('Open Note'));
      await tester.pumpAndSettle();

      // Note opens in Read Mode without any 'Saved' status pill
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      expect(find.byTooltip('Edit Note'), findsOneWidget);
      expect(find.byTooltip('Reader Mode'), findsNothing);
      expect(find.text('Saved'), findsNothing);
      expect(find.text('Saving...'), findsNothing);

      // 2. Transition from Read Mode -> Edit Mode
      await tester.tap(find.byTooltip('Edit Note'));
      await tester.pumpAndSettle();

      // Now in Edit Mode (reader switch button visible, still no 'Saved' pill)
      expect(find.byTooltip('Reader Mode'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);
      expect(find.text('Saving...'), findsNothing);

      // 3. Press back while in Edit Mode
      // Should transition to Read Mode instead of popping the screen
      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // We should STILL be in NoteEditorScreen, but back in Read Mode!
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      expect(find.byTooltip('Edit Note'), findsOneWidget);
      expect(find.byTooltip('Reader Mode'), findsNothing);

      // 4. Press back while in Read Mode
      // Should now pop back to Home screen
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // NoteEditorScreen is popped, Home screen is back
      expect(find.byType(NoteEditorScreen), findsNothing);
      expect(find.text('Open Note'), findsOneWidget);
    });

    testWidgets('5. Untouched blank draft discards and pops directly on Back (05 §2.2 D2)', (tester) async {
      final repo = _MockWorkspaceRepo();
      final workspaceProvider = WorkspaceProvider(repo);

      final blankDraft = await workspaceProvider.createQuickItem(
        title: 'Untitled Note',
        content: '',
        type: ItemType.note,
        paletteId: 'amber',
      );
      expect(workspaceProvider.libraryNotes.any((n) => n.id == blankDraft.id), isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => NoteEditorScreen(
                            item: blankDraft,
                            startInEditMode: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('New Blank Draft'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('New Blank Draft'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteEditorScreen), findsOneWidget);

      // Press Back immediately without typing anything
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Should pop directly back to caller and discard the untouched empty draft
      expect(find.byType(NoteEditorScreen), findsNothing);
      expect(find.text('New Blank Draft'), findsOneWidget);
      expect(workspaceProvider.libraryNotes.any((n) => n.id == blankDraft.id), isFalse);
    });

    testWidgets('6. SmartBottomNavBar renders 5 icon-only Paper & Pin slots (Today, Library, Capture, Boards, Search)', (tester) async {
      int tappedIndex = -1;
      bool captureTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: SmartBottomNavBar(
              currentIndex: 0,
              inboxCount: 3,
              onTap: (idx) => tappedIndex = idx,
              onFabTap: () => captureTapped = true,
            ),
          ),
        ),
      );

      // No visible text labels in bottom navigation dock
      expect(find.text('Today'), findsNothing);
      expect(find.text('Library'), findsNothing);
      expect(find.text('Boards'), findsNothing);
      expect(find.text('Search'), findsNothing);

      // Accessible semantics & slot keys are present
      expect(find.bySemanticsLabel('Today'), findsOneWidget);
      expect(find.bySemanticsLabel('Library'), findsOneWidget);
      expect(find.bySemanticsLabel('Boards'), findsOneWidget);
      expect(find.bySemanticsLabel('Search'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav_item_1')));
      await tester.pump();
      expect(tappedIndex, 1);

      await tester.tap(find.byKey(const ValueKey('nav_capture_fab')));
      await tester.pump();
      expect(captureTapped, isTrue);

      // Verify the background pill fill smoothly glides across the dock when index changes
      final pillFinder = find.descendant(
        of: find.descendant(
          of: find.byType(SmartBottomNavBar),
          matching: find.byType(SlideTransition),
        ),
        matching: find.byType(DecoratedBox),
      );
      final startX = tester.getTopLeft(pillFinder).dx;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: SmartBottomNavBar(
              currentIndex: 4, // Last slot (Search)
              inboxCount: 3,
              onTap: (idx) => tappedIndex = idx,
              onFabTap: () => captureTapped = true,
            ),
          ),
        ),
      );

      // Midway through the 300ms glide, indicator should be strictly between start and end
      await tester.pump(const Duration(milliseconds: 120));
      final midX = tester.getTopLeft(pillFinder).dx;
      await tester.pumpAndSettle();
      final endX = tester.getTopLeft(pillFinder).dx;

      expect(midX, greaterThan(startX + 10));
      expect(midX, lessThan(endX - 10));
    });

    testWidgets('7. ProfileSettingsScreen switches between tabs with IndexedStack, clipBehavior, and clean TabBar', (tester) async {
      final repo = _MockWorkspaceRepo();
      final workspaceProvider = WorkspaceProvider(repo);
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: workspaceProvider),
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // TabBar must have NoSplash and transparent overlay
      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);
      final tabBar = tester.widget<TabBar>(tabBarFinder);
      expect(tabBar.splashFactory, equals(NoSplash.splashFactory));

      // Uses IndexedStack (not TabBarView which creates sliding shadow bounding box glitches)
      expect(find.byType(IndexedStack), findsOneWidget);
      expect(find.byType(TabBarView), findsNothing);

      // Initially shows clean simplified Profile & Settings labels without subheadings/subtitles
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('Trash'),
        ),
        findsOneWidget,
      );
      expect(find.text('Carry forward unfinished tasks'), findsOneWidget);
      expect(find.text('All files'), findsOneWidget);
      expect(find.text('Export backup'), findsOneWidget);
      expect(find.text('Restore backup'), findsOneWidget);
      expect(find.text('About & Privacy'), findsOneWidget);

      expect(find.text('On-device JSON store'), findsNothing);
      expect(find.text('Trash & Deleted Items'), findsNothing);
      expect(find.text('Appearance'), findsNothing);
      expect(find.text('Today & Daily Note'), findsNothing);
      expect(find.text('Local Storage & Backup'), findsNothing);
      expect(find.text('About'), findsNothing);
      expect(find.text('Restore or permanently delete items'), findsNothing);

      // Tapping Dark theme updates ThemeProvider synchronously and animates SlidingPillTrack cleanly
      await tester.tap(find.text('Dark'));
      await tester.pump();
      expect(themeProvider.themeMode, ThemeMode.dark);
      await tester.pumpAndSettle();

      // Switch to What's New tab
      await tester.tap(find.text("What's New"));
      await tester.pumpAndSettle();

      // IndexedStack index updated to 1, showing What's New content
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 1);
      expect(find.text('v2.0.0  •  MAJOR UPDATE'), findsOneWidget);
    });

    testWidgets('8. NeoNoteCard does not render body content inside preview on home screen', (tester) async {
      final now = DateTime.now();
      final note = TextNote(
        id: 'test_note_1',
        title: 'Project Architecture',
        content: 'Detailed hidden body content that should never appear on the home preview card.',
        tags: const ['design'],
        paletteId: 'peach',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: NeoNoteCard(
                item: note,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title and Tag must be visible
      expect(find.text('Project Architecture'), findsOneWidget);
      expect(find.text('#design'), findsOneWidget);

      // Body text snippet MUST NOT be present
      expect(find.textContaining('Detailed hidden body content'), findsNothing);
    });

    testWidgets('9. ZOrderColumn renders children in reverse paint order for unclipped drop shadows', (tester) async {
      bool firstTapped = false;
      bool secondTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ZOrderColumn(
              children: [
                GestureDetector(
                  onTap: () => firstTapped = true,
                  child: Container(
                    height: 100,
                    width: 200,
                    color: Colors.blue,
                    child: const Text('Top Card'),
                  ),
                ),
                GestureDetector(
                  onTap: () => secondTapped = true,
                  child: Container(
                    height: 100,
                    width: 200,
                    color: Colors.green,
                    child: const Text('Bottom Card'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Card'), findsOneWidget);
      expect(find.text('Bottom Card'), findsOneWidget);

      await tester.tap(find.text('Top Card'));
      await tester.pump();
      expect(firstTapped, isTrue);

      await tester.tap(find.text('Bottom Card'));
      await tester.pump();
      expect(secondTapped, isTrue);
    });

    testWidgets('10. AppFloatingDialog renders custom island card with 28dp radius and pill actions', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  confirmed = await AppFloatingDialog.confirm(
                    context: ctx,
                    title: 'Delete Note?',
                    message: 'This note will be moved to trash.',
                    confirmLabel: 'Move to Trash',
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Delete Note?'), findsOneWidget);
      expect(find.text('This note will be moved to trash.'), findsOneWidget);
      expect(find.text('Move to Trash'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Verify custom floating island card with 28dp rounded corners
      final cardFinder = find.ancestor(
        of: find.text('Delete Note?'),
        matching: find.byType(Container),
      ).first;
      final card = tester.widget<Container>(cardFinder);
      final decoration = card.decoration as ShapeDecoration?;
      final shape = decoration?.shape as SmoothRectangleBorder?;
      expect(shape?.borderRadius, equals(AppSpacing.roundedModal));

      // Tap Confirm
      await tester.tap(find.text('Move to Trash'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });

    test('11. WhiteboardCanvasScreen.computeDensestClusterBounds picks dense cluster over outliers', () {
      const nodes = [
        // Isolated distant outliers
        CanvasNode(id: 'out1', text: 'Outlier 1', shapeType: CanvasNodeType.process, x: 900, y: 900),
        CanvasNode(id: 'out2', text: 'Outlier 2', shapeType: CanvasNodeType.process, x: 5200, y: 4900),
        // Dense cluster of 4 connected nodes around (3600, 3200)
        CanvasNode(id: 'c1', text: 'Core 1', shapeType: CanvasNodeType.process, x: 3500, y: 3100),
        CanvasNode(id: 'c2', text: 'Core 2', shapeType: CanvasNodeType.process, x: 3720, y: 3120),
        CanvasNode(id: 'c3', text: 'Core 3', shapeType: CanvasNodeType.decision, x: 3560, y: 3320),
        CanvasNode(id: 'c4', text: 'Core 4', shapeType: CanvasNodeType.sticky, x: 3760, y: 3340),
      ];
      const edges = [
        CanvasEdge(id: 'e1', fromNodeId: 'c1', toNodeId: 'c2'),
        CanvasEdge(id: 'e2', fromNodeId: 'c2', toNodeId: 'c3'),
        CanvasEdge(id: 'e3', fromNodeId: 'c3', toNodeId: 'c4'),
      ];

      final bounds = WhiteboardCanvasScreen.computeDensestClusterBounds(
        nodes,
        edges: edges,
      );
      expect(bounds, isNotNull);
      expect(bounds!.left, greaterThanOrEqualTo(3400));
      expect(bounds.right, lessThanOrEqualTo(4000));
      expect(bounds.top, greaterThanOrEqualTo(3000));
      expect(bounds.bottom, lessThanOrEqualTo(3500));
    });

    testWidgets('12. WhiteboardCanvasScreen hides Whiteboard subtitle & chevron and opens on densest cluster', (tester) async {
      final repo = _MockWorkspaceRepo();
      final workspaceProvider = WorkspaceProvider(repo);
      final now = DateTime.now();

      final board = WhiteboardCanvasItem(
        id: 'wb_dense_open',
        title: 'Roadmap Architecture',
        createdAt: now,
        updatedAt: now,
        paletteId: 'cyan',
        // Stale random pan offset far away from the dense cluster
        panOffset: const Offset(100, 100),
        zoomScale: 0.4,
        nodes: const [
          CanvasNode(id: 'far', text: 'Far Node', shapeType: CanvasNodeType.process, x: 900, y: 900),
          CanvasNode(id: 'd1', text: 'Hub A', shapeType: CanvasNodeType.process, x: 3600, y: 3100),
          CanvasNode(id: 'd2', text: 'Hub B', shapeType: CanvasNodeType.process, x: 3820, y: 3100),
          CanvasNode(id: 'd3', text: 'Hub C', shapeType: CanvasNodeType.process, x: 3710, y: 3290),
        ],
        edges: const [
          CanvasEdge(id: 'e1', fromNodeId: 'd1', toNodeId: 'd2'),
          CanvasEdge(id: 'e2', fromNodeId: 'd2', toNodeId: 'd3'),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: WhiteboardCanvasScreen(item: board),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Board title renders without 'Whiteboard' subtitle or down arrow
      expect(find.text('Roadmap Architecture'), findsOneWidget);
      expect(find.text('Whiteboard'), findsNothing);
      final appBarFinder = find.byType(AppBar);
      expect(
        find.descendant(
          of: appBarFinder,
          matching: find.byWidgetPredicate(
            (w) => w is TackIcon && w.icon == TackIcons.chevronDown,
          ),
        ),
        findsNothing,
      );

      // InteractiveViewer camera should be focused near the dense cluster (around 3700, 3200)
      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final viewportCenter = viewer.transformationController!.toScene(
        const Offset(400, 260),
      );
      expect(viewportCenter.dx, greaterThan(3200));
      expect(viewportCenter.dy, greaterThan(2700));
    });

    test('13. SmoothRectangleBorder produces strictly convex smooth squircle boundary', () {
      const rect = Rect.fromLTWH(0, 0, 360, 240);
      final shape = AppSpacing.smoothModal(
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
      );

      final outer = shape.getOuterPath(rect);
      final inner = shape.getInnerPath(rect);
      expect(outer.getBounds(), equals(rect));
      expect(inner.getBounds(), isNot(rect));

      // Verify curve never overshoots straight edges anywhere near top-left corner
      final metric = outer.computeMetrics().first;
      for (int i = 0; i <= 100; i++) {
        final pos = metric.getTangentForOffset(metric.length * (i / 100.0))!.position;
        expect(pos.dx, inInclusiveRange(-0.01, rect.width + 0.01));
        expect(pos.dy, inInclusiveRange(-0.01, rect.height + 0.01));
      }
    });

    testWidgets('14. Sort modal clears 28dp corners, aligns title with rows, and paints clean foreground border', (tester) async {
      final repo = _MockWorkspaceRepo();
      final workspace = WorkspaceProvider(repo)..setBottomNavIndex(3);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspace),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('header_sort_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sort items'), findsOneWidget);
      expect(find.text('Recently updated (Pinned first)'), findsOneWidget);

      // Modal shell uses MaterialType.transparency + foregroundDecoration for border
      final sheetContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Sort items'),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is ShapeDecoration &&
                (w.decoration as ShapeDecoration).shape is SmoothRectangleBorder,
          ),
        ).first,
      );
      expect(sheetContainer.foregroundDecoration, isA<ShapeDecoration>());
      final sheetMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byWidgetPredicate((w) => identical(w, sheetContainer)),
          matching: find.byType(Material),
        ).first,
      );
      expect(sheetMaterial.type, equals(MaterialType.transparency));

      // 'Sort items' header stays well clear of 28dp top-left curve and aligns with option labels
      final sheetRect = tester.getRect(find.byWidgetPredicate((w) => identical(w, sheetContainer)));
      final headerRect = tester.getRect(find.text('Sort items'));
      final optionRect = tester.getRect(find.text('Recently updated (Pinned first)'));
      expect(headerRect.top - sheetRect.top, greaterThanOrEqualTo(22.0));
      expect(headerRect.left - sheetRect.left, greaterThanOrEqualTo(22.0));
      expect((headerRect.left - optionRect.left).abs(), lessThanOrEqualTo(1.0));
    });

    testWidgets('15. Library filter bar scrolls away cleanly with grid and clips within viewport', (tester) async {
      final repo = _MockWorkspaceRepo();
      final now = DateTime(2026, 11, 15, 9, 0);
      for (var i = 0; i < 16; i++) {
        await repo.saveItem(
          TextNote(
            id: 'lib_$i',
            title: 'Note $i',
            content: '#work Item $i',
            paletteId: 'slate',
            tags: const ['work'],
            createdAt: now.subtract(Duration(minutes: i)),
            updatedAt: now.subtract(Duration(minutes: i)),
          ),
        );
      }
      final workspace = WorkspaceProvider(repo);
      await workspace.loadItems();
      workspace.setBottomNavIndex(1); // Library

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspace),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollFinder = find.byKey(const ValueKey('library_custom_scroll'));
      expect(scrollFinder, findsOneWidget);
      final customScroll = tester.widget<CustomScrollView>(scrollFinder);
      expect(customScroll.clipBehavior, isNot(equals(Clip.none)));

      // Initially at top: filter chips are visible inside viewport.
      final initialFilterTop = tester.getTopLeft(find.text('All Notes')).dy;
      final scrollTop = tester.getTopLeft(scrollFinder).dy;
      expect(initialFilterTop, greaterThanOrEqualTo(scrollTop));

      // Scroll down strongly -> filter bar slides out of view above the viewport.
      await tester.drag(scrollFinder, const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Scrollable>(find.descendant(of: scrollFinder, matching: find.byType(Scrollable)).first),
        isNotNull,
      );
      expect(find.text('All Notes'), findsNothing);

      // Scroll back to top -> filter bar returns cleanly.
      await tester.drag(scrollFinder, const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.text('All Notes'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('library_filter_bar')),
          matching: find.text('#work'),
        ),
        findsOneWidget,
      );

      // Standalone ResponsiveCardGrid does not disable viewport clipping.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ResponsiveCardGrid(
              crossAxisCount: 2,
              itemCount: 2,
              itemBuilder: (_, i) => Text('Item $i'),
            ),
          ),
        ),
      );
      final standaloneScroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(standaloneScroll.clipBehavior, equals(Clip.hardEdge));
    });

    testWidgets('16. AboutTackScreen includes Privacy & Legal tab with local-first & permissions coverage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AboutTackScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Architecture'), findsOneWidget);
      expect(find.text('Privacy & Legal'), findsOneWidget);
      expect(find.text('Open Source'), findsOneWidget);

      await tester.tap(find.text('Privacy & Legal'));
      await tester.pumpAndSettle();

      expect(find.text('Local-First Storage & Zero Telemetry'), findsOneWidget);
      expect(find.textContaining('AlarmManager'), findsOneWidget);
    });

    testWidgets('17. ProfileSettingsScreen Restore Backup validates inline and preserves input on invalid JSON/schema', (tester) async {
      final repo = _MockWorkspaceRepo();
      final workspace = WorkspaceProvider(repo);
      await workspace.loadItems();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspace),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Restore backup'),
        200,
        scrollable: find.descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(find.text('Restore backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore backup'));
      await tester.pumpAndSettle();

      expect(find.text('Restore Backup'), findsOneWidget);
      final fieldFinder = find.byType(TextField);
      expect(fieldFinder, findsOneWidget);

      await tester.enterText(fieldFinder, '{"foo":"bar"}');
      await tester.pump();
      expect(find.text('Not a recognized Tack backup schema'), findsOneWidget);
      expect(tester.widget<TextField>(fieldFinder).controller?.text, '{"foo":"bar"}');

      await tester.enterText(fieldFinder, 'invalid json{');
      await tester.pump();
      expect(find.text('Invalid JSON format'), findsOneWidget);
      expect(tester.widget<TextField>(fieldFinder).controller?.text, 'invalid json{');
    });

    testWidgets('18. EmptyStateWidget renders custom actionIcon and invokes action callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EmptyStateWidget(
              icon: TackIcons.search,
              title: 'Nothing found',
              subtitle: 'Try clearing your active filters.',
              actionLabel: 'Clear filters',
              actionIcon: TackIcons.close,
              onAction: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing found'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is TackIcon && w.icon == TackIcons.close,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Clear filters'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('19. KnowledgeGraphScreen strips # when opening a tag node and switches to Library', (tester) async {
      final repo = _MockWorkspaceRepo();
      final now = DateTime(2026, 11, 15, 10, 0);
      await repo.saveItem(
        TextNote(
          id: 'tag-note-1',
          title: 'Design Spec',
          content: 'Specs #design',
          paletteId: 'slate',
          tags: const ['design'],
          createdAt: now,
          updatedAt: now,
        ),
      );
      final workspace = WorkspaceProvider(repo);
      await workspace.loadItems();
      workspace.setBottomNavIndex(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspace),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const KnowledgeGraphScreen(
                            focusItemId: 'tag:#design',
                          ),
                        ),
                      );
                    },
                    child: const Text('Push Graph'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Push Graph'));
      await tester.pumpAndSettle();

      expect(find.text('#design'), findsOneWidget);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(workspace.selectedTag, 'design');
      expect(workspace.bottomNavIndex, 1);
      expect(find.text('Push Graph'), findsOneWidget);
    });

    testWidgets('20. AppFloatingDialog.prompt returns entered text and disposes controller cleanly', (tester) async {
      String? promptResult;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    promptResult = await AppFloatingDialog.prompt(
                      context: context,
                      title: 'Rename Section',
                      hintText: 'Section name',
                      initialValue: 'Draft',
                    );
                  },
                  child: const Text('Prompt'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Prompt'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Architecture');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(promptResult, 'Architecture');
      expect(tester.takeException(), isNull);
    });

    testWidgets('13. 120fps optimizations: composited SlidingPillTrack & RepaintBoundary IndexedStack tabs', (tester) async {
      // SlidingPillTrack uses SlideTransition + RepaintBoundary (never AnimatedAlign relayouts)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SlidingPillTrack(
                itemCount: 3,
                selectedIndex: 0,
                trackColor: Colors.grey.shade200,
                indicatorColor: Colors.black,
                children: const [
                  Center(child: Text('System')),
                  Center(child: Text('Light')),
                  Center(child: Text('Dark')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedAlign), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SlidingPillTrack),
          matching: find.byType(SlideTransition),
        ),
        findsOneWidget,
      );

      // Re-pump with new selectedIndex transitions pill smoothly via SlideTransition
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SlidingPillTrack(
                itemCount: 3,
                selectedIndex: 2,
                trackColor: Colors.grey.shade200,
                indicatorColor: Colors.black,
                children: const [
                  Center(child: Text('System')),
                  Center(child: Text('Light')),
                  Center(child: Text('Dark')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final slideTransition = tester.widget<SlideTransition>(
        find.descendant(
          of: find.byType(SlidingPillTrack),
          matching: find.byType(SlideTransition),
        ),
      );
      expect(slideTransition.position.value.dx, greaterThan(0.0));
      expect(slideTransition.position.value.dx, lessThan(2.0));
      await tester.pumpAndSettle();
      expect(slideTransition.position.value.dx, closeTo(2.0, 0.001));

      // HomeScreen isolates IndexedStack tabs in RepaintBoundary without full-screen FadeTransition
      final repo = _MockWorkspaceRepo();
      final workspaceProvider = WorkspaceProvider(repo);
      final themeProvider = ThemeProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: workspaceProvider),
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            themeAnimationDuration: Duration.zero,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.children.length, 4);
      for (final child in indexedStack.children) {
        expect(child, isA<RepaintBoundary>());
      }
      expect(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.ancestor(
            of: find.byType(IndexedStack),
            matching: find.byType(FadeTransition),
          ),
        ),
        findsNothing,
      );
    });

    testWidgets(
      '21. Fade-out transitions use responsive exit curves and composited RepaintBoundary without Opacity saveLayers',
      (tester) async {
        // A. Real MaterialPageRoute pop drops opacity immediately on exit (AppTheme pageTransitionsTheme)
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(body: Text('Second Page')),
                      ),
                    );
                  },
                  child: const Text('Push Page'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Push Page'));
        await tester.pumpAndSettle();
        expect(find.text('Second Page'), findsOneWidget);

        Navigator.of(tester.element(find.text('Second Page'))).pop();
        await tester.pump();
        // After 75ms (25% of 300ms route pop), outgoing page should already be well below 0.45
        await tester.pump(const Duration(milliseconds: 75));
        final poppedFadeFinder = find.ancestor(
          of: find.text('Second Page'),
          matching: find.byType(FadeTransition),
        );
        expect(poppedFadeFinder, findsOneWidget);
        expect(tester.widget<FadeTransition>(poppedFadeFinder).opacity.value, lessThan(0.45));
        expect(
          find.descendant(
            of: poppedFadeFinder,
            matching: find.byType(RepaintBoundary),
          ),
          findsWidgets,
        );

        // After +145ms (220ms elapsed, >72% fade interval), outgoing page reaches 0.0 cleanly
        await tester.pump(const Duration(milliseconds: 145));
        expect(tester.widget<FadeTransition>(poppedFadeFinder).opacity.value, equals(0.0));
        await tester.pumpAndSettle();

        // B. AppFloatingDialog uses TackAnimatedTransition (ScaleTransition + FadeTransition), never raw Opacity
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    AppFloatingDialog.showCustom<void>(
                      context: ctx,
                      builder: (dlgCtx) => const Text('Dialog Body'),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final dialogTransitionFinder = find.ancestor(
          of: find.text('Dialog Body'),
          matching: find.byType(TackAnimatedTransition),
        );
        expect(dialogTransitionFinder, findsOneWidget);
        expect(
          find.descendant(
            of: dialogTransitionFinder,
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: dialogTransitionFinder,
            matching: find.byType(ScaleTransition),
          ),
          findsOneWidget,
        );
        await tester.pumpAndSettle();

        // Dismiss dialog and verify rapid fade-out within 60ms of 190ms duration
        Navigator.of(tester.element(find.text('Dialog Body'))).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final dialogFadeFinder = find.descendant(
          of: dialogTransitionFinder,
          matching: find.byType(FadeTransition),
        );
        expect(tester.widget<FadeTransition>(dialogFadeFinder).opacity.value, lessThan(0.45));
        await tester.pumpAndSettle();

        // C. SmartBottomNavBar uses alpha-tinted TackIcon color instead of Opacity saveLayer
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              bottomNavigationBar: SmartBottomNavBar(
                currentIndex: 0,
                onTap: (_) {},
                onFabTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(SmartBottomNavBar),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      '22. Home header, To-Do/Completed icons, transparent bottom nav, and decluttered Search screen match refinements',
      (tester) async {
        final repo = _MockWorkspaceRepo();
        await repo.saveItem(
          TextNote(
            id: 'note-1',
            title: 'Weekly Focus',
            content: '# Focus\nShip dark mode & search polish.\n- [ ] Test layout',
            folderName: 'All Notes',
            paletteId: 'amber',
            createdAt: DateTime(2026, 11, 18),
            updatedAt: DateTime(2026, 11, 18),
          ),
        );
        final workspaceProvider = WorkspaceProvider(repo);
        final themeProvider = ThemeProvider();
        await workspaceProvider.loadItems();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: workspaceProvider),
              ChangeNotifierProvider.value(value: themeProvider),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Header shows "Hi Wassup!" with no subtagline
        expect(find.text('Hi Wassup!'), findsOneWidget);
        expect(find.text("Let's make progress today!"), findsNothing);

        // Mon..Sun week strip and Inbox tab are removed on TodayScreen
        expect(find.text('Mon'), findsNothing);
        expect(find.text('Sun'), findsNothing);
        expect(find.text('Inbox'), findsNothing);
        expect(find.text('Today (1)'), findsNothing);

        // Two-tab segmented control uses unfilled square for To do and check for Completed
        final taskPillTrack = tester.widget<SlidingPillTrack>(
          find.descendant(
            of: find.byType(TodayScreen),
            matching: find.byType(SlidingPillTrack),
          ),
        );
        expect(taskPillTrack.itemCount, 2);
        expect(
          find.descendant(
            of: find.byType(TodayScreen),
            matching: find.byWidgetPredicate(
              (w) => w is TackIcon && w.icon == TackIcons.taskOpen,
            ),
          ),
          findsWidgets,
        );
        expect(TackIcons.taskOpen.outline, TablerIcons.square);
        expect(TackIcons.check.outline, TablerIcons.check);
        expect(
          find.descendant(
            of: find.byType(TodayScreen),
            matching: find.byWidgetPredicate(
              (w) => w is TackIcon && w.icon == TackIcons.check,
            ),
          ),
          findsOneWidget,
        );

        // Bottom nav renders transparently with extendBody enabled (no cut-off strip)
        final homeScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(homeScaffold.extendBody, isTrue);
        expect(
          tester.widget<SmartBottomNavBar>(find.byType(SmartBottomNavBar)),
          isNotNull,
        );
        expect(
          find.descendant(
            of: find.byType(SmartBottomNavBar),
            matching: find.byType(ColoredBox),
          ),
          findsNothing,
        );

        // Search tab is calm, concise, and free of command taglines/subtitles
        await tester.tap(find.byKey(const ValueKey('nav_item_4')));
        await tester.pumpAndSettle();

        expect(find.byType(SearchCommandScreen), findsOneWidget);
        expect(
          find.text('Jump to today’s note with carried-forward tasks'),
          findsNothing,
        );
        expect(
          find.text('Start a visual flowchart & spec board'),
          findsNothing,
        );
        expect(find.text('Recent'), findsOneWidget);
        expect(find.text('Weekly Focus'), findsOneWidget);
        expect(find.text('Ship dark mode & search polish.'), findsNothing);
      },
    );

    testWidgets(
      '23. TackRoutes.sharedAxisHorizontal & slideUp animate primary + secondary routes cleanly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).push(
                          TackRoutes.sharedAxisHorizontal<void>(
                            Scaffold(
                              body: Builder(
                                builder: (innerCtx) => ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(innerCtx).push(
                                      TackRoutes.sharedAxisHorizontal<void>(
                                        const Scaffold(
                                          body: Text('Axis Child 2'),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Push Deeper'),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Push Axis'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).push(
                          TackRoutes.slideUp<void>(
                            const Scaffold(body: Text('Slide Up Modal')),
                          ),
                        );
                      },
                      child: const Text('Push SlideUp'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // 1. Test Shared Axis Horizontal primary + secondary animation
        await tester.tap(find.text('Push Axis'));
        await tester.pumpAndSettle();
        expect(find.text('Push Deeper'), findsOneWidget);

        await tester.tap(find.text('Push Deeper'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(find.text('Axis Child 2'), findsOneWidget);
        final deeperTransitions = tester.widgetList<SlideTransition>(
          find.ancestor(
            of: find.text('Push Deeper'),
            matching: find.byType(SlideTransition),
          ),
        );
        expect(
          deeperTransitions.any((s) => s.position.value.dx < 0.0),
          isTrue,
          reason: 'Underlying route should nudge smoothly left via secondaryAnimation',
        );

        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.text('Axis Child 2'))).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final poppedFade = find.ancestor(
          of: find.text('Axis Child 2'),
          matching: find.byType(FadeTransition),
        );
        expect(
          tester.widget<FadeTransition>(poppedFade).opacity.value,
          lessThan(0.55),
        );
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.text('Push Deeper'))).pop();
        await tester.pumpAndSettle();

        // 2. Test SlideUp transition
        await tester.tap(find.text('Push SlideUp'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 90));
        expect(find.text('Slide Up Modal'), findsOneWidget);
        final modalSlide = find.ancestor(
          of: find.text('Slide Up Modal'),
          matching: find.byType(SlideTransition),
        );
        expect(tester.widget<SlideTransition>(modalSlide).position.value.dy, greaterThan(0.0));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '24. Starter showcase note & board render full capabilities, asset images, and zero node overlap',
      (WidgetTester tester) async {
        final items = MockInitialData.getInitialItems();
        expect(items.length, 2);

        final note = items[0] as TextNote;
        final board = items[1] as WhiteboardCanvasItem;

        // 1. Validate Note capabilities (frontmatter, tasks, mermaid, embeds, bundled images)
        final fm = FrontmatterService.parse(note.content);
        expect(fm.status, 'Approved');
        expect(fm.priority, 'High');
        expect(fm.aliases, containsAll(['How Tack Works', 'Starter Guide']));

        final openTasks = OpenTasksService.extractTasks([note]);
        expect(openTasks.length, 3);
        expect(openTasks.any((t) => t.recurrence == TaskRecurrence.daily), isTrue);
        expect(openTasks.every((t) => !t.isOverdue()), isTrue);

        final mermaidMatch = RegExp(
          r'```mermaid\n([\s\S]*?)```',
        ).firstMatch(note.content);
        expect(mermaidMatch, isNotNull);
        final parsedMermaid = MermaidDiagramParser.parse(mermaidMatch!.group(1)!);
        expect(parsedMermaid.isValid, isTrue);
        expect(parsedMermaid.nodes.length, 5);

        // 2. Validate Board flowchart shapes, bundled image node, non-overlap & cluster bounds
        expect(board.title, 'Capture to Clarity');
        final types = board.nodes.map((n) => n.shapeType).toSet();
        expect(
          types,
          containsAll([
            CanvasNodeType.textOnly,
            CanvasNodeType.startEnd,
            CanvasNodeType.inputOutput,
            CanvasNodeType.decision,
            CanvasNodeType.process,
            CanvasNodeType.connector,
            CanvasNodeType.sticky,
            CanvasNodeType.specCard,
            CanvasNodeType.image,
          ]),
        );

        final imageNode = board.nodes.firstWhere(
          (n) => n.shapeType == CanvasNodeType.image,
        );
        expect(imageNode.imagePath, 'assets/images/onboarding/slide3_connected_ideas.jpg');

        final specNode = board.nodes.firstWhere(
          (n) => n.shapeType == CanvasNodeType.specCard,
        );
        expect(specNode.linkedNoteId, note.id);

        // Every pair of board nodes must have non-overlapping rectangles
        for (int a = 0; a < board.nodes.length; a++) {
          final ra = Rect.fromLTWH(
            board.nodes[a].x,
            board.nodes[a].y,
            board.nodes[a].width,
            board.nodes[a].height,
          );
          for (int b = a + 1; b < board.nodes.length; b++) {
            final rb = Rect.fromLTWH(
              board.nodes[b].x,
              board.nodes[b].y,
              board.nodes[b].width,
              board.nodes[b].height,
            );
            expect(
              ra.overlaps(rb),
              isFalse,
              reason: '${board.nodes[a].id} overlaps ${board.nodes[b].id}',
            );
          }
        }

        // All board nodes sit within initial camera cluster framing
        final cluster = WhiteboardCanvasScreen.computeDensestClusterBounds(
          board.nodes,
          edges: board.edges,
        )!;
        for (final node in board.nodes) {
          expect(cluster.contains(node.center), isTrue, reason: '${node.id} outside cluster');
        }

        // 3. Render starter Note view with live WorkspaceProvider and asset images
        final repo = _MockWorkspaceRepo();
        await repo.saveItem(note);
        await repo.saveItem(board);
        final workspace = WorkspaceProvider(repo);
        await workspace.loadItems();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: workspace),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RichNoteContentView(
                    content: note.content,
                    paletteId: note.paletteId,
                    workspaceItems: workspace.rawItems,
                    onContentChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Table'), findsOneWidget);
        expect(find.text('Capture to Clarity'), findsWidgets);
        // 2 block asset images + 1 inline asset thumbnail
        final noteImages = tester.widgetList<Image>(find.byType(Image));
        expect(noteImages.length, 3);
        for (final img in noteImages) {
          expect(img.image, isA<AssetImage>());
        }

        // 4. Render starter Board screen with bundled asset node & linked SpecCard
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: workspace),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: WhiteboardCanvasScreen(item: board),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tack Complete Guide'), findsWidgets);
        expect(find.text('Open ↗'), findsOneWidget);
        final boardImages = tester.widgetList<Image>(find.byType(Image));
        expect(
          boardImages.any((img) => img.image is AssetImage),
          isTrue,
        );
      },
    );

    test(
      '25. LocalStorageWorkspaceRepository upgrades untouched v1 starter items cleanly without overwriting user edits',
      () async {
        // Case A: Untouched legacy v1 starter items upgrade to v2
        final now = DateTime.now();
        final oldNote = TextNote(
          id: MockInitialData.welcomeNoteId,
          title: 'How Tack Works',
          content: '# Tack in 30 seconds\n\nLegacy content',
          createdAt: now,
          updatedAt: now,
          paletteId: 'amber',
        );
        final oldBoard = WhiteboardCanvasItem(
          id: MockInitialData.starterBoardId,
          title: 'Capture to Clarity (Board)',
          createdAt: now,
          updatedAt: now,
          paletteId: 'cyan',
          nodes: List.generate(
            5,
            (idx) => CanvasNode(
              id: idx == 0 ? 'n_idea' : 'n_$idx',
              text: 'Node $idx',
              shapeType: CanvasNodeType.process,
              x: 3000,
              y: 3000,
            ),
          ),
        );

        SharedPreferences.setMockInitialValues({
          'tack_workspace_items_v2':
              jsonEncode([oldNote.toJson(), oldBoard.toJson()]),
        });

        final repoUpgrade = LocalStorageWorkspaceRepository();
        final upgraded = await repoUpgrade.getAllActiveItems();
        final upgradedNote = upgraded.whereType<TextNote>().first;
        final upgradedBoard = upgraded.whereType<WhiteboardCanvasItem>().first;
        expect(upgradedNote.title, 'Tack Complete Guide');
        expect(
          upgradedNote.content.contains('assets/images/onboarding/slide1_tactile_grid.jpg'),
          isTrue,
        );
        expect(upgradedBoard.title, 'Capture to Clarity');
        expect(upgradedBoard.nodes.length, 11);

        // Case B: User-customized starter note is NEVER overwritten
        final editedNote = oldNote.copyWith(
          title: 'My Custom Title',
          content: '# My own personal notes',
        );
        SharedPreferences.setMockInitialValues({
          'tack_workspace_items_v2': jsonEncode([editedNote.toJson()]),
        });

        final repoPreserved = LocalStorageWorkspaceRepository();
        final preserved = await repoPreserved.getAllActiveItems();
        expect(preserved.single.title, 'My Custom Title');
        expect((preserved.single as TextNote).content, '# My own personal notes');
      },
    );

    testWidgets(
      '26. DocumentOutlineSheet opens near top and Inline [TOC] scrolls target heading cleanly to top of viewport',
      (WidgetTester tester) async {
        final fillerTop = List.generate(18, (i) => 'Intro paragraph line $i.\n').join('\n');
        final fillerBottom = List.generate(28, (i) => 'Trailing paragraph line $i.\n').join('\n');
        final longNote = TextNote(
          id: 'toc_motion_note',
          title: 'TOC Precision Test',
          content:
              '[TOC]\n\n'
              '## Overview Section\n\n$fillerTop\n'
              '## Target Heading Destination\n\n$fillerBottom',
          createdAt: DateTime(2026, 11, 18),
          updatedAt: DateTime(2026, 11, 18),
          paletteId: 'amber',
        );

        final repo = _MockWorkspaceRepo();
        await repo.saveItem(longNote);
        final workspace = WorkspaceProvider(repo);
        await workspace.loadItems();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: workspace),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: NoteEditorScreen(item: longNote),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Tap Inline [TOC] entry -> target heading scrolls cleanly near top (NOT bottom)
        final tocEntry = find.descendant(
          of: find.byType(InlineTocCard),
          matching: find.text('Target Heading Destination'),
        );
        expect(tocEntry, findsOneWidget);
        await tester.tap(tocEntry);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        final targetInBody = find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.maxLines == null &&
              w.text.toPlainText().trim() == 'Target Heading Destination',
        );
        expect(targetInBody, findsOneWidget);
        final landedY = tester.getTopLeft(targetInBody).dy;
        expect(landedY, lessThan(220.0));
        expect(landedY, greaterThan(40.0));

        // 2. Open Document Outline button at top bar -> popover opens near top (not bottom)
        await tester.tap(find.byTooltip('Document Outline'));
        await tester.pumpAndSettle();

        final outlineFinder = find.byType(DocumentOutlineSheet);
        expect(outlineFinder, findsOneWidget);
        expect(tester.getTopLeft(outlineFinder).dy, lessThan(180.0));

        // Jump back up to Overview Section from Document Outline popover
        await tester.tap(
          find.descendant(
            of: outlineFinder,
            matching: find.text('Overview Section'),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.byType(DocumentOutlineSheet), findsNothing);
        final overviewInBody = find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.maxLines == null &&
              w.text.toPlainText().trim() == 'Overview Section',
        );
        expect(overviewInBody, findsOneWidget);
        expect(tester.getTopLeft(overviewInBody).dy, lessThan(220.0));
      },
    );

    testWidgets(
      '27. Today To-Do <-> Completed switches smoothly with top-anchored size/slide and Cards expand into Detail via OpenContainer',
      (WidgetTester tester) async {
        final items = MockInitialData.getInitialItems();
        final repo = _MockWorkspaceRepo();
        for (final item in items) {
          await repo.saveItem(item);
        }
        final workspace = WorkspaceProvider(repo);
        await workspace.loadItems();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: workspace),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Today To-Do <-> Completed switcher uses AnimatedSize (topCenter) + directional Slide
        final taskAnimatedSize = find.descendant(
          of: find.byType(TodayScreen),
          matching: find.byWidgetPredicate(
            (w) => w is AnimatedSize && w.alignment == Alignment.topCenter,
          ),
        );
        expect(taskAnimatedSize, findsOneWidget);

        await tester.tap(find.textContaining('Completed'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        // Incoming Completed subtree slides horizontally toward 0 while top-aligned
        final completedSlide = find.ancestor(
          of: find.textContaining('Explore Home to switch'),
          matching: find.byType(SlideTransition),
        );
        expect(completedSlide, findsWidgets);
        final offset = tester.widget<SlideTransition>(completedSlide.first).position.value;
        expect(offset.dx, greaterThan(0.0));
        expect(offset.dy, equals(0.0));
        await tester.pumpAndSettle();

        // 2. Verify Pinned Grid uses TackCardOpenContainer / OpenContainer and expands cleanly into NoteEditorScreen
        expect(find.byType(TackCardOpenContainer), findsWidgets);
        expect(find.byType(OpenContainer<void>), findsWidgets);

        final guideCard = find.descendant(
          of: find.byType(TodayScreen),
          matching: find.byWidgetPredicate(
            (w) => w is NeoNoteCard && w.item.id == MockInitialData.welcomeNoteId,
          ),
        );
        await tester.ensureVisible(guideCard);
        await tester.pumpAndSettle();
        await tester.tap(guideCard);
        await tester.pumpAndSettle();

        // Detail screen is open cleanly via Container Transform
        expect(find.byType(NoteEditorScreen), findsOneWidget);
        expect(find.text('Tack Complete Guide'), findsWidgets);

        // Press Back -> collapses cleanly back into Home card without crashing or stalling
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.byType(NoteEditorScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      '28. SlashAndBlockActionsSheet uses SlidingPillTrack, grouped Paper command cards, and 2-column Transform tiles cleanly',
      (WidgetTester tester) async {
        SlashCommandItem? insertedCmd;
        BlockKind? turnedIntoKind;
        bool movedUp = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      SlashAndBlockActionsSheet.show(
                        ctx,
                        currentBlockKind: BlockKind.paragraph,
                        onInsertCommand: (cmd) => insertedCmd = cmd,
                        onTurnInto: (kind) => turnedIntoKind = kind,
                        onMoveUp: () => movedUp = true,
                        onMoveDown: () {},
                        onDuplicateBlock: () {},
                      );
                    },
                    child: const Text('Open Insert & Transform'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Insert & Transform'));
        await tester.pumpAndSettle();

        // Uses SlidingPillTrack (Insert · Transform) and grouped Insert sections
        expect(
          find.descendant(
            of: find.byType(SlashAndBlockActionsSheet),
            matching: find.byType(SlidingPillTrack),
          ),
          findsOneWidget,
        );
        expect(find.text('Insert block'), findsOneWidget);
        expect(find.text('WRITING'), findsOneWidget);
        expect(find.text('/todo'), findsOneWidget);

        // Switch to Transform tab -> shows current block badge, Move actions, and BlockKind grid
        await tester.tap(find.text('Transform'));
        await tester.pumpAndSettle();

        expect(find.text('Transform block'), findsOneWidget);
        expect(find.text('Paragraph'), findsWidgets);
        expect(find.text('Move up'), findsOneWidget);
        expect(find.text('CONVERT LINE TO'), findsOneWidget);

        await tester.tap(find.text('Move up'));
        expect(movedUp, isTrue);

        await tester.tap(find.text('Heading 1'));
        await tester.pumpAndSettle();
        expect(turnedIntoKind, BlockKind.h1);

        // Re-open on Insert and verify command selection
        await tester.tap(find.text('Open Insert & Transform'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('To-Do'));
        await tester.pumpAndSettle();
        expect(insertedCmd?.id, 'todo');
      },
    );

    testWidgets(
      '29. Unified DM Sans typography & clean editorial left-ruled InlineTocCard',
      (WidgetTester tester) async {
        expect(AppTypography.displayFontFamily, equals(AppTypography.fontFamily));
        expect(AppTypography.serifFontFamily, equals(AppTypography.fontFamily));
        expect(AppTypography.display().fontFamily, startsWith('DMSans'));
        expect(AppTypography.serifItalic().fontFamily, startsWith('DMSans'));
        expect(AppTypography.titleLg().fontFamily, startsWith('DMSans'));
        expect(AppTypography.bodySm().fontFamily, startsWith('DMSans'));
        expect(AppTypography.caption().fontFamily, startsWith('DMSans'));
        expect(AppTypography.display().fontFamily, isNot(contains('Newsreader')));
        expect(
          AppTypography.mono().fontFamily,
          startsWith('JetBrainsMono'),
        );

        final lavender = AppColors.getPaletteById('lavender');
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: InlineTocCard(
                  paletteId: 'lavender',
                  content: '# Main Title\n## Sub Section\n',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CONTENTS'), findsOneWidget);
        expect(find.text('Main Title'), findsOneWidget);
        expect(find.text('Sub Section'), findsOneWidget);

        // Verify left accent bar uses Lavender darker variant (no puffy 16dp rounded card)
        final clip = tester.widget<ClipRRect>(
          find.descendant(
            of: find.byType(InlineTocCard),
            matching: find.byType(ClipRRect),
          ),
        );
        expect(clip.borderRadius, BorderRadius.circular(4));

        final leftRuleFinder = find.descendant(
          of: find.byType(InlineTocCard),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.color == lavender.resolveAccentColor(false) &&
                w.constraints?.maxWidth == 2.5,
          ),
        );
        expect(leftRuleFinder, findsOneWidget);
      },
    );

    testWidgets(
      '30. Note palette switching updates canvas, tags, frontmatter pills, TOC, and embed cards with darker variant',
      (WidgetTester tester) async {
        final peach = AppColors.getPaletteById('peach');
        final lavender = AppColors.getPaletteById('lavender');

        final board = WhiteboardCanvasItem(
          id: 'board-target',
          title: 'Capture to Clarity',
          paletteId: 'cyan',
          createdAt: DateTime(2026, 11, 18),
          updatedAt: DateTime(2026, 11, 18),
          nodes: [
            CanvasNode(
              id: 'n1',
              x: 0,
              y: 0,
              width: 140,
              height: 60,
              text: 'Spark',
              shapeType: CanvasNodeType.process,
              paletteId: 'cyan',
            ),
          ],
          edges: const [],
        );
        final note = TextNote(
          id: 'note-palette-test',
          title: 'Palette Showcase',
          paletteId: 'peach',
          tags: const ['guide'],
          createdAt: DateTime(2026, 11, 18),
          updatedAt: DateTime(2026, 11, 18),
          content:
              '---\nstatus: Approved\npriority: Low\n---\n'
              '[TOC]\n'
              '# Section One\n'
              'Link to [[Capture to Clarity]]\n'
              '![[Capture to Clarity]]\n',
        );

        final repo = _MockWorkspaceRepo();
        await repo.saveItem(board);
        await repo.saveItem(note);
        final workspace = WorkspaceProvider(repo);
        await workspace.loadItems();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider.value(value: workspace),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: NoteEditorScreen(item: note),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert initial Peach canvas & darker-variant tags/frontmatter/embed
        var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(peach.resolveNoteCanvas(false)));

        var guideChip = tester.widget<Chip>(find.widgetWithText(Chip, '#guide'));
        expect(guideChip.labelStyle?.color, equals(peach.resolveAccentColor(false)));
        expect(guideChip.backgroundColor, equals(peach.resolveChipFill(false)));

        var approvedText = tester.widget<Text>(find.text('Approved'));
        expect(approvedText.style?.color, equals(peach.resolveAccentColor(false)));

        var lowText = tester.widget<Text>(find.text('Low'));
        expect(lowText.style?.color, equals(peach.resolveAccentColor(false)));

        final embedCardFinder = find.byType(WorkspaceEmbedCard);
        expect(embedCardFinder, findsOneWidget);
        var openBoardText = tester.widget<Text>(find.text('Open Board →'));
        expect(openBoardText.style?.color, equals(peach.resolveAccentColor(false)));

        // Switch palette to Lavender Mist via Overflow Menu -> Color Palette
        await tester.tap(find.byTooltip('More options'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Color Palette'));
        await tester.pumpAndSettle();

        final lavenderSwatch = find.bySemanticsLabel('Lavender Mist color');
        await tester.ensureVisible(lavenderSwatch);
        await tester.tap(lavenderSwatch);
        await tester.pumpAndSettle();

        // Assert canvas, tags, frontmatter pills, and embed card updated to Lavender Mist
        scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(lavender.resolveNoteCanvas(false)));

        guideChip = tester.widget<Chip>(find.widgetWithText(Chip, '#guide'));
        expect(guideChip.labelStyle?.color, equals(lavender.resolveAccentColor(false)));
        expect(guideChip.backgroundColor, equals(lavender.resolveChipFill(false)));

        approvedText = tester.widget<Text>(find.text('Approved'));
        expect(approvedText.style?.color, equals(lavender.resolveAccentColor(false)));

        lowText = tester.widget<Text>(find.text('Low'));
        expect(lowText.style?.color, equals(lavender.resolveAccentColor(false)));

        openBoardText = tester.widget<Text>(find.text('Open Board →'));
        expect(openBoardText.style?.color, equals(lavender.resolveAccentColor(false)));
      },
    );

    testWidgets(
      '31. TactileFilterPill keeps Material InkWell clipped inside the visual pill while preserving 48dp hit target',
      (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (ctx, setState) => TactileFilterPill(
                    label: 'Connected Specs',
                    isSelected: taps.isOdd,
                    onTap: () => setState(() => taps++),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final targetFinder = find.byType(TactileInkTarget);
        final inkFinder = find.descendant(
          of: targetFinder,
          matching: find.byType(InkWell),
        );
        final visualContainerFinder = find.descendant(
          of: targetFinder,
          matching: find.byType(AnimatedContainer),
        );
        final clippedMaterialFinder = find.descendant(
          of: visualContainerFinder,
          matching: find.byType(Material),
        );

        final outerSize = tester.getSize(targetFinder);
        final inkSize = tester.getSize(inkFinder);
        final pillSize = tester.getSize(visualContainerFinder);
        final clippedMat = tester.widget<Material>(clippedMaterialFinder);

        // Outer target meets 48dp accessibility minimum; ink stays strictly <= pill bounds
        expect(outerSize.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
        expect(pillSize.height, lessThan(outerSize.height));
        expect(inkSize.height, lessThanOrEqualTo(pillSize.height));
        expect(inkSize.width, lessThanOrEqualTo(pillSize.width));
        expect(clippedMat.clipBehavior, equals(Clip.antiAlias));

        // Tapping in the top 3dp margin (inside 48dp hit zone, outside ~36dp pill) still fires onTap
        final topEdgeHit = tester.getTopLeft(targetFinder) + Offset(outerSize.width / 2, 2);
        await tester.tapAt(topEdgeHit);
        await tester.pumpAndSettle();
        expect(taps, equals(1));

        // Also verify ReleaseNotesTab category pills use TactileFilterPill with clipped ink
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: ReleaseNotesTab()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(ReleaseNotesTab),
            matching: find.byType(TactileFilterPill),
          ),
          findsWidgets,
        );
        final connectedPill = find.widgetWithText(TactileFilterPill, 'Connected Specs');
        final connectedInk = find.descendant(
          of: connectedPill,
          matching: find.byType(InkWell),
        );
        final connectedVisual = find.descendant(
          of: connectedPill,
          matching: find.byType(AnimatedContainer),
        );
        expect(
          tester.getSize(connectedInk).height,
          lessThanOrEqualTo(tester.getSize(connectedVisual).height),
        );
      },
    );
  });
}
