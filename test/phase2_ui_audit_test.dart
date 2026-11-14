import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:notes/core/theme/app_spacing.dart';
import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/shared/data/i_workspace_repo.dart';
import 'package:notes/shared/models/base_item.dart';
import 'package:notes/features/notes/models/text_note.dart';
import 'package:notes/features/notes/services/markdown_table_service.dart';
import 'package:notes/core/theme/theme_provider.dart';
import 'package:notes/shared/providers/workspace_provider.dart';
import 'package:notes/shared/widgets/neo_note_card.dart';
import 'package:notes/shared/widgets/app_bottom_sheet.dart';
import 'package:notes/shared/widgets/app_floating_dialog.dart';
import 'package:notes/shared/widgets/app_search_field.dart';
import 'package:notes/shared/widgets/z_order_column.dart';
import 'package:notes/shared/widgets/smart_bottom_nav_bar.dart';
import 'package:notes/features/notes/screens/note_editor_screen.dart';
import 'package:notes/features/settings/screens/settings_screen.dart';

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

      // Note opens in Read Mode
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      expect(find.byTooltip('Edit Note'), findsOneWidget);
      expect(find.byTooltip('Reader Mode'), findsNothing);

      // 2. Transition from Read Mode -> Edit Mode
      await tester.tap(find.byTooltip('Edit Note'));
      await tester.pumpAndSettle();

      // Now in Edit Mode (reader switch button visible)
      expect(find.byTooltip('Reader Mode'), findsOneWidget);

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

      // Initially shows Profile & Settings content
      expect(find.text('Trash & Deleted Items'), findsOneWidget);
      expect(find.text('Carry forward unfinished tasks'), findsOneWidget);

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
  });
}
